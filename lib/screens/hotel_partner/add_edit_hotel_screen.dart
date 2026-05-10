import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/hotel_partner_service.dart';
import '../../widgets/fullscreen_gallery.dart';
import '../../widgets/location_picker_screen.dart';

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

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<Map<String, dynamic>> _existingImages = []; // {imageid, image} from API

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

        // Load existing images from image_master
        try {
          final existing = await HotelPartnerService.getHotelImageMaps(hotelid);
          setState(() => _existingImages = existing);
        } catch (_) {
          // Images not critical — continue without them
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

  int get _totalImageCount => _existingImages.length + _selectedImages.length;

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth: 800,
        imageQuality: 70,
      );
      if (picked.isNotEmpty) {
        if (_totalImageCount + picked.length > 5) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Max 5 images allowed')));
          return;
        }
        setState(() {
          _selectedImages.addAll(picked);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking images: $e')));
    }
  }

  Future<void> _removeExistingImage(int index) async {
    final map = _existingImages[index];
    final imageid = map['imageid'] as int? ?? 0;
    setState(() => _existingImages.removeAt(index));
    if (imageid > 0) {
      try {
        await HotelPartnerService.deleteImage(imageid);
      } catch (_) {}
    }
  }

  void _removeNewImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: double.tryParse(_latCtrl.text),
          initialLng: double.tryParse(_lngCtrl.text),
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _addressCtrl.text = result['address'] ?? '';
        _latCtrl.text = result['latitude']?.toString() ?? '';
        _lngCtrl.text = result['longitude']?.toString() ?? '';
        
        // Attempt to match state
        if (result['state'] != null) {
          final stateName = result['state'].toString().toLowerCase();
          final match = _states.where((s) => s.statename.toLowerCase().contains(stateName)).firstOrNull;
          if (match != null) {
            _selectedStateId = match.stateid;
            _onStateSelected(_selectedStateId);
            
            // Attempt to match city after state is selected
            if (result['city'] != null) {
               Future.delayed(const Duration(milliseconds: 500), () {
                 final cityName = result['city'].toString().toLowerCase();
                 final cityMatch = _cities.where((c) => c.cityname.toLowerCase().contains(cityName)).firstOrNull;
                 if (cityMatch != null) {
                   setState(() => _selectedCityId = cityMatch.cityid);
                 }
               });
            }
          }
        }
      });
    }
  }

  Future<void> _showAddCityDialog() async {
    if (_selectedStateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a state first')));
      return;
    }

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add New City', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: ctrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'City Name *',
                    prefixIcon: Icon(Icons.location_city_rounded),
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
                            final newCity = await HotelPartnerService.addCity(
                              ctrl.text.trim(),
                              _selectedStateId!,
                              widget.userid,
                            );
                            
                            setState(() {
                              if (!_cities.any((c) => c.cityid == newCity.cityid)) {
                                _cities.add(newCity);
                                _cities.sort((a, b) => a.cityname.compareTo(b.cityname));
                              }
                              _selectedCityId = newCity.cityid;
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
                    backgroundColor: const Color(0xFF2563EB),
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

  Future<List<String>> _processImages() async {
    List<String> base64Images = [];
    for (var file in _selectedImages) {
      final bytes = await file.readAsBytes();
      base64Images.add(base64Encode(bytes));
    }
    return base64Images;
  }

  Future<void> _saveHotel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a city')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Combine kept existing images + any newly picked ones
      final List<String> newBase64 = await _processImages();
      final List<String> existingB64 = _existingImages.map((m) => m['image'] as String).toList();
      final List<String> allImages = [...existingB64, ...newBase64];

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

      if (allImages.isNotEmpty) {
        payload['images'] = allImages;
      }

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
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _selectedCityId,
                                        decoration: const InputDecoration(labelText: 'City *', prefixIcon: Icon(Icons.location_city_rounded)),
                                        items: _cities.map((c) => DropdownMenuItem(value: c.cityid, child: Text(c.cityname))).toList(),
                                        onChanged: _cities.isEmpty && _selectedStateId == null ? null : (val) => setState(() => _selectedCityId = val),
                                        validator: (val) => val == null ? 'Please select a city' : null,
                                        hint: Text(_selectedStateId == null ? 'Select state' : (_cities.isEmpty ? 'No cities' : 'Select city')),
                                        isExpanded: true,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      height: 52,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.add_location_alt_rounded, color: Color(0xFF2563EB)),
                                        onPressed: _showAddCityDialog,
                                        tooltip: 'Add new city',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                            
                            const SizedBox(height: 32),
                            Text('Property Images (Max 5)', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
                            const SizedBox(height: 16),
                            if (_totalImageCount > 0) ...[
                              SizedBox(
                                height: 110,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    // ── Existing images (from server) ──
                                      ..._existingImages.asMap().entries.map((entry) {
                                        final idx = entry.key;
                                        final b64 = (entry.value['image'] as String? ?? '');
                                        final isPrimary = idx == 0 && _selectedImages.isEmpty;
                                        return Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () => openFullscreenGallery(
                                                context,
                                                _existingImages.map((m) => m['image'] as String).toList(),
                                                initialIndex: idx,
                                              ),
                                              child: Container(
                                                margin: const EdgeInsets.only(right: 12),
                                                width: 100,
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isPrimary ? const Color(0xFF2563EB) : Colors.transparent,
                                                    width: 2,
                                                  ),
                                                  color: Colors.grey[200],
                                                ),
                                                clipBehavior: Clip.antiAlias,
                                                child: Image.memory(
                                                  base64Decode(b64),
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            top: 4,
                                            right: 16,
                                            child: GestureDetector(
                                              onTap: () => _removeExistingImage(idx),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                                              ),
                                            ),
                                          ),
                                          if (isPrimary)
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2563EB).withAlpha(200),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text('Primary', style: GoogleFonts.poppins(fontSize: 10, color: Colors.white)),
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                                    // ── Newly picked images ──
                                    ..._selectedImages.asMap().entries.map((entry) {
                                      final idx = entry.key;
                                      final file = entry.value;
                                      final globalIdx = _existingImages.length + idx;
                                      final isPrimary = globalIdx == 0;
                                      return Stack(
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(right: 12),
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isPrimary ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                                width: 2,
                                              ),
                                              color: Colors.grey[200],
                                            ),
                                            clipBehavior: Clip.antiAlias,
                                            child: FutureBuilder<Uint8List>(
                                              future: file.readAsBytes(),
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                                }
                                                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                              },
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 16,
                                            child: GestureDetector(
                                              onTap: () => _removeNewImage(idx),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, size: 16, color: Colors.red),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            left: 4,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isPrimary
                                                    ? const Color(0xFF2563EB).withAlpha(200)
                                                    : const Color(0xFF10B981).withAlpha(200),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isPrimary ? 'Primary' : 'New',
                                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_totalImageCount < 5)
                              OutlinedButton.icon(
                                onPressed: _pickImages,
                                icon: const Icon(Icons.add_photo_alternate_outlined),
                                label: Text('Add Images', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            
                            const SizedBox(height: 48),
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Location Details',
                                      style: GoogleFonts.poppins(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B))),
                                ),
                                TextButton.icon(
                                  onPressed: _openLocationPicker,
                                  icon: const Icon(Icons.map_rounded, size: 20),
                                  label: Text('Pick on Map',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Full Address *',
                                  prefixIcon: Icon(Icons.location_on_rounded)),
                              maxLines: 2,
                              validator: (val) => (val == null || val.trim().length < 10)
                                  ? 'Must be at least 10 characters'
                                  : null,
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
