import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bus_provider.dart';
import 'widgets/bus_card.dart';

class BusListScreen extends ConsumerWidget {
  final String source;
  final String destination;
  
  const BusListScreen({super.key, required this.source, required this.destination});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busState = ref.watch(busSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('$source to $destination', style: const TextStyle(fontSize: 16)),
            const Text('Showing available buses', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
      body: busState.when(
        data: (buses) {
          if (buses.isEmpty) {
            return const Center(child: Text('No buses found for this route.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              return BusCard(bus: buses[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
