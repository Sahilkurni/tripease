import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/room_model.dart';
import '../../services/hotel_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';

class GuestDetailsScreen extends StatefulWidget {
  final String hotelId;
  final String hotelName;
  final RoomModel room;

  const GuestDetailsScreen({
    super.key,
    required this.hotelId,
    required this.hotelName,
    required this.room,
  });

  @override
  State<GuestDetailsScreen> createState() => _GuestDetailsScreenState();
}

class _GuestDetailsScreenState extends State<GuestDetailsScreen> {
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _paxController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    paymentService.init(
      onSuccess: _onPaymentSuccess,
      onError: _onPaymentError,
    );
  }

  void _onPaymentSuccess(String paymentId) {
    _createBooking(paymentId);
  }

  void _onPaymentError(String error) {
    // FOR TESTING: Proceed with booking even if payment fails
    print("Payment Failed/Cancelled: $error. Proceeding with test booking...");
    _createBooking("TEST_PAYMENT_BYPASS");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _paxController.dispose();
    paymentService.dispose();
    super.dispose();
  }

  Future<void> _handleBooking() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter guest name')),
      );
      return;
    }

    setState(() => _isLoading = true);

    paymentService.openPayment(
      amount: widget.room.price,
      name: "TripEase Hotel",
      description: "Booking for ${widget.hotelName} - ${widget.room.roomtype}",
      email: user.email,
    );
  }

  Future<void> _createBooking(String paymentId) async {
    final user = authService.currentUser!;
    try {
      final success = await hotelService.createBooking(
        userId: int.parse(user.userid),
        hotelId: int.parse(widget.hotelId),
        roomId: widget.room.roomid,
        amount: widget.room.price,
        guestName: _nameController.text,
        age: _ageController.text,
        gender: _genderController.text,
        paymentId: paymentId,
      );

      if (!mounted) return;

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Text('Booking Confirmed'),
              ],
            ),
            content: const Text('Your hotel room has been booked successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('Great!', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking failed. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
        title: Text('Guest Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(isDark),
                const SizedBox(height: 32),
                _buildGuestForm(isDark),
              ],
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.hotelName,
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            widget.room.roomtype,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount:', style: TextStyle(color: Colors.white70)),
              Text('₹${widget.room.price}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
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
          Text('Primary Guest', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.calendar_today_outlined)),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _genderController,
                  decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_outlined)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _paxController,
            decoration: const InputDecoration(labelText: 'Number of Guests (PAX)', prefixIcon: Icon(Icons.group_outlined)),
            keyboardType: TextInputType.number,
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
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 20, offset: const Offset(0, -10))],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('Confirm & Pay ₹${widget.room.price}', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
