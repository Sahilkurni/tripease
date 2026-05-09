import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/bus_model.dart';
import '../../services/bus_service.dart';
import '../../services/hotel_partner_service.dart';
import '../../widgets/fullscreen_gallery.dart';

class AddEditBusScreen extends StatefulWidget {
  final BusModel? bus;
  final int partnerid;
  final int userid;

  const AddEditBusScreen({
    super.key,
    this.bus,
    required this.partnerid,
    required this.userid,
  });

  bool get isEdit => bus != null;

  @override
  State<AddEditBusScreen> createState() => _AddEditBusScreenState();
}

class _AddEditBusScreenState extends State<AddEditBusScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNameCtrl = TextEditingController();
  final _departureCtrl = TextEditingController();
  final _arrivalCtrl = TextEditingController();
  final _fareCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();

  final _busTypes = const ['AC', 'Non-AC', 'Sleeper'];
  final _layoutTypes = const ['1x2', '2x2', 'sleeper'];

  bool _isLoadingCities = true;
  bool _isSaving = false;
  String _busType = 'AC';
  String _layoutType = '2x2';
  int? _sourceCityId;
  int? _destinationCityId;
  List<CityItem> _cities = [];

  // ── Image handling ──
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _existingImages = []; // {imageid, image} from API
  List<XFile> _selectedImages = [];  // newly picked

  int get _totalImageCount => _existingImages.length + _selectedImages.length;

  @override
  void initState() {
    super.initState();
    _loadCities();
    final bus = widget.bus;
    if (bus != null) {
      _busNameCtrl.text = bus.busName;
      _busType = _busTypes.contains(bus.busType) ? bus.busType : 'AC';
      _layoutType =
          _layoutTypes.contains(bus.layoutType) ? bus.layoutType : '2x2';
      _sourceCityId = bus.sourceCityId == 0 ? null : bus.sourceCityId;
      _destinationCityId =
          bus.destinationCityId == 0 ? null : bus.destinationCityId;
      _departureCtrl.text = bus.departureTime;
      _arrivalCtrl.text = bus.arrivalTime;
      _fareCtrl.text = bus.baseFare.toStringAsFixed(0);
      _seatsCtrl.text = bus.totalSeats.toString();

      // Load existing images
      _loadExistingImages(bus.busid);
    }
  }

  Future<void> _loadExistingImages(int busid) async {
    try {
      final maps = await busService.getBusImageMaps(busid);
      if (mounted) setState(() => _existingImages = maps);
    } catch (_) {}
  }

  @override
  void dispose() {
    _busNameCtrl.dispose();
    _departureCtrl.dispose();
    _arrivalCtrl.dispose();
    _fareCtrl.dispose();
    _seatsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await HotelPartnerService.getCities();
      if (mounted) {
        setState(() {
          _cities = cities;
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCities = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load cities: $e')));
      }
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    controller.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth: 800,
        imageQuality: 70,
      );
      if (picked.isNotEmpty) {
        if (_totalImageCount + picked.length > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Max 5 images allowed')),
            );
          }
          return;
        }
        setState(() => _selectedImages.addAll(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking images: $e')));
      }
    }
  }

  Future<void> _removeExistingImage(int index) async {
    final map = _existingImages[index];
    final imageid = map['imageid'] as int? ?? 0;
    setState(() => _existingImages.removeAt(index));
    if (imageid > 0) {
      try {
        await busService.deleteImage(imageid);
      } catch (_) {
        // Already removed from UI; DB failure is non-critical
      }
    }
  }

  void _removeNewImage(int index) =>
      setState(() => _selectedImages.removeAt(index));

  Future<List<String>> _processImages() async {
    final List<String> result = [];
    for (final file in _selectedImages) {
      final bytes = await file.readAsBytes();
      result.add(base64Encode(bytes));
    }
    return result;
  }

  Future<void> _saveBus() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceCityId == null || _destinationCityId == null) {
      _showError('Please select source and destination cities.');
      return;
    }
    if (_sourceCityId == _destinationCityId) {
      _showError('Source and destination must be different.');
      return;
    }
    if (widget.partnerid == 0 || widget.userid == 0) {
      _showError('Session missing. Please log in again.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final newBase64 = await _processImages();
      // existing images are already saved in DB; just pass their base64 for any re-upload logic
      final existingB64 = _existingImages.map((m) => m['image'] as String).toList();
      final allImages = [...existingB64, ...newBase64];

      final payload = <String, dynamic>{
        'action': widget.isEdit ? 'update' : 'create',
        'busid': widget.bus?.busid ?? 0,
        'partnerid': widget.partnerid,
        'bus_name': _busNameCtrl.text.trim(),
        'bus_type': _busType,
        'layout_type': _layoutType,
        'source_city_id': _sourceCityId,
        'destination_city_id': _destinationCityId,
        'departure_time': _departureCtrl.text.trim(),
        'arrival_time': _arrivalCtrl.text.trim(),
        'base_fare': double.parse(_fareCtrl.text.trim()),
        'total_seats': int.parse(_seatsCtrl.text.trim()),
        'uid': widget.userid,
      };

      if (allImages.isNotEmpty) payload['images'] = allImages;

      await busService.saveBus(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? 'Bus updated successfully'
                  : 'Bus added and seats generated',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showError('Error saving bus: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bus Images (Max 5)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        if (_totalImageCount > 0) ...[
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Existing images (server)
                ..._existingImages.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final map = entry.value;
                  final b64 = map['image'] as String;
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
                              color: isPrimary
                                  ? const Color(0xFF2563EB)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            color: Colors.grey[200],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.memory(
                            base64Decode(b64),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, color: Colors.grey),
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
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child:
                                const Icon(Icons.close, size: 16, color: Colors.red),
                          ),
                        ),
                      ),
                      if (isPrimary)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withAlpha(200),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Primary',
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: Colors.white)),
                          ),
                        ),
                    ],
                  );
                }),
                // Newly picked images
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
                            color: isPrimary
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF10B981),
                            width: 2,
                          ),
                          color: Colors.grey[200],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FutureBuilder<Uint8List>(
                          future: file.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.memory(snapshot.data!,
                                  fit: BoxFit.cover);
                            }
                            return const Center(
                                child: CircularProgressIndicator(strokeWidth: 2));
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
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle),
                            child:
                                const Icon(Icons.close, size: 16, color: Colors.red),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPrimary
                                ? const Color(0xFF2563EB).withAlpha(200)
                                : const Color(0xFF10B981).withAlpha(200),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPrimary ? 'Primary' : 'New',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_totalImageCount < 5)
          OutlinedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text('Add Images',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Bus' : 'Add Bus',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body:
          _isLoadingCities
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bus Details',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _responsiveRow([
                              TextFormField(
                                controller: _busNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Bus Name *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.directions_bus),
                                ),
                                validator:
                                    (value) =>
                                        (value == null ||
                                                value.trim().length < 3)
                                            ? 'Enter at least 3 characters'
                                            : null,
                              ),
                              DropdownButtonFormField<String>(
                                value: _busType,
                                decoration: const InputDecoration(
                                  labelText: 'Bus Type *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.event_seat),
                                ),
                                items:
                                    _busTypes
                                        .map(
                                          (type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (value) =>
                                        setState(() => _busType = value!),
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _responsiveRow([
                              DropdownButtonFormField<String>(
                                value: _layoutType,
                                decoration: const InputDecoration(
                                  labelText: 'Layout Type *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.grid_view),
                                ),
                                items:
                                    _layoutTypes
                                        .map(
                                          (type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ),
                                        )
                                        .toList(),
                                onChanged:
                                    (value) =>
                                        setState(() => _layoutType = value!),
                              ),
                              TextFormField(
                                controller: _seatsCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Total Seats *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.confirmation_number),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  final seats = int.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  if (seats == null || seats < 1) {
                                    return 'Enter a valid seat count';
                                  }
                                  if (seats > 80) return 'Maximum 80 seats';
                                  return null;
                                },
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _responsiveRow([
                              DropdownButtonFormField<int>(
                                value: _sourceCityId,
                                decoration: const InputDecoration(
                                  labelText: 'Source City *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.trip_origin),
                                ),
                                items: _cities.map<DropdownMenuItem<int>>((city) {
                                  return DropdownMenuItem<int>(
                                    value: city.cityid,
                                    child: Text(city.cityname),
                                  );
                                }).toList(),
                                onChanged:
                                    (value) =>
                                        setState(() => _sourceCityId = value),
                                validator:
                                    (value) =>
                                        value == null ? 'Select source' : null,
                              ),
                              DropdownButtonFormField<int>(
                                value: _destinationCityId,
                                decoration: const InputDecoration(
                                  labelText: 'Destination City *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_on_outlined),
                                ),
                                items: _cities.map<DropdownMenuItem<int>>((city) {
                                  return DropdownMenuItem<int>(
                                    value: city.cityid,
                                    child: Text(city.cityname),
                                  );
                                }).toList(),
                                onChanged:
                                    (value) => setState(
                                      () => _destinationCityId = value,
                                    ),
                                validator:
                                    (value) =>
                                        value == null
                                            ? 'Select destination'
                                            : null,
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _responsiveRow([
                              TextFormField(
                                controller: _departureCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Departure Time *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.schedule),
                                ),
                                onTap: () => _pickTime(_departureCtrl),
                                validator: _required,
                              ),
                              TextFormField(
                                controller: _arrivalCtrl,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Arrival Time *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.more_time),
                                ),
                                onTap: () => _pickTime(_arrivalCtrl),
                                validator: _required,
                              ),
                            ]),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fareCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Base Fare *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.currency_rupee),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                final fare = double.tryParse(
                                  value?.trim() ?? '',
                                );
                                if (fare == null || fare <= 0) {
                                  return 'Enter a valid fare';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // ── Image Section ──
                            _buildImageSection(),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFED7AA),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: Color(0xFFEA580C),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Seats are generated automatically after save using the selected layout.',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveBus,
                                icon:
                                    _isSaving
                                        ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                        : const Icon(Icons.save),
                                label: Text(
                                  widget.isEdit ? 'Update Bus' : 'Save Bus',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
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

  Widget _responsiveRow(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children:
                children
                    .map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: child,
                      ),
                    )
                    .toList(),
          );
        }
        return Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}
