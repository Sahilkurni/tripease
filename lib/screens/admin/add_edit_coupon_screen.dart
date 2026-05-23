import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';

class AddEditCouponScreen extends StatefulWidget {
  final String roleView;
  final int userid;
  final CouponModel? coupon;

  const AddEditCouponScreen({
    super.key,
    required this.roleView,
    required this.userid,
    this.coupon,
  });

  @override
  State<AddEditCouponScreen> createState() => _AddEditCouponScreenState();
}

class _AddEditCouponScreenState extends State<AddEditCouponScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isEdit = false;
  bool _isSaving = false;

  late TextEditingController _codeController;
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _valueController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxDiscountController;
  late TextEditingController _expiryController;
  late TextEditingController _limitController;
  late TextEditingController _serviceIdController;

  String _discountType = 'FLAT';
  String _serviceType = 'global';

  @override
  void initState() {
    super.initState();
    _isEdit = widget.coupon != null;
    _codeController = TextEditingController(text: widget.coupon?.couponcode ?? '');
    _titleController = TextEditingController(text: widget.coupon?.title ?? '');
    _descController = TextEditingController(text: widget.coupon?.description ?? '');
    _valueController = TextEditingController(text: widget.coupon?.discountvalue.toString() ?? '');
    _minAmountController = TextEditingController(text: widget.coupon?.minamount.toString() ?? '');
    _maxDiscountController = TextEditingController(text: widget.coupon?.maximumDiscount.toString() ?? '');
    _expiryController = TextEditingController(text: widget.coupon?.expirydate ?? '');
    _limitController = TextEditingController(text: widget.coupon?.usageLimit.toString() ?? '0');
    _serviceIdController = TextEditingController(text: widget.coupon?.serviceId?.toString() ?? '');

    _discountType = widget.coupon?.discounttype ?? 'FLAT';
    _serviceType = widget.coupon?.serviceType ?? 'global';

    if (widget.roleView == 'owner') _serviceType = 'hotel';
    if (widget.roleView == 'agent' && _serviceType == 'global') _serviceType = 'package';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _valueController.dispose();
    _minAmountController.dispose();
    _maxDiscountController.dispose();
    _expiryController.dispose();
    _limitController.dispose();
    _serviceIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _save() async {
    // debugPrint("Saving coupon... Code: ${_codeController.text}, Service: $_serviceType");
    
    if (!_formKey.currentState!.validate()) {
      // debugPrint("Form validation failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    // debugPrint("IsSaving set to true");

    final Map<String, String> data = {
      'userid': widget.userid.toString(),
      'couponcode': _codeController.text.toUpperCase(),
      'title': _titleController.text,
      'description': _descController.text,
      'discounttype': _discountType,
      'discountvalue': _valueController.text,
      'minamount': _minAmountController.text,
      'maximum_discount': _maxDiscountController.text,
      'expirydate': _expiryController.text,
      'usage_limit': _limitController.text,
      'service_type': _serviceType,
      'service_id': _serviceIdController.text,
    };

    try {
      if (_isEdit) {
        data['couponid'] = widget.coupon!.couponid.toString();
        final result = await couponService.updateCoupon(data);
        if (mounted) {
          if (result['status'] == 'success') {
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${result['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        // debugPrint("Calling createCoupon API...");
        final result = await couponService.createCoupon(data);
        // debugPrint("createCoupon result: $result");
        if (mounted) {
          if (result['status'] == 'success') {
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${result['message'] ?? 'Unknown error'}'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      // debugPrint("Catch block: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Coupon' : 'Create Coupon',
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
              _buildSectionTitle('Basic Information'),
              _buildTextField('Coupon Code', _codeController, enabled: !_isEdit, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField('Title', _titleController, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              _buildTextField('Description', _descController, maxLines: 3),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Discount Settings'),
              Row(
                children: [
                  Expanded(
                    child: _buildDropdown('Discount Type', _discountType, ['FLAT', 'PERCENT'], (v) => setState(() => _discountType = v!)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Discount Value', _valueController, keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Min Booking Amount', _minAmountController, keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Max Discount', _maxDiscountController, keyboardType: TextInputType.number),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Usage & Validity'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _buildTextField('Expiry Date', _expiryController, suffixIcon: Icons.calendar_month),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Usage Limit (0 for ∞)', _limitController, keyboardType: TextInputType.number),
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
                          _isEdit ? 'Update Coupon' : 'Create Coupon',
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
        filled: !enabled,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
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
          onChanged: (widget.roleView == 'admin' || widget.roleView == 'agent') 
              ? (v) => setState(() => _serviceType = v!) 
              : null,
        ),
      ],
    );
  }
}
