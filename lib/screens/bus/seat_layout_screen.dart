import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/bus_model.dart';

class SeatLayoutScreen extends StatefulWidget {
  final BusModel bus;
  const SeatLayoutScreen({super.key, required this.bus});

  @override
  State<SeatLayoutScreen> createState() => _SeatLayoutScreenState();
}

class _SeatLayoutScreenState extends State<SeatLayoutScreen> {
  final Set<String> _selectedSeats = {};
  final List<String> _bookedSeats = ['1A', '2B', '5C', '5D'];

  void _toggleSeat(String seat) {
    if (_bookedSeats.contains(seat)) return;
    setState(() {
      if (_selectedSeats.contains(seat)) {
        _selectedSeats.remove(seat);
      } else {
        if (_selectedSeats.length < 4) {
          _selectedSeats.add(seat);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select a maximum of 4 seats.')),
          );
        }
      }
    });
  }

  Widget _buildSeat(String id) {
    final isBooked = _bookedSeats.contains(id);
    final isSelected = _selectedSeats.contains(id);

    return GestureDetector(
      onTap: () => _toggleSeat(id),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isBooked
              ? Colors.grey.shade300
              : isSelected
                  ? Colors.blue
                  : Colors.white,
          border: Border.all(
            color: isBooked ? Colors.grey.shade400 : Colors.blue,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            id,
            style: TextStyle(
              color: isSelected ? Colors.white : (isBooked ? Colors.grey : Colors.blue),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Seats - ${widget.bus.operatorName}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendWidget(Colors.white, 'Available'),
                _buildLegendWidget(Colors.blue, 'Selected'),
                _buildLegendWidget(Colors.grey.shade300, 'Booked'),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.topRight,
                      child: Icon(Icons.panorama_horizontal_select, size: 32, color: Colors.grey), // Steering wheel mock
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        itemCount: 40,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) {
                          if (index % 5 == 2) return const SizedBox.shrink(); // Aisle
                          
                          int row = (index / 5).floor() + 1;
                          String col = ['A', 'B', '', 'C', 'D'][index % 5];
                          return _buildSeat('$row$col');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      bottomSheet: _selectedSeats.isEmpty ? const SizedBox.shrink() : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_selectedSeats.length} Seats | \$${widget.bus.fare * _selectedSeats.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_selectedSeats.join(', '), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                context.push('/passenger_details', extra: {
                  'bus': widget.bus,
                  'seats': _selectedSeats.toList(),
                });
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendWidget(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
