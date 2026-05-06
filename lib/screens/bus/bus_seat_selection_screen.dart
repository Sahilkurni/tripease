import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bus_model.dart';
import '../../services/bus_service.dart';
import '../../services/auth_service.dart';

class BusSeatSelectionScreen extends StatefulWidget {
  final BusModel bus;

  const BusSeatSelectionScreen({super.key, required this.bus});

  @override
  State<BusSeatSelectionScreen> createState() => _BusSeatSelectionScreenState();
}

class _BusSeatSelectionScreenState extends State<BusSeatSelectionScreen> {
  final Set<BusSeatModel> _selectedSeats = {};
  List<BusSeatModel> _allSeats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSeats();
  }

  Future<void> _loadSeats() async {
    try {
      if (widget.bus.busid == 0) {
        throw Exception("Invalid Trip ID (Demo Mode)");
      }
      final seatData = await busService.getBusSeats(widget.bus.busid);
      if (seatData.isEmpty) {
        throw Exception("No seats found");
      }
      setState(() {
        _allSeats = seatData.map((s) => BusSeatModel.fromJson(s)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Seat Load Error (using fallback): $e");
      setState(() {
        _allSeats = _generateMockSeats();
        _isLoading = false;
      });
    }
  }

  List<BusSeatModel> _generateMockSeats() {
    List<BusSeatModel> mock = [];
    for (int r = 1; r <= 10; r++) {
      for (int c = 1; c <= 4; c++) {
        mock.add(BusSeatModel(
          seatid: r * 10 + c,
          busid: widget.bus.busid,
          seatNo: '${String.fromCharCode(64 + r)}$c',
          rowNo: r,
          colNo: c,
          isBooked: (r + c) % 5 == 0,
        ));
      }
    }
    return mock;
  }

  void _toggleSeat(BusSeatModel seat) {
    if (seat.isBooked) return;

    setState(() {
      if (_selectedSeats.any((s) => s.seatid == seat.seatid)) {
        _selectedSeats.removeWhere((s) => s.seatid == seat.seatid);
      } else {
        if (_selectedSeats.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 6 seats can be selected')),
          );
          return;
        }
        _selectedSeats.add(seat);
      }
    });
  }

  double get _totalFare {
    double total = 0;
    for (var seat in _selectedSeats) {
      total += widget.bus.baseFare + seat.extraFare;
    }
    return total;
  }

  Future<void> _bookSeats() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // For multi-seat booking, we'd normally loop or have a bulk API
      for (var seat in _selectedSeats) {
        await busService.bookBus(
          userId: int.parse(user.userid),
          tripId: widget.bus.busid,
          seatId: seat.seatid,
          amount: widget.bus.baseFare + seat.extraFare,
        );
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Success'),
          content: Text('Successfully booked ${_selectedSeats.length} seats!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.bus.busName, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildBusInfo(isDark),
                _buildLegend(isDark),
                Expanded(child: _buildSeatLayout(isDark)),
                _buildBottomBar(isDark),
              ],
            ),
    );
  }

  Widget _buildBusInfo(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.bus.sourceCityName ?? 'Source',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB)),
              ),
              Text(
                widget.bus.destinationCityName ?? 'Destination',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.bus.busType,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(isDark ? Colors.white10 : Colors.white, 'Available', true, isDark),
          const SizedBox(width: 20),
          _legendItem(const Color(0xFF2563EB), 'Selected', false, isDark),
          const SizedBox(width: 20),
          _legendItem(isDark ? Colors.white24 : Colors.grey[300]!, 'Booked', false, isDark),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, bool hasBorder, bool isDark) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey.shade400) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSeatLayout(bool isDark) {
    int maxRows = 0;
    for (var seat in _allSeats) {
      if (seat.rowNo > maxRows) maxRows = seat.rowNo;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24, right: 8),
                child: Icon(Icons.radio_button_checked_rounded, size: 32, color: Colors.grey),
              ),
            ),
            for (int r = 1; r <= maxRows; r++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSeat(r, 1, isDark),
                    _buildSeat(r, 2, isDark),
                    const SizedBox(width: 40),
                    _buildSeat(r, 3, isDark),
                    _buildSeat(r, 4, isDark),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeat(int row, int col, bool isDark) {
    final seatIndex = _allSeats.indexWhere((s) => s.rowNo == row && s.colNo == col);
    if (seatIndex == -1) return Container(width: 36, height: 36, margin: const EdgeInsets.symmetric(horizontal: 4));

    final seat = _allSeats[seatIndex];
    final isSelected = _selectedSeats.any((s) => s.seatid == seat.seatid);

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: seat.isBooked
              ? (isDark ? Colors.white10 : Colors.grey[200])
              : (isSelected ? const Color(0xFF2563EB) : (isDark ? Colors.white12 : Colors.white)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seat.isBooked
                ? Colors.transparent
                : (isSelected ? const Color(0xFF1D4ED8) : Colors.grey.shade400),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          seat.seatNo,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: seat.isBooked
                ? Colors.grey
                : (isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
          ),
        ),
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
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_selectedSeats.length} Seats Selected',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '₹${_totalFare.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _selectedSeats.isEmpty ? null : _bookSeats,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Confirm Booking',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
