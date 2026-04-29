import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bus_provider.dart';

class BusSearchScreen extends ConsumerStatefulWidget {
  const BusSearchScreen({super.key});

  @override
  ConsumerState<BusSearchScreen> createState() => _BusSearchScreenState();
}

class _BusSearchScreenState extends ConsumerState<BusSearchScreen> {
  final _sourceController = TextEditingController(text: 'Mumbai');
  final _destController = TextEditingController(text: 'Goa');
  DateTime _selectedDate = DateTime.now();

  void _searchBuses() {
    ref.read(busSearchProvider.notifier).searchBuses(
      _sourceController.text,
      _destController.text,
      _selectedDate.toIso8601String(),
    );
    context.push('/bus_list', extra: {
      'source': _sourceController.text,
      'destination': _destController.text,
    });
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Buses')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _sourceController,
                    decoration: const InputDecoration(
                      labelText: 'Leaving From',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: _destController,
                    decoration: const InputDecoration(
                      labelText: 'Going To',
                      prefixIcon: Icon(Icons.location_on),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_month, color: Colors.grey),
                    title: const Text('Journey Date', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _searchBuses,
              child: const Text('Search Buses'),
            ),
          ],
        ),
      ),
    );
  }
}
