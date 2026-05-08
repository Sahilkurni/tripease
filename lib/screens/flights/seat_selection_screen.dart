import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/flight_model.dart';
import '../../models/seat_model.dart';
import '../../services/flight_service.dart';
import '../../services/auth_service.dart';
import 'flight_passenger_details_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final FlightModel flight;
  const SeatSelectionScreen({super.key, required this.flight});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  List<SeatModel> _seats = [];
  bool _isLoading = true;
  String? _error;
  final List<SeatModel> _selectedSeats = [];
  final int _maxSeats = 6;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final seats = await flightService.getFlightSeats(widget.flight.flightId);
      setState(() {
        _seats = seats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load seats';
        _isLoading = false;
      });
    }
  }

  void _toggleSeat(SeatModel seat) {
    if (seat.isBooked == 1) return;

    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
        seat.isSelected = false;
      } else {
        if (_selectedSeats.length < _maxSeats) {
          _selectedSeats.add(seat);
          seat.isSelected = true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select a maximum of 6 seats')),
          );
        }
      }
    });
  }

  double get _totalPrice => _selectedSeats.length * widget.flight.price;

  Future<void> _processBooking() async {
    if (_selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one seat')),
      );
      return;
    }

    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a flight')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlightPassengerDetailsScreen(
          flight: widget.flight,
          selectedSeats: _selectedSeats,
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Booking Successful!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Your flight from ${widget.flight.fromCityName} to ${widget.flight.toCityName} has been booked.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to details
                Navigator.of(context).pop(); // Go back to list/dashboard
              },
              child: Text(
                'Back to Home',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ),
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
          'Select Seats',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    _buildLegend(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: _buildSeatGrid(),
                      ),
                    ),
                    _buildBottomBar(isDark),
                  ],
                ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Available', Colors.green),
          const SizedBox(width: 20),
          _legendItem('Booked', Colors.red),
          const SizedBox(width: 20),
          _legendItem('Selected', Colors.blue),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildSeatGrid() {
    // Group seats into rows of 4 for a 2x2 layout
    List<List<SeatModel>> rows = [];
    for (int i = 0; i < _seats.length; i += 4) {
      int end = (i + 4 < _seats.length) ? i + 4 : _seats.length;
      rows.add(_seats.sublist(i, end));
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Cockpit indicator
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: Text(
                'COCKPIT',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey,
                  letterSpacing: 2,
                ),
              ),
            ),
            ...List.generate(rows.length, (index) {
              final rowSeats = rows[index];
              final isEmergencyExit = (index + 1) == 5; // Let's say Row 5 is emergency exit

              return Column(
                children: [
                  if (isEmergencyExit) _buildEmergencyExitLabel(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left side (2 seats)
                        ...List.generate(2, (i) {
                          if (i < rowSeats.length) {
                            return _buildSeatItem(rowSeats[i]);
                          }
                          return const SizedBox(width: 45);
                        }),
                        
                        // Aisle
                        const SizedBox(width: 40, child: Center(child: Text(''))),

                        // Right side (2 seats)
                        ...List.generate(2, (i) {
                          int seatIdx = i + 2;
                          if (seatIdx < rowSeats.length) {
                            return _buildSeatItem(rowSeats[seatIdx]);
                          }
                          return const SizedBox(width: 45);
                        }),
                      ],
                    ),
                  ),
                  if (isEmergencyExit) const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyExitLabel() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.exit_to_app_rounded, color: Colors.orange, size: 14),
          const SizedBox(width: 6),
          Text(
            'EMERGENCY EXIT',
            style: GoogleFonts.poppins(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatItem(SeatModel seat) {
    Color seatColor = Colors.green;
    if (seat.isBooked == 1) {
      seatColor = Colors.red;
    } else if (_selectedSeats.contains(seat)) {
      seatColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: Container(
        width: 45,
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (_selectedSeats.contains(seat))
              BoxShadow(
                color: Colors.blue.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            seat.seatNumber,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
                  '${_selectedSeats.length} Seats Selected',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '₹${_totalPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _selectedSeats.isEmpty ? null : _processBooking,
                child: Text(
                  'Book Now',
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
