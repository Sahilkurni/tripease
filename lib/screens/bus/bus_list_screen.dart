import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/bus_service.dart';
import '../../models/bus_model.dart';

class BusListScreen extends StatefulWidget {
  final String? source;
  final String? destination;
  final String? date;

  const BusListScreen({
    super.key,
    this.source,
    this.destination,
    this.date,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  final BusService _busService = busService;
  List<BusModel> _buses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    try {
      List<BusModel> buses;
      if (widget.source != null && widget.source!.isNotEmpty && 
          widget.destination != null && widget.destination!.isNotEmpty) {
        buses = await _busService.searchBuses(
          widget.source!, 
          widget.destination!, 
          widget.date ?? DateTime.now().toIso8601String()
        );
      } else {
        buses = await _busService.getHomeBusTrips();
      }
      
      setState(() {
        _buses = buses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          (widget.source != null && widget.source!.isNotEmpty) 
            ? '${widget.source} to ${widget.destination}'
            : 'Available Bus Trips',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _buses.isEmpty
                  ? _buildEmptyState(isDark)
                  : isDesktop
                      ? _buildGrid(context, isDark)
                      : _buildList(context, isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No buses found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 450,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: 220,
      ),
      itemCount: _buses.length,
      itemBuilder: (context, index) => _BusTripCard(bus: _buses[index], isDark: isDark),
    );
  }

  Widget _buildList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _buses.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _BusTripCard(bus: _buses[index], isDark: isDark),
      ),
    );
  }
}

class _BusTripCard extends StatelessWidget {
  final BusModel bus;
  final bool isDark;

  const _BusTripCard({required this.bus, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus.busName,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                '₹${bus.baseFare.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bus.busType,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeLoc(bus.departureTime, bus.sourceCityName ?? 'Source', false),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB), size: 20),
              _buildTimeLoc(bus.arrivalTime, bus.destinationCityName ?? 'Dest', true),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/bus/seats', extra: bus),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB).withAlpha(30),
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Select Seats', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLoc(String time, String loc, bool alignEnd) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        Text(
          loc,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
