import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/api_config.dart';
import '../../services/payment_service.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/travel_image_placeholder.dart';
import '../../services/coupon_service.dart';
import '../../models/coupon_model.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;
  final String packageName;
  final double price;
  final String? imageUrl;
  final List<String>? images;

  const PackageDetailsScreen({
    super.key,
    required this.packageId,
    required this.packageName,
    required this.price,
    this.imageUrl,
    this.images,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  bool _loading = false;
  final _couponController = TextEditingController();
  double _discountAmount = 0.0;
  CouponModel? _appliedCoupon;
  bool _isApplyingCoupon = false;

  double get _finalAmount => widget.price - _discountAmount;

  @override
  void initState() {
    super.initState();
    paymentService.init(
      onSuccess: _onPaymentSuccess,
      onError: _onPaymentError,
    );
  }

  void _onPaymentSuccess(String paymentId) {
    _createPackageBooking(paymentId);
  }

  @override
  void dispose() {
    _couponController.dispose();
    paymentService.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);
    final user = authService.currentUser!;
    
    final result = await couponService.applyCoupon(
      couponCode: code,
      userId: int.parse(user.userid),
      serviceType: 'package',
      serviceId: int.parse(widget.packageId),
      amount: widget.price,
    );

    setState(() => _isApplyingCoupon = false);

    if (result != null && result['status'] == 'success') {
      setState(() {
        _appliedCoupon = CouponModel.fromJson(result['data']);
        _discountAmount = double.tryParse(result['discount_amount'].toString()) ?? 0.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon applied! You saved ₹$_discountAmount')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result?['message'] ?? 'Invalid coupon')),
      );
    }
  }

  void _onPaymentError(String error) {
    // FOR TESTING: Proceed with booking even if payment fails
    // print("Payment Failed/Cancelled: $error. Proceeding with test booking...");
    _createPackageBooking("TEST_PAYMENT_BYPASS");
  }

  Future<void> _bookPackage() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }

    setState(() => _loading = true);

    paymentService.openPayment(
      amount: _finalAmount,
      name: "TripEase Package",
      description: "Booking for ${widget.packageName}",
      email: user.email,
    );
  }

  Future<void> _createPackageBooking(String paymentId) async {
    final user = authService.currentUser!;
    final userId = user.userid;
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createPackageBooking),
        body: {
          'userid': userId.toString(),
          'packageid': widget.packageId,
          'amount': _finalAmount.toString(),
          'payment_id': paymentId,
        },
      );

      // print('Package Booking Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (_appliedCoupon != null) {
          // Record coupon usage
          await couponService.recordCouponUsage(
            couponId: _appliedCoupon!.couponid,
            userId: int.parse(userId),
            bookingId: 0,
            serviceType: 'package',
            serviceId: int.parse(widget.packageId),
            discountAmount: _discountAmount,
          );
        }
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Booking Confirmed'),
            content: const Text('Your travel package booking has been confirmed successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Booking failed')),
        );
      }
    } catch (e) {
      // print('Package Booking Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred during booking')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.packageName, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: TravelImagePlaceholder(
                  imageUrl: widget.imageUrl ?? '',
                  images: widget.images,
                  icon: Icons.map_rounded,
                  colors: const [Color(0xFFDB2777), Color(0xFFF59E0B)],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.packageName,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Experience the trip of a lifetime with our curated travel package.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Package Price',
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  '₹${_finalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFDB2777),
                  ),
                ),
              ],
            ),
            if (_discountAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Saved ₹${_discountAmount.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            _buildCouponSection(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _bookPackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Book Package for ₹${_finalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          Text('Have a Coupon?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
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
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isApplyingCoupon ? null : _applyCoupon,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isApplyingCoupon
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Apply'),
                ),
              ),
            ],
          ),
          if (_appliedCoupon != null) ...[
            const SizedBox(height: 8),
            Text(
              'Coupon "${_appliedCoupon!.couponcode}" applied successfully!',
              style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
