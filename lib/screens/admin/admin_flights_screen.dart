import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/flight_model.dart';
import '../../services/flight_service.dart';

class AdminFlightsScreen extends StatefulWidget {
  const AdminFlightsScreen({super.key});

  @override
  State<AdminFlightsScreen> createState() => _AdminFlightsScreenState();
}

class _AdminFlightsScreenState extends State<AdminFlightsScreen> {
  List<FlightModel> _flights = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() => _isLoading = true);
    final flights = await flightService.getAdminFlights();
    setState(() {
      _flights = flights;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(int flightId, String status) async {
    final success = await flightService.updateFlightStatus(flightId, status);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flight $status successfully')),
      );
      _loadFlights();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      appBar: AppBar(
        title: Text(
          'Manage Flights',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFlights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flights.isEmpty
              ? _buildEmptyState()
              : _buildFlightsTable(isDark),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No flights found',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightsTable(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: DataTable(
              columnSpacing: 30,
              headingRowColor: MaterialStateProperty.all(
                AppColors.primary.withOpacity(0.1),
              ),
              columns: [
                _buildColumn('Airline'),
                _buildColumn('Flight No'),
                _buildColumn('Route'),
                _buildColumn('Price'),
                _buildColumn('Status'),
                _buildColumn('Actions'),
              ],
              rows: _flights.map((flight) {
                return DataRow(cells: [
                  DataCell(Text(flight.airline, style: _cellStyle())),
                  DataCell(Text(flight.flightNumber, style: _cellStyle())),
                  DataCell(Text('${flight.fromCityName} -> ${flight.toCityName}', style: _cellStyle())),
                  DataCell(Text('₹${flight.price}', style: _cellStyle())),
                  DataCell(_buildStatusBadge(flight.status)),
                  DataCell(_buildActions(flight)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataColumn _buildColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }

  TextStyle _cellStyle() {
    return GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500);
  }

  Widget _buildStatusBadge(String status) {
    final color = status.toLowerCase() == 'approved'
        ? Colors.green
        : status.toLowerCase() == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActions(FlightModel flight) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (flight.status.toLowerCase() != 'approved')
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
            onPressed: () => _updateStatus(flight.flightId, 'approved'),
            tooltip: 'Approve',
          ),
        if (flight.status.toLowerCase() != 'rejected')
          IconButton(
            icon: const Icon(Icons.cancel_rounded, color: Colors.red),
            onPressed: () => _updateStatus(flight.flightId, 'rejected'),
            tooltip: 'Reject',
          ),
      ],
    );
  }
}
