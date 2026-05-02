import 'package:flutter/material.dart';
import '../../services/bus_service.dart';
import '../../models/bus_model.dart';
import 'package:go_router/go_router.dart';

class BusListScreen extends StatefulWidget {
  final String source;
  final String destination;
  final String date;

  const BusListScreen({
    super.key,
    required this.source,
    required this.destination,
    required this.date,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  bool _isLoading = true;
  List<BusModel> _buses = [];

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    try {
      final buses = await busService.searchBuses(widget.source, widget.destination, widget.date);
      if (mounted) {
        setState(() {
          _buses = buses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.source} ➔ ${widget.destination}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.date.split('T').first, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buses.isEmpty
              ? const Center(child: Text('No buses found for this route.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _buses.length,
                  itemBuilder: (context, index) {
                    final bus = _buses[index];
                    return _buildBusCard(bus);
                  },
                ),
    );
  }

  Widget _buildBusCard(BusModel bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(bus.busName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('₹${bus.baseFare}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 8),
            Text('${bus.busType} | ${bus.layoutType}', style: TextStyle(color: Colors.grey[600])),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.departureTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(bus.sourceCityName ?? 'Source', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(bus.arrivalTime, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(bus.destinationCityName ?? 'Dest', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/bus/seats', extra: bus),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Select Seats'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
