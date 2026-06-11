import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/offer_model.dart';
import '../../services/offer_service.dart';

class AddEditOfferScreen extends StatefulWidget {
  final String roleView;
  final int userid;
  final OfferModel? offer;

  const AddEditOfferScreen({
    super.key,
    required this.roleView,
    required this.userid,
    this.offer,
  });

  @override
  State<AddEditOfferScreen> createState() => _AddEditOfferScreenState();
}

class _AddEditOfferScreenState extends State<AddEditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _serviceIdController;
  late TextEditingController _discountValueController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxDiscountController;

  String _serviceType = 'global';
  String _discountType = 'FLAT';
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _isEdit = widget.offer != null;
    _titleController = TextEditingController(text: widget.offer?.title ?? '');
    _descController = TextEditingController(text: widget.offer?.description ?? '');
    _fromController = TextEditingController(text: widget.offer?.validFrom ?? '');
    _toController = TextEditingController(text: widget.offer?.validTo ?? '');
    _serviceIdController = TextEditingController(text: widget.offer?.serviceId?.toString() ?? '');
    _discountValueController = TextEditingController(text: widget.offer?.discountValue.toString() ?? '0');
    _minAmountController = TextEditingController(text: widget.offer?.minAmount.toString() ?? '0');
    _maxDiscountController = TextEditingController(text: widget.offer?.maxDiscount?.toString() ?? '');

    _serviceType = widget.offer?.serviceType ?? 'global';
    _discountType = widget.offer?.discountType ?? 'FLAT';
    _base64Image = widget.offer?.primaryImage;

    if (widget.roleView == 'owner') _serviceType = 'hotel';
    if (widget.roleView == 'agent' && (_serviceType == 'global' || _serviceType == 'hotel')) {
      _serviceType = 'package';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _serviceIdController.dispose();
    _discountValueController.dispose();
    _minAmountController.dispose();
    _maxDiscountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Valid From and Valid To dates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, String> data = {
        'userid': widget.userid.toString(),
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'valid_from': _fromController.text,
        'valid_to': _toController.text,
        'service_type': _serviceType,
        'service_id': _serviceIdController.text.trim(),
        'discount_type': _discountType,
        'discount_value': _discountValueController.text.trim(),
        'minamount': _minAmountController.text.trim(),
        'maximum_discount': _maxDiscountController.text.trim(),
      };

      if (_base64Image != null) {
        data['image'] = _base64Image!;
      }

      bool success;
      if (_isEdit) {
        data['offerid'] = widget.offer!.offerid.toString();
        success = await offerService.updateOffer(data);
      } else {
        success = await offerService.createOffer(data);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Offer updated successfully!' : 'Offer created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Failed to update offer. Please try again.' : 'Failed to create offer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Offer' : 'Create Offer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildSectionTitle('Offer Details'),
              _buildTextField('Offer Title', _titleController, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField('Description', _descController, maxLines: 3),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Discount Details'),
              _buildDiscountTypeSelector(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Discount Value', _discountValueController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Min Booking Amount', _minAmountController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              if (_discountType == 'PERCENT')
                _buildTextField('Max Discount (Optional)', _maxDiscountController, keyboardType: TextInputType.number),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Validity Period'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(_fromController),
                      child: AbsorbPointer(
                        child: _buildTextField('Valid From', _fromController, suffixIcon: Icons.calendar_today),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(_toController),
                      child: AbsorbPointer(
                        child: _buildTextField('Valid To', _toController, suffixIcon: Icons.calendar_today),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Service Scope'),
              _buildServiceTypeSelector(),
              const SizedBox(height: 16),
              if (_serviceType != 'global')
                _buildTextField('Service ID (Optional)', _serviceIdController, keyboardType: TextInputType.number),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEdit ? 'Update Offer' : 'Create Offer',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Stack(
        children: [
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: _base64Image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(base64Decode(_base64Image!), fit: BoxFit.cover),
                  )
                : Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey.withOpacity(0.5)),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton.small(
              onPressed: _pickImage,
              child: const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    IconData? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon) : null,
      ),
    );
  }

  Widget _buildServiceTypeSelector() {
    List<String> options = [];
    if (widget.roleView == 'admin') {
      options = ['global', 'hotel', 'package', 'bus', 'flight'];
    } else if (widget.roleView == 'owner') {
      options = ['hotel'];
    } else if (widget.roleView == 'agent') {
      options = ['package', 'bus', 'flight'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Type', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _serviceType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
          onChanged: options.length > 1 ? (v) => setState(() => _serviceType = v!) : null,
        ),
      ],
    );
  }
  Widget _buildDiscountTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Discount Type', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _discountType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: const [
            DropdownMenuItem(value: 'FLAT', child: Text('FLAT')),
            DropdownMenuItem(value: 'PERCENT', child: Text('PERCENTAGE')),
          ],
          onChanged: (v) => setState(() => _discountType = v!),
        ),
      ],
    );
  }
}
