import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/flight_model.dart';
import '../../models/seat_model.dart';
import '../../services/flight_service.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';

class FlightPassengerDetailsScreen extends StatefulWidget {
  final FlightModel flight;
  final List<SeatModel> selectedSeats;

  const FlightPassengerDetailsScreen({
    super.key,
    required this.flight,
    required this.selectedSeats,
  });

  @override
  State<FlightPassengerDetailsScreen> createState() => _FlightPassengerDetailsScreenState();
}

class _FlightPassengerDetailsScreenState extends State<FlightPassengerDetailsScreen> {
  bool _isLoading = false;
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _ageControllers = [];
  final List<TextEditingController> _genderControllers = [];
  final List<TextEditingController> _idProofControllers = [];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.selectedSeats.length; i++) {
      _nameControllers.add(TextEditingController());
      _ageControllers.add(TextEditingController());
      _genderControllers.add(TextEditingController());
      _idProofControllers.add(TextEditingController());
    }
    paymentService.init(
      onSuccess: (paymentId) => _processBooking(paymentId),
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed or cancelled: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    for (var c in _nameControllers) c.dispose();
    for (var c in _ageControllers) c.dispose();
    for (var c in _genderControllers) c.dispose();
    for (var c in _idProofControllers) c.dispose();
    paymentService.dispose();
    super.dispose();
  }

  double get _totalAmount => widget.selectedSeats.length * widget.flight.price;

  Future<void> _handleBooking() async {
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }

    // Validation
    for (int i = 0; i < _nameControllers.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter name for Seat ${widget.selectedSeats[i].seatNumber}')),
        );
        return;
      }
      if (_ageControllers[i].text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter age for Seat ${widget.selectedSeats[i].seatNumber}')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    paymentService.openPayment(
      amount: _totalAmount,
      name: "TripEase Flights",
      description: "Booking for ${widget.flight.airline} ${widget.flight.flightNumber}",
      email: user.email,
    );
  }

  Future<void> _processBooking(String paymentId) async {
    final user = authService.currentUser;
    if (user == null) return;

    try {
      final List<Map<String, dynamic>> passengers = [];
      for (int i = 0; i < widget.selectedSeats.length; i++) {
        passengers.add({
          'fullname': _nameControllers[i].text.trim(),
          'age': int.tryParse(_ageControllers[i].text.trim()) ?? 0,
          'gender': _genderControllers[i].text.trim().isEmpty ? 'Not Specified' : _genderControllers[i].text.trim(),
          'idproof': _idProofControllers[i].text.trim().isEmpty ? 'N/A' : _idProofControllers[i].text.trim(),
        });
      }

      final result = await flightService.createFlightBooking(
        userId: int.parse(user.userid),
        flightId: widget.flight.flightId,
        selectedSeats: widget.selectedSeats.map((s) => s.seatId).toList(),
        passengers: passengers,
        paymentId: paymentId,
      );

      if (!mounted) return;

      if (result['status'] == 'success') {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Booking failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
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
        content: const Text('Your flight has been booked successfully!'),
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      appBar: AppBar(
        title: Text(
          'Passenger Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSummaryCard(isDark),
                const SizedBox(height: 24),
                Text(
                  'Traveller Information',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(widget.selectedSeats.length, (index) {
                  return _buildPassengerForm(index, widget.selectedSeats[index], isDark);
                }),
                const SizedBox(height: 100),
              ],
            ),
      bottomSheet: _buildBottomBar(isDark),
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                '${widget.flight.airline} • ${widget.flight.flightNumber}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.flight.fromCityName} → ${widget.flight.toCityName}',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            'Seats: ${widget.selectedSeats.map((s) => s.seatNumber).join(', ')}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerForm(int index, SeatModel seat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Passenger ${index + 1} (Seat ${seat.seatNumber})',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameControllers[index],
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ageControllers[index],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Age',
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _genderControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: const Icon(Icons.wc_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _idProofControllers[index],
            decoration: InputDecoration(
              labelText: 'ID Proof (Aadhar/Passport)',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Price',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  '₹${_totalAmount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _handleBooking,
                child: Text(
                  'Pay & Book',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
