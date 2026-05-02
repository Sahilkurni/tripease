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
                    bus.busName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${bus.baseFare}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TimeLoc(time: bus.departureTime, loc: bus.sourceCityName ?? 'Source'),
                  Column(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.grey),
                      Text(bus.busType, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  _TimeLoc(time: bus.arrivalTime, loc: bus.destinationCityName ?? 'Dest'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeLoc extends StatelessWidget {
  final String time;
  final String loc;
  const _TimeLoc({required this.time, required this.loc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(loc, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
