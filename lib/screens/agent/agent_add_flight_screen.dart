import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../services/flight_service.dart';
import '../../services/auth_service.dart';
import '../../services/city_service.dart';
import '../../widgets/location_picker_screen.dart';
import '../../models/flight_model.dart';

class AgentAddFlightScreen extends StatefulWidget {
  final FlightModel? flight;
  const AgentAddFlightScreen({super.key, this.flight});

  @override
  State<AgentAddFlightScreen> createState() => _AgentAddFlightScreenState();
}

class _AgentAddFlightScreenState extends State<AgentAddFlightScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _airlineController;
  late final TextEditingController _flightNumberController;
  late final TextEditingController _priceController;
  late final TextEditingController _seatsController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  
  CityModel? _fromCity;
  CityModel? _toCity;
  DateTime? _departureDate;
  TimeOfDay? _departureTime;
  
  List<CityModel> _cities = [];
  bool _isLoadingCities = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _airlineController = TextEditingController(text: widget.flight?.airline);
    _flightNumberController = TextEditingController(text: widget.flight?.flightNumber);
    _priceController = TextEditingController(text: widget.flight?.price.toString());
    _seatsController = TextEditingController(text: widget.flight?.totalSeats.toString());
    _latController = TextEditingController(text: widget.flight?.latitude?.toString() ?? '');
    _lngController = TextEditingController(text: widget.flight?.longitude?.toString() ?? '');
    
    if (widget.flight != null) {
      try {
        final dep = DateTime.parse(widget.flight!.departureTime);
        _departureDate = dep;
        _departureTime = TimeOfDay(hour: dep.hour, minute: dep.minute);
      } catch (e) {
        // Fallback if date is invalid
      }
    }
    
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await cityService.getCities();
    setState(() {
      _cities = cities;
      _isLoadingCities = false;
      
      if (widget.flight != null) {
        _fromCity = _cities.where((c) => c.cityId == widget.flight!.fromCity).firstOrNull;
        _toCity = _cities.where((c) => c.cityId == widget.flight!.toCity).firstOrNull;
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _departureDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departureTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _departureTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _fromCity == null || _toCity == null || _departureDate == null || _departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = authService.currentUser;
    if (user == null) return;

    final departureDateTime = DateTime(
      _departureDate!.year,
      _departureDate!.month,
      _departureDate!.day,
      _departureTime!.hour,
      _departureTime!.minute,
    );

    // Dummy arrival time (3 hours later)
    final arrivalDateTime = departureDateTime.add(const Duration(hours: 3));

    final flightData = {
      'airline': _airlineController.text,
      'flight_number': _flightNumberController.text,
      'from_city': _fromCity!.cityId.toString(),
      'to_city': _toCity!.cityId.toString(),
      'departure_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(departureDateTime),
      'arrival_time': DateFormat('yyyy-MM-dd HH:mm:ss').format(arrivalDateTime),
      'duration': '3h 00m',
      'price': _priceController.text,
      'total_seats': _seatsController.text,
      'latitude': _latController.text,
      'longitude': _lngController.text,
      'userid': user.userid,
    };

    bool success;
    if (widget.flight != null) {
      flightData['flightid'] = widget.flight!.flightId.toString();
      success = await flightService.updateFlight(flightData);
    } else {
      success = await flightService.createFlight(flightData);
    }

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.flight != null ? 'Flight updated successfully' : 'Flight created successfully. Pending admin approval.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${widget.flight != null ? 'update' : 'create'} flight')),
      );
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: double.tryParse(_latController.text),
          initialLng: double.tryParse(_lngController.text),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latController.text = result['latitude']?.toString() ?? '';
        _lngController.text = result['longitude']?.toString() ?? '';
        
        // Match city
        if (result['city'] != null) {
          final cityName = result['city'].toString().toLowerCase();
          final cityMatch = _cities.where((c) => c.cityName.toLowerCase().contains(cityName)).firstOrNull;
          if (cityMatch != null) {
            if (_fromCity == null) {
              _fromCity = cityMatch;
            } else if (_toCity == null) {
              _toCity = cityMatch;
            }
          }
        }
      });
    }
  }

  Future<void> _showAddCityDialog() async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSavingCity = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(ctx).brightness == Brightness.dark ? const Color(0xFF142035) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add New City', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Colors.black)),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: ctrl,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: 'City Name *',
                    labelStyle: TextStyle(color: Theme.of(ctx).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'City name is required';
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSavingCity ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSavingCity
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setStateDialog(() => isSavingCity = true);
                          try {
                            final user = authService.currentUser;
                            if (user == null) throw Exception('User not logged in');
                            
                            final newCity = await cityService.addCity(
                              ctrl.text.trim(),
                              int.parse(user.userid),
                            );
                            
                            setState(() {
                              if (!_cities.any((c) => c.cityId == newCity.cityId)) {
                                _cities.add(newCity);
                                _cities.sort((a, b) => a.cityName.compareTo(b.cityName));
                              }
                            });
                            if (mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setStateDialog(() => isSavingCity = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent)
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSavingCity
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Add City', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      appBar: AppBar(
        title: Text(
          widget.flight != null ? 'Edit Flight' : 'Add New Flight',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoadingCities
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(_airlineController, 'Airline Name', Icons.flight_rounded),
                    const SizedBox(height: 16),
                    _buildTextField(_flightNumberController, 'Flight Number', Icons.numbers_rounded),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildCityDropdown('From City', _fromCity, (val) => setState(() => _fromCity = val))),
                        const SizedBox(width: 12),
                        Container(
                          height: 52,
                          width: 52,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
                            onPressed: _showAddCityDialog,
                            tooltip: 'Add new city',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildCityDropdown('To City', _toCity, (val) => setState(() => _toCity = val))),
                        const SizedBox(width: 12),
                        Container(
                          height: 52,
                          width: 52,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
                            onPressed: _showAddCityDialog,
                            tooltip: 'Add new city',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDateTimePicker('Departure Date', _departureDate == null ? 'Select Date' : DateFormat('MMM dd, yyyy').format(_departureDate!), Icons.calendar_today_rounded, _selectDate)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDateTimePicker('Departure Time', _departureTime == null ? 'Select Time' : _departureTime!.format(context), Icons.access_time_rounded, _selectTime)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_priceController, 'Price (₹)', Icons.currency_rupee_rounded, isNumeric: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_seatsController, 'Total Seats', Icons.airline_seat_recline_extra_rounded, isNumeric: true)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Airport Location', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                        TextButton.icon(
                          onPressed: _openLocationPicker,
                          icon: const Icon(Icons.map_rounded),
                          label: Text('Pick on Map', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(_latController, 'Latitude', Icons.explore_rounded, isNumeric: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField(_lngController, 'Longitude', Icons.explore_rounded, isNumeric: true)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.flight != null ? 'Update Flight' : 'Create Flight',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF8FAFC),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildCityDropdown(String label, CityModel? value, Function(CityModel?) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DropdownButtonFormField<CityModel>(
      value: value,
      items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city.cityName, style: TextStyle(color: isDark ? Colors.white : Colors.black)))).toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? const Color(0xFF1E3A5F) : Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF8FAFC),
      ),
      validator: (val) => val == null ? 'Required' : null,
    );
  }

  Widget _buildDateTimePicker(String label, String value, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFF8FAFC),
        ),
        child: Text(value, style: GoogleFonts.poppins(color: isDark ? Colors.white : Colors.black)),
      ),
    );
  }
}
