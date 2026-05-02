import 'package:flutter/material.dart';
import '../../models/bus_model.dart';

class PassengerDetailsScreen extends StatelessWidget {
  final BusModel bus;
  final List<String> seats;

  const PassengerDetailsScreen({super.key, required this.bus, required this.seats});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traveller Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${bus.busName} • ${bus.busType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Seats: ${seats.join(', ')}'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Contact Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone)),
          ),
          const SizedBox(height: 32),
          Text('Passenger Details (${seats.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...seats.map((seat) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seat $seat', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextFormField(decoration: const InputDecoration(labelText: 'Full Name')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Age'))),
                        const SizedBox(width: 16),
                        Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Gender'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
          const SizedBox(height: 100),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Processing Payment / booking dummy
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Confirmed!')));
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text('Pay \$${bus.baseFare * seats.length}'),
        ),
      ),
    );
  }
}
