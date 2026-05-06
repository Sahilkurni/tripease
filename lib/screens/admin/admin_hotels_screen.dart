import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class AdminHotelsScreen extends StatefulWidget {
  const AdminHotelsScreen({super.key});

  @override
  State<AdminHotelsScreen> createState() => _AdminHotelsScreenState();
}

class _AdminHotelsScreenState extends State<AdminHotelsScreen> {
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF2563EB);

  bool _loading = true;
  bool _updating = false;
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

    final response = await adminService.getAllHotels();
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
        print('Hotels count: ${_data.length}');
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response['message']?.toString() ?? 'Failed to load hotels';
      });
    }
  }

  Future<void> _setStatus(int id, String status) async {
    setState(() => _updating = true);
    final response = await adminService.updateHotelStatus(
      hotelId: id,
      status: status,
    );
    if (!mounted) return;
    setState(() => _updating = false);

    if (response['status'] == 'success') {
      _showMessage('Hotel updated successfully');
      setState(() {
        _data =
            _data.where((item) {
              final itemId = int.tryParse((item['hotelid'] ?? '').toString());
              return itemId != id;
            }).toList();
      });
    } else {
      print("response $response");
      _showMessage(
        response['message']?.toString() ?? 'Failed to update hotel',
        isError: true,
      );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
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
                width: isDesktop ? 520 : width - 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotels Management',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Approve or reject hotel listings.',
                      style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loading || _updating ? null : _fetchData,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
            DataColumn(label: Text('Hotel Name')),
            DataColumn(label: Text('Owner Name')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('Rating')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows:
              _data.map((item) {
                final id = int.tryParse((item['hotelid'] ?? '').toString());
                return DataRow(
                  cells: [
                    DataCell(Text((item['hotelname'] ?? '-').toString())),
                    DataCell(Text((item['ownername'] ?? '-').toString())),
                    DataCell(
                      Text((item['cityid'] ?? item['city'] ?? '-').toString()),
                    ),
                    DataCell(
                      Text(
                        (item['rating'] ?? item['star_rating'] ?? '0')
                            .toString(),
                      ),
                    ),
                    DataCell(_statusChip((item['status'] ?? '').toString())),
                    DataCell(
                      id == null
                          ? const Text('-')
                          : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ActionButton(
                                label: 'Approve',
                                onPressed:
                                    _updating
                                        ? null
                                        : () => _setStatus(id, 'APPROVED'),
                              ),
                              const SizedBox(width: 8),
                              _ActionButton(
                                label: 'Reject',
                                danger: true,
                                onPressed:
                                    _updating
                                        ? null
                                        : () => _setStatus(id, 'REJECTED'),
                              ),
                            ],
                          ),
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
        final id = int.tryParse((item['hotelid'] ?? '').toString());
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
                (item['hotelname'] ?? '-').toString(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${(item['ownername'] ?? '-').toString()}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              Text(
                'City ID: ${(item['cityid'] ?? item['city'] ?? '-').toString()} | Rating: ${(item['rating'] ?? item['star_rating'] ?? '0').toString()}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 12),
              _statusChip((item['status'] ?? '').toString()),
              const Divider(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionButton(
                    label: 'Approve',
                    onPressed:
                        _updating || id == null
                            ? null
                            : () => _setStatus(id, 'APPROVED'),
                  ),
                  _ActionButton(
                    label: 'Reject',
                    danger: true,
                    onPressed:
                        _updating || id == null
                            ? null
                            : () => _setStatus(id, 'REJECTED'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final normalized = status.toUpperCase();
    final isApproved = normalized == 'APPROVED';
    final isRejected = normalized == 'REJECTED';
    final fg =
        isApproved
            ? Colors.green.shade800
            : isRejected
            ? Colors.red.shade800
            : Colors.orange.shade800;
    final bg =
        isApproved
            ? Colors.green.shade50
            : isRejected
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
    itemCount: 6,
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
      'No hotels found',
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

class _ActionButton extends StatelessWidget {
  final String label;
  final bool danger;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: danger ? Colors.red.shade700 : const Color(0xFF2563EB),
        side: BorderSide(
          color: danger ? Colors.red.shade200 : const Color(0xFFBFDBFE),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
