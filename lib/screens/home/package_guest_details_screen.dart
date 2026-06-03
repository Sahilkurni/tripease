import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/booking_success_screen.dart';
import '../../services/payment_service.dart';
import '../../services/coupon_service.dart';
import '../../models/coupon_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/coupon_selector.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../core/constants/app_colors.dart';

class PackageGuestDetailsScreen extends StatefulWidget {
  final String packageId;
  final String packageName;
  final double price;
  final String? imageUrl;

  const PackageGuestDetailsScreen({
    super.key,
    required this.packageId,
    required this.packageName,
    required this.price,
    this.imageUrl,
  });

  @override
  State<PackageGuestDetailsScreen> createState() => _PackageGuestDetailsScreenState();
}

class _PackageGuestDetailsScreenState extends State<PackageGuestDetailsScreen> {
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _paxController = TextEditingController(text: '1');
  final _couponController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double _discountAmount = 0.0;
  CouponModel? _appliedCoupon;
  CouponModel? _bestCoupon;
  bool _isApplyingCoupon = false;

  double get _finalAmount => widget.price - _discountAmount;
  String get _formattedAmount => _finalAmount.toStringAsFixed(0);

  @override
  void initState() {
    super.initState();
    try {
      paymentService.init(
        onSuccess: _onPaymentSuccess,
        onError: _onPaymentError,
      );
    } catch (e) {
      // debugPrint("Payment service init error: $e");
    }
    final user = authService.currentUser;
    if (user != null) {
      _fetchBestCoupon(user.userid);
    }
  }

  Future<void> _fetchBestCoupon(String userId) async {
    final best = await couponService.getBestCoupon(
      userId: int.parse(userId),
      amount: widget.price,
      serviceType: 'package',
      serviceId: int.tryParse(widget.packageId),
    );
    if (mounted) {
      setState(() => _bestCoupon = best);
    }
  }

  void _onPaymentSuccess(String paymentId) {
    _createBooking(paymentId);
  }

  void _onPaymentError(String error) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed or cancelled: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _paxController.dispose();
    _couponController.dispose();
    try {
      paymentService.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final result = await couponService.applyCoupon(
        couponCode: code,
        userId: int.tryParse(user.userid) ?? 0,
        serviceType: 'package',
        serviceId: int.tryParse(widget.packageId) ?? 0,
        amount: widget.price,
      );

      if (mounted) setState(() => _isApplyingCoupon = false);

      if (result != null && result['status'] == 'success') {
        setState(() {
          _appliedCoupon = CouponModel.fromJson(result['data']);
          _discountAmount = double.tryParse(result['data']['discount_amount'].toString()) ?? 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Coupon applied! You saved ₹$_discountAmount')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result?['message'] ?? 'Invalid coupon')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isApplyingCoupon = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleBooking() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to book')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      paymentService.openPayment(
        amount: _finalAmount,
        name: "TripEase Package",
        description: "Booking for ${widget.packageName}",
        email: user.email,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment System Error: $e')));
    }
  }

  Future<void> _createBooking(String paymentId) async {
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createPackageBooking),
        body: {
          'userid': user.userid.toString(),
          'packageid': widget.packageId,
          'amount': _finalAmount.toString(),
          'payment_id': paymentId,
          'guest_name': _nameController.text,
          'guest_age': _ageController.text,
          'guest_gender': _genderController.text,
        },
      );

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final success = data['status'] == 'success';
      final bookingId = int.tryParse(data['data']?['bookingid']?.toString() ?? '') ?? 0;

      if (success && _appliedCoupon != null && bookingId > 0) {
        await couponService.recordCouponUsage(
          couponId: _appliedCoupon!.couponid,
          userId: int.tryParse(user.userid) ?? 0,
          bookingId: bookingId,
          serviceType: 'package',
          serviceId: int.tryParse(widget.packageId) ?? 0,
          discountAmount: _discountAmount,
        );
      }

      if (!mounted) return;

      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookingSuccessScreen(
              title: 'Package Booked! 🎉',
              subtitle: 'Your travel package has been\nbooked successfully!',
              bookingType: 'package',
              savedAmount: _discountAmount > 0
                  ? _discountAmount.toStringAsFixed(0)
                  : null,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Booking failed. Please try again.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Guest Details', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSummaryCard(isDark),
                    const SizedBox(height: 32),
                    _buildGuestForm(isDark),
                    const SizedBox(height: 24),
                    _buildCouponSection(isDark),
                    const SizedBox(height: 32),
                    _buildBottomBar(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.packageName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Travel Package Tour', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Original Amount:', style: TextStyle(color: Colors.white70)),
              Text('₹${widget.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, decoration: TextDecoration.lineThrough)),
            ],
          ),
          if (_discountAmount > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Coupon Discount:', style: TextStyle(color: Colors.white70)),
                Text('- ₹$_discountAmount', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount:', style: TextStyle(color: Colors.white70)),
              Text('₹$_formattedAmount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestForm(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Primary Guest', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
            validator: (value) => value == null || value.isEmpty ? 'Please enter name' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.calendar_today_outlined), border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _genderController,
                  decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined), border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paxController,
            decoration: const InputDecoration(labelText: 'Number of Guests (PAX)', prefixIcon: Icon(Icons.group_outlined), border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || value.isEmpty ? 'Please enter guest count' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCouponSection(bool isDark) {
    return Column(
      children: [
        if (_bestCoupon != null && _appliedCoupon == null)
          GestureDetector(
            onTap: () {
              _couponController.text = _bestCoupon!.couponcode;
              _applyCoupon();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Save ₹${_bestCoupon!.calculateSavings(widget.price).toStringAsFixed(0)} more with "${_bestCoupon!.couponcode}"!',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Text(
                    'APPLY',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Have a Coupon?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
                  TextButton.icon(
                    onPressed: () => CouponSelector.show(
                      context: context,
                      serviceType: 'package',
                      serviceId: int.tryParse(widget.packageId),
                      amount: widget.price,
                      onSelect: (c) {
                        _couponController.text = c.couponcode;
                        _applyCoupon();
                      },
                    ),
                    icon: const Icon(Icons.local_offer_rounded, size: 18),
                    label: const Text('View Offers'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _couponController,
                      decoration: InputDecoration(
                        hintText: 'Enter code',
                        prefixIcon: const Icon(Icons.local_offer_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: const Color(0xFF8B5CF6),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _isApplyingCoupon ? null : _applyCoupon,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 90,
                        height: 50,
                        alignment: Alignment.center,
                        child: _isApplyingCoupon
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                'Apply',
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_appliedCoupon != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Coupon "${_appliedCoupon!.couponcode}" applied! Saved ₹${_discountAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B5CF6),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: Text('Confirm & Pay ₹$_formattedAmount', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }
}
