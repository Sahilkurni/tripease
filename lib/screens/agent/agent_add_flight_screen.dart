import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../services/flight_service.dart';
import '../../services/auth_service.dart';
import '../../services/city_service.dart';

class AgentAddFlightScreen extends StatefulWidget {
  const AgentAddFlightScreen({super.key});

  @override
  State<AgentAddFlightScreen> createState() => _AgentAddFlightScreenState();
}

class _AgentAddFlightScreenState extends State<AgentAddFlightScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _airlineController = TextEditingController();
  final _flightNumberController = TextEditingController();
  final _priceController = TextEditingController();
  final _seatsController = TextEditingController();
  
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
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await cityService.getCities();
    setState(() {
      _cities = cities;
      _isLoadingCities = false;
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
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
      initialTime: TimeOfDay.now(),
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
      'userid': user.userid,
    };

    final success = await flightService.createFlight(flightData);

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flight created successfully. Pending admin approval.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create flight')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      appBar: AppBar(
        title: Text(
          'Add New Flight',
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
                      children: [
                        Expanded(child: _buildCityDropdown('From City', _fromCity, (val) => setState(() => _fromCity = val))),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCityDropdown('To City', _toCity, (val) => setState(() => _toCity = val))),
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
                              'Create Flight',
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
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildCityDropdown(String label, CityModel? value, Function(CityModel?) onChanged) {
    return DropdownButtonFormField<CityModel>(
      value: value,
      items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city.cityName))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
      validator: (val) => val == null ? 'Required' : null,
    );
  }

  Widget _buildDateTimePicker(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        child: Text(value, style: GoogleFonts.poppins()),
      ),
    );
  }
}
