import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF2563EB);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await adminService.getAllBookings();
    if (!mounted) return;

    if (response['status'] == 'success') {
      final list = response['data'];
      setState(() {
        _data =
            list is List
                ? list
                    .whereType<Map>()
                    .map((e) => e.map((k, v) => MapEntry('$k', v)))
                    .toList()
                : [];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response['message']?.toString() ?? 'Failed to load bookings';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isDesktop ? 500 : width - 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bookings Log',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'View all system bookings.',
                      style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loading ? null : _fetchData,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  _loading
                      ? _buildLoading()
                      : _error != null
                      ? _buildError()
                      : _data.isEmpty
                      ? _buildEmpty()
                      : isDesktop
                      ? _buildDesktopTable()
                      : _buildMobileCards(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          columns: const [
            DataColumn(label: Text('Booking ID')),
            DataColumn(label: Text('User')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Amount')),
            DataColumn(label: Text('Status')),
          ],
          rows:
              _data.map((item) {
                return DataRow(
                  cells: [
                    DataCell(Text((item['bookingid'] ?? '-').toString())),
                    DataCell(Text((item['fullname'] ?? '-').toString())),
                    DataCell(Text((item['bookingtype'] ?? '-').toString())),
                    DataCell(Text('₹${item['totalamount'] ?? '0'}')),
                    DataCell(
                      _statusChip((item['bookingstatus'] ?? '').toString()),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCards() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = _data[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking #${item['bookingid']}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'User: ${(item['fullname'] ?? '-').toString()}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              Text(
                'Type: ${(item['bookingtype'] ?? '-').toString()} | Amount: ₹${item['totalamount']}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 12),
              _statusChip((item['bookingstatus'] ?? '').toString()),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();
    final isSuccess = normalized == 'CONFIRMED' || normalized == 'COMPLETED';
    final isFailed = normalized == 'CANCELLED' || normalized == 'FAILED';
    final fg =
        isSuccess
            ? Colors.green.shade800
            : isFailed
            ? Colors.red.shade800
            : Colors.orange.shade800;
    final bg =
        isSuccess
            ? Colors.green.shade50
            : isFailed
            ? Colors.red.shade50
            : Colors.orange.shade50;
    return Chip(
      label: Text(
        normalized.isEmpty ? 'PENDING' : normalized,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
    );
  }

  Widget _buildLoading() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 7,
    itemBuilder:
        (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 58,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
  );
  Widget _buildEmpty() => Center(
    child: Text(
      'No bookings found',
      style: GoogleFonts.poppins(fontSize: 16, color: _muted),
    ),
  );
  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
        const SizedBox(height: 12),
        Text(_error ?? 'Error', style: GoogleFonts.poppins(color: _ink)),
        ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
      ],
    ),
  );
}
