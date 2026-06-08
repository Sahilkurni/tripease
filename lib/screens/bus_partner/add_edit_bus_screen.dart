import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/bus_model.dart';
import '../../services/bus_service.dart';
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
  final _busNumberCtrl = TextEditingController();
  final _seatsCtrl = TextEditingController();
  final _amenitiesCtrl = TextEditingController();

  final _busTypes = const ['AC', 'Non-AC', 'Sleeper'];

  bool _isSaving = false;
  String _busType = 'AC';

  // ── Image handling ──
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _existingImages = []; // {imageid, image} from API
  List<XFile> _selectedImages = [];  // newly picked

  int get _totalImageCount => _existingImages.length + _selectedImages.length;

  @override
  void initState() {
    super.initState();
    final bus = widget.bus;
    if (bus != null) {
      _busNameCtrl.text = bus.busname;
      _busNumberCtrl.text = bus.busnumber;
      _busType = _busTypes.contains(bus.bustype) ? bus.bustype : 'AC';
      _seatsCtrl.text = bus.totalseats.toString();
      _amenitiesCtrl.text = bus.amenities;

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
    _busNumberCtrl.dispose();
    _seatsCtrl.dispose();
    _amenitiesCtrl.dispose();
    super.dispose();
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
        'busname': _busNameCtrl.text.trim(),
        'busnumber': _busNumberCtrl.text.trim(),
        'bustype': _busType,
        'totalseats': int.parse(_seatsCtrl.text.trim()),
        'amenities': _amenitiesCtrl.text.trim(),
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
                  : 'Bus added',
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

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bus Images (Max 5)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isEdit ? 'Edit Bus' : 'Add Bus',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
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
                      TextFormField(
                        controller: _busNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bus Number *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        validator:
                            (value) =>
                                (value == null ||
                                        value.trim().isEmpty)
                                    ? 'Required'
                                    : null,
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _responsiveRow([
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
                    TextFormField(
                      controller: _amenitiesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Amenities (e.g., WiFi, Water, AC)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.ac_unit),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildImageSection(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBus,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor:
                              Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child:
                            _isSaving
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : Text(
                                  widget.isEdit
                                      ? 'Update Bus'
                                      : 'Add Bus',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
        if (constraints.maxWidth > 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                children.map((child) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: child == children.last ? 0 : 16,
                      ),
                      child: child,
                    ),
                  );
                }).toList(),
          );
        } else {
          return Column(
            children:
                children.map((child) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: child == children.last ? 0 : 16,
                    ),
                    child: child,
                  );
                }).toList(),
          );
        }
      },
    );
  }
}
