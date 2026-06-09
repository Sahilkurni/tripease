import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/booking_success_screen.dart';
import '../../models/bus_model.dart';
import '../../services/bus_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../services/coupon_service.dart';
import '../../models/coupon_model.dart';
import '../../core/utils/validators.dart';
import '../../widgets/coupon_selector.dart';

class PassengerDetailsScreen extends StatefulWidget {
  final BusModel bus;
  final List<BusSeatModel> selectedSeats;

  const PassengerDetailsScreen({
    super.key,
    required this.bus,
    required this.selectedSeats,
  });

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  bool _isLoading = false;
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _ageControllers = [];
  final List<TextEditingController> _genderControllers = [];
  final _contactEmailCtrl = TextEditingController();
  final _contactMobileCtrl = TextEditingController();
  final _couponController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _discountAmount = 0.0;
  CouponModel? _appliedCoupon;
  CouponModel? _bestCoupon;
  bool _isApplyingCoupon = false;

  double get _finalAmount => _totalAmount - _discountAmount;

  double _seatAmount(BusSeatModel seat) => widget.bus.baseFare + seat.extraFare;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.selectedSeats.length; i++) {
      _nameControllers.add(TextEditingController());
      _ageControllers.add(TextEditingController());
      _genderControllers.add(TextEditingController());
    }
    paymentService.init(onSuccess: _onPaymentSuccess, onError: _onPaymentError);
    final user = authService.currentUser;
    if (user != null) {
      _contactEmailCtrl.text = user.email;
      _fetchBestCoupon(user.userid);
    }
  }

  Future<void> _fetchBestCoupon(String userId) async {
    final best = await couponService.getBestCoupon(
      userId: int.parse(userId),
      amount: _totalAmount,
      serviceType: 'bus',
      serviceId: widget.bus.busid,
    );
    if (mounted) {
      setState(() => _bestCoupon = best);
    }
  }

  void _onPaymentSuccess(String paymentId) {
    _createBookings(paymentId);
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

  double get _totalAmount {
    double total = 0;
    for (var seat in widget.selectedSeats) {
      total += _seatAmount(seat);
    }
    return total;
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _ageControllers) c.dispose();
    for (var c in _genderControllers) c.dispose();
    _contactEmailCtrl.dispose();
    _contactMobileCtrl.dispose();
    _couponController.dispose();
    paymentService.dispose();

    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to apply coupon')),
      );
      return;
    }

    setState(() => _isApplyingCoupon = true);

    final result = await couponService.applyCoupon(
      couponCode: code,
      userId: int.parse(user.userid),
      serviceType: 'bus',
      serviceId: widget.bus.busid,
      amount: _totalAmount,
    );

    setState(() => _isApplyingCoupon = false);

    if (result != null && result['status'] == 'success') {
      setState(() {
        _appliedCoupon = CouponModel.fromJson(result['data']);
        _discountAmount =
            double.tryParse(result['data']['discount_amount'].toString()) ??
            0.0;
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

  Future<void> _handleBooking() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to book')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    paymentService.openPayment(
      amount: _finalAmount,
      name: "TripEase Bus",
      description: "Booking for ${widget.bus.busname}",
      email: _contactEmailCtrl.text.trim(),
    );
  }

  Future<void> _createBookings(String paymentId) async {
    final user = authService.currentUser!;
    try {
      int? firstBookingId;
      // Loop through each selected seat and book it
      final perSeatDiscount =
          widget.selectedSeats.isEmpty
              ? 0.0
              : _discountAmount / widget.selectedSeats.length;
      for (var i = 0; i < widget.selectedSeats.length; i++) {
        final seat = widget.selectedSeats[i];
        final bookingId = await busService.bookBus(
          userId: int.parse(user.userid),
          tripId: widget.bus.busid,
          seatId: seat.seatid,
          amount: (_seatAmount(seat) - perSeatDiscount).clamp(
            0,
            double.infinity,
          ),
          passengerName: _nameControllers[i].text,
          age: _ageControllers[i].text,
          gender: _genderControllers[i].text,
          paymentId: paymentId,
        );
        if (i == 0) {
          firstBookingId = bookingId;
        }
      }

      if (_appliedCoupon != null &&
          firstBookingId != null &&
          firstBookingId > 0) {
        // Record coupon usage
        await couponService.recordCouponUsage(
          couponId: _appliedCoupon!.couponid,
          userId: int.parse(user.userid),
          bookingId: firstBookingId,
          serviceType: 'bus',
          serviceId: widget.bus.busid,
          discountAmount: _discountAmount,
        );
      }

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => BookingSuccessScreen(
                title: 'Bus Booked! 🚌',
                subtitle:
                    'Successfully booked ${widget.selectedSeats.length} seat(s)\non ${widget.bus.busname}!',
                bookingType: 'bus',
                savedAmount:
                    _discountAmount > 0
                        ? _discountAmount.toStringAsFixed(0)
                        : null,
              ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Traveller Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSummaryCard(isDark),
                    const SizedBox(height: 32),
                    _buildContactSection(isDark),
                    const SizedBox(height: 32),
                    _buildCouponSection(isDark),
                    const SizedBox(height: 32),
                    Text(
                      'Passenger Details (${widget.selectedSeats.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(widget.selectedSeats.length, (index) {
                      return _buildPassengerForm(
                        index,
                        widget.selectedSeats[index],
                        isDark,
                      );
                    }),
                    const SizedBox(height: 120),
                  ],
                ),
              ),

      bottomSheet: _buildBottomBar(isDark),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus_filled, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${widget.bus.busname} • ${widget.bus.bustype}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seats Selected:',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              Text(
                widget.selectedSeats.map((s) => s.seatNo).join(', '),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contact Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          validator: Validators.validateEmail,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _contactMobileCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
          validator: Validators.validatePhone,
        ),
      ],
    );
  }

  Widget _buildPassengerForm(int index, BusSeatModel seat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Seat ${seat.seatNo}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameControllers[index],
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => Validators.validateRequired(v, 'name'),
          ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageControllers[index],
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value:
                      _genderControllers[index].text.isEmpty
                          ? null
                          : _genderControllers[index].text,
                  items:
                      ['Male', 'Female', 'Other']
                          .map(
                            (g) => DropdownMenuItem(value: g, child: Text(g)),
                          )
                          .toList(),
                  onChanged: (v) => _genderControllers[index].text = v ?? '',
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Payable',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  '₹${_finalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                if (_discountAmount > 0)
                  Text(
                    'Saved ₹${_discountAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Pay & Book',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
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
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Save ₹${_bestCoupon!.calculateSavings(_totalAmount).toStringAsFixed(0)} more with "${_bestCoupon!.couponcode}"!',
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
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Have a Coupon?',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        () => CouponSelector.show(
                          context: context,
                          serviceType: 'bus',
                          serviceId: widget.bus.busid,
                          amount: _totalAmount,
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _isApplyingCoupon ? null : _applyCoupon,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 90,
                        height: 50,
                        alignment: Alignment.center,
                        child:
                            _isApplyingCoupon
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Apply',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
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
}
