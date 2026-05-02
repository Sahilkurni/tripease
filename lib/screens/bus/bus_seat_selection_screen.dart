import 'package:flutter/material.dart';
import '../../models/bus_model.dart';
import 'package:go_router/go_router.dart';

class BusSeatSelectionScreen extends StatefulWidget {
  final BusModel bus;

  const BusSeatSelectionScreen({super.key, required this.bus});

  @override
  State<BusSeatSelectionScreen> createState() => _BusSeatSelectionScreenState();
}

class _BusSeatSelectionScreenState extends State<BusSeatSelectionScreen> {
  final Set<BusSeatModel> _selectedSeats = {};

  void _toggleSeat(BusSeatModel seat) {
    if (seat.isBooked) return;

    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.bus.busName} Seats'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildInfoHeader(),
          _buildLegend(),
          Expanded(child: _buildSeatLayout()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInfoHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.bus.sourceCityName} to ${widget.bus.destinationCityName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.bus.busType} | Base Fare: ₹${widget.bus.baseFare}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const Icon(Icons.directions_bus, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.white, 'Available', true),
          const SizedBox(width: 16),
          _legendItem(Colors.green, 'Selected', false),
          const SizedBox(width: 16),
          _legendItem(Colors.grey[400]!, 'Booked', false),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String text, bool hasBorder) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder ? Border.all(color: Colors.grey) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSeatLayout() {
    // Assuming a 2x2 layout with 4 columns. We will group by row.
    // Determine max rows
    int maxRows = 0;
    for (var seat in widget.bus.seats) {
      if (seat.rowNo > maxRows) maxRows = seat.rowNo;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            // Steering Wheel Icon
            const Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(bottom: 24.0, right: 16.0),
                child: Icon(Icons.sports_motorsports, size: 32, color: Colors.grey),
              ),
            ),
            
            // Generate Rows
            for (int r = 1; r <= maxRows; r++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSeatInRow(r, 1),
                    _buildSeatInRow(r, 2),
                    const SizedBox(width: 40), // Aisle
                    _buildSeatInRow(r, 3),
                    _buildSeatInRow(r, 4),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatInRow(int row, int col) {
    // Find seat
    final seatIndex = widget.bus.seats.indexWhere((s) => s.rowNo == row && s.colNo == col);
    if (seatIndex == -1) {
      return const SizedBox(width: 40, height: 40); // Empty space if no seat
    }
    
    final seat = widget.bus.seats[seatIndex];
    final isSelected = _selectedSeats.contains(seat);

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: seat.isBooked ? Colors.grey[300] : (isSelected ? Colors.green : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: seat.isBooked ? Colors.grey[400]! : (isSelected ? Colors.green[700]! : Colors.blue),
            width: 1.5,
          ),
          boxShadow: isSelected ? [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 8)] : null,
        ),
        alignment: Alignment.center,
        child: Text(
          seat.seatNo,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: seat.isBooked ? Colors.grey[600] : (isSelected ? Colors.white : Colors.blue[800]),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -5), blurRadius: 10)],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_selectedSeats.length} Seats Selected', style: TextStyle(color: Colors.grey[600])),
                Text('₹$_totalFare', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            ElevatedButton(
              onPressed: _selectedSeats.isEmpty ? null : () {
                // Proceed to payment/booking
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proceeding to payment...')));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
