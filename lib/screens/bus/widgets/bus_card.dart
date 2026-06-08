import 'package:flutter/material.dart';
import '../../../models/bus_model.dart';
import 'package:go_router/go_router.dart';

class BusCard extends StatelessWidget {
  final BusModel bus;

  const BusCard({super.key, required this.bus});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/bus/seats', extra: bus),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bus.busname,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'No. ${bus.busnumber.isNotEmpty ? bus.busnumber : 'N/A'}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bus.bustype, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Type', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.grey),
                      Text('${bus.totalseats} Seats', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bus.amenities.isNotEmpty ? 'Has Amenities' : 'Standard', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const Text('Features', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
