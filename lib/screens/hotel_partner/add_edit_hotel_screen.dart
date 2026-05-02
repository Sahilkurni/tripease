import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/hotel_partner_service.dart';

class AddEditHotelScreen extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? hotelData; // passed from dashboard (contains hotelid)
  final int partnerid;
  final int userid;

  const AddEditHotelScreen({
    super.key,
    required this.isEdit,
    this.hotelData,
    required this.partnerid,
    required this.userid,
  });

  @override
  State<AddEditHotelScreen> createState() => _AddEditHotelScreenState();
}

class _AddEditHotelScreenState extends State<AddEditHotelScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoadingForm = true;
  bool _isSaving = false;

  List<StateItem> _states = [];
  List<CityItem> _cities = [];

  final _hotelNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _checkInCtrl = TextEditingController();
  final _checkOutCtrl = TextEditingController();

  int? _selectedStateId;
  int? _selectedCityId;
  int _starRating = 3;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final states = await HotelPartnerService.getStates();
      setState(() => _states = states);

      if (widget.isEdit && widget.hotelData != null) {
        final hotelid = widget.hotelData!['hotelid'] as int;
        final hotelDetails = await HotelPartnerService.getHotel(hotelid);
        
        _hotelNameCtrl.text = hotelDetails['hotelname'] ?? '';
        _descCtrl.text = hotelDetails['description'] ?? '';
        _addressCtrl.text = hotelDetails['address'] ?? '';
        
        _starRating = int.tryParse(hotelDetails['star_rating']?.toString() ?? '3') ?? 3;
        _latCtrl.text = hotelDetails['latitude']?.toString() ?? '';
        _lngCtrl.text = hotelDetails['longitude']?.toString() ?? '';
        _checkInCtrl.text = hotelDetails['checkintime'] ?? '';
        _checkOutCtrl.text = hotelDetails['checkouttime'] ?? '';

        _selectedStateId = int.tryParse(hotelDetails['stateid']?.toString() ?? '');
        if (_selectedStateId != null) {
          final cities = await HotelPartnerService.getCities(_selectedStateId!);
          setState(() {
            _cities = cities;
            _selectedCityId = int.tryParse(hotelDetails['cityid']?.toString() ?? '');
          });
        }
      }
      
      if (mounted) setState(() => _isLoadingForm = false);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingForm = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  Future<void> _onStateSelected(int? stateid) async {
    if (stateid == null || stateid == _selectedStateId) return;
    setState(() {
      _selectedStateId = stateid;
      _selectedCityId = null;
      _cities = []; // clear previous cities
    });
    try {
      final cities = await HotelPartnerService.getCities(stateid);
      if (mounted) setState(() => _cities = cities);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load cities: $e')));
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      final String hour = picked.hour.toString().padLeft(2, '0');
      final String minute = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$hour:$minute';
      });
    }
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a city')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'hotelid': widget.isEdit ? widget.hotelData!['hotelid'] : 0,
        'partnerid': widget.partnerid,
        'hotelname': _hotelNameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'cityid': _selectedCityId,
        'star_rating': _starRating,
        'latitude': _latCtrl.text.trim().isNotEmpty ? double.tryParse(_latCtrl.text.trim()) : null,
        'longitude': _lngCtrl.text.trim().isNotEmpty ? double.tryParse(_lngCtrl.text.trim()) : null,
        'checkintime': _checkInCtrl.text.trim(),
        'checkouttime': _checkOutCtrl.text.trim(),
        'uid': widget.userid,
      };

      if (widget.isEdit) {
        await HotelPartnerService.editHotel(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hotel updated successfully')));
          Navigator.pop(context, true);
        }
      } else {
        await HotelPartnerService.addHotel(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hotel added successfully')));
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving hotel: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildStarRating() {
    return Row(
      children: List.generate(5, (index) {
        final isSelected = index < _starRating;
        return GestureDetector(
          onTap: () => setState(() => _starRating = index + 1),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              isSelected ? Icons.star_rounded : Icons.star_border_rounded,
              color: isSelected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
              size: 40,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(widget.isEdit ? 'Edit Property' : 'Add New Property', style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600)),
      ),
      body: _isLoadingForm
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Basic Details', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 24),
                          
                          TextFormField(
                            controller: _hotelNameCtrl,
                            decoration: const InputDecoration(labelText: 'Property Name *', prefixIcon: Icon(Icons.domain)),
                            validator: (val) => (val == null || val.trim().length < 3) ? 'Must be at least 3 characters' : null,
                          ),
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _descCtrl,
                            decoration: const InputDecoration(labelText: 'Description *', alignLabelWithHint: true),
                            maxLines: 4,
                            validator: (val) => (val == null || val.trim().length < 20) ? 'Must be at least 20 characters' : null,
                          ),
                          
                          const SizedBox(height: 32),
                          Text('Location Details', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedStateId,
                                  decoration: const InputDecoration(labelText: 'State *', prefixIcon: Icon(Icons.map_rounded)),
                                  items: _states.map((s) => DropdownMenuItem(value: s.stateid, child: Text(s.statename))).toList(),
                                  onChanged: _onStateSelected,
                                  validator: (val) => val == null ? 'Please select a state' : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedCityId,
                                  decoration: const InputDecoration(labelText: 'City *', prefixIcon: Icon(Icons.location_city_rounded)),
                                  items: _cities.map((c) => DropdownMenuItem(value: c.cityid, child: Text(c.cityname))).toList(),
                                  onChanged: _cities.isEmpty ? null : (val) => setState(() => _selectedCityId = val),
                                  validator: (val) => val == null ? 'Please select a city' : null,
                                  hint: Text(_selectedStateId == null ? 'Select state first' : (_cities.isEmpty ? 'Loading cities...' : 'Select a city')),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _addressCtrl,
                            decoration: const InputDecoration(labelText: 'Full Address *', prefixIcon: Icon(Icons.location_on_rounded)),
                            maxLines: 2,
                            validator: (val) => (val == null || val.trim().length < 10) ? 'Must be at least 10 characters' : null,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _latCtrl,
                                  decoration: const InputDecoration(labelText: 'Latitude (Optional)', prefixIcon: Icon(Icons.explore_rounded)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: TextFormField(
                                  controller: _lngCtrl,
                                  decoration: const InputDecoration(labelText: 'Longitude (Optional)', prefixIcon: Icon(Icons.explore_rounded)),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          Text('Property Ratings & Timings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                          const SizedBox(height: 24),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Star Rating *', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF64748B))),
                                    const SizedBox(height: 8),
                                    _buildStarRating(),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _checkInCtrl,
                                        readOnly: true,
                                        decoration: const InputDecoration(labelText: 'Check-in *', suffixIcon: Icon(Icons.access_time)),
                                        onTap: () => _pickTime(_checkInCtrl),
                                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _checkOutCtrl,
                                        readOnly: true,
                                        decoration: const InputDecoration(labelText: 'Check-out *', suffixIcon: Icon(Icons.access_time)),
                                        onTap: () => _pickTime(_checkOutCtrl),
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) return 'Required';
                                          if (val == _checkInCtrl.text) return 'Must differ';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 48),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveHotel,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                backgroundColor: const Color(0xFF2563EB),
                                elevation: 4,
                                shadowColor: const Color(0xFF2563EB).withAlpha(100),
                              ),
                              child: _isSaving
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                  : Text(widget.isEdit ? 'Update Property' : 'Save Property', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
