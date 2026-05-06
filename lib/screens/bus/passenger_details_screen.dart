import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bus_model.dart';
import '../../services/bus_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';

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

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.selectedSeats.length; i++) {
      _nameControllers.add(TextEditingController());
      _ageControllers.add(TextEditingController());
      _genderControllers.add(TextEditingController());
    }
    paymentService.init(
      onSuccess: _onPaymentSuccess,
      onError: _onPaymentError,
    );
  }

  void _onPaymentSuccess(String paymentId) {
    _createBookings(paymentId);
  }

  void _onPaymentError(String error) {
    // FOR TESTING: Proceed with booking even if payment fails
    print("Payment Failed/Cancelled: $error. Proceeding with test booking...");
    _createBookings("TEST_PAYMENT_BYPASS");
  }

  double get _totalAmount {
    double total = 0;
    for (var seat in widget.selectedSeats) {
      total += widget.bus.baseFare + seat.extraFare;
    }
    return total;
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _ageControllers) c.dispose();
    for (var c in _genderControllers) c.dispose();
    paymentService.dispose();
    super.dispose();
  }

  Future<void> _handleBooking() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to book')));
      return;
    }

    // Validate names
    for (int i = 0; i < _nameControllers.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter name for Seat ${widget.selectedSeats[i].seatNo}')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    paymentService.openPayment(
      amount: _totalAmount,
      name: "TripEase Bus",
      description: "Booking for ${widget.bus.busName}",
      email: user.email,
    );
  }

  Future<void> _createBookings(String paymentId) async {
    final user = authService.currentUser!;
    try {
      // Loop through each selected seat and book it
      for (var i = 0; i < widget.selectedSeats.length; i++) {
        final seat = widget.selectedSeats[i];
        await busService.bookBus(
          userId: int.parse(user.userid),
          tripId: widget.bus.busid,
          seatId: seat.seatid,
          amount: widget.bus.baseFare + seat.extraFare,
          passengerName: _nameControllers[i].text,
          age: _ageControllers[i].text,
          gender: _genderControllers[i].text,
          paymentId: paymentId,
        );
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Success',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Text(
                'Successfully booked ${widget.selectedSeats.length} seats!',
                style: GoogleFonts.poppins(),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text(
                    'Great!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
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
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSummaryCard(isDark),
                  const SizedBox(height: 32),
                  _buildContactSection(isDark),
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
                  '${widget.bus.busName} • ${widget.bus.busType}',
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
          decoration: InputDecoration(
            labelText: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Mobile Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          ),
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
                child: TextFormField(
                  controller: _genderControllers[index],
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(Icons.wc_outlined),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    double totalFare = 0;
    for (var seat in widget.selectedSeats) {
      totalFare += widget.bus.baseFare + seat.extraFare;
    }

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
      child: SafeArea(
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
                  '₹${totalFare.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2563EB),
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
}
