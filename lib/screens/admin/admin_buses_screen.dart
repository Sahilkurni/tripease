import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class AdminBusesScreen extends StatefulWidget {
  const AdminBusesScreen({super.key});

  @override
  State<AdminBusesScreen> createState() => _AdminBusesScreenState();
}

class _AdminBusesScreenState extends State<AdminBusesScreen> {
  // Colors will be derived from theme in build()
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _ink => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF172033);
  Color get _muted => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B);
  Color get _surface => Theme.of(context).cardColor;

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

    final response = await adminService.getAllBuses();
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
        _error = response['message']?.toString() ?? 'Failed to load buses';
      });
    }
  }

  Future<void> _setStatus(int id, String status) async {
    setState(() => _updating = true);
    final response = await adminService.updateBusStatus(
      busId: id,
      status: status,
    );
    if (!mounted) return;
    setState(() => _updating = false);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _data =
            _data.where((item) {
              final itemId = int.tryParse((item['busid'] ?? '').toString());
              return itemId != id;
            }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Failed to update bus',
          ),
          backgroundColor: Colors.red,
        ),
      );
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
                width: isDesktop ? 560 : width - 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buses Management',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Approve or reject bus listings.',
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
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                border: Border.all(color: Theme.of(context).dividerColor),
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
            color: _muted,
          ),
          columns: const [
            DataColumn(label: Text('Bus Name')),
            DataColumn(label: Text('Route')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Fare')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows:
              _data.map((item) {
                final id = int.tryParse((item['busid'] ?? '').toString());
                final route =
                    '${item['source_city_name'] ?? item['source'] ?? item['source_city_id'] ?? '-'} -> ${item['destination_city_name'] ?? item['destination'] ?? item['destination_city_id'] ?? '-'}';
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        (item['bus_name'] ?? item['operator'] ?? '-')
                            .toString(), style: TextStyle(color: _ink),
                      ),
                    ),
                    DataCell(Text(route, style: TextStyle(color: _ink))),
                    DataCell(
                      Text(
                        (item['bus_type'] ?? item['layout_type'] ?? '-')
                            .toString(), style: TextStyle(color: _ink),
                      ),
                    ),
                    DataCell(
                      Text('₹${item['base_fare'] ?? item['fare'] ?? '0'}', style: TextStyle(color: _ink)),
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
        final id = int.tryParse((item['busid'] ?? '').toString());
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item['bus_name'] ?? item['operator'] ?? '-').toString(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${item['source_city_name'] ?? item['source'] ?? '-'} -> ${item['destination_city_name'] ?? item['destination'] ?? '-'}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 10),
              _statusChip((item['status'] ?? '').toString()),
              const Divider(height: 24),
              Wrap(
                spacing: 8,
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
    final fg = normalized == 'APPROVED' ? Colors.green : normalized == 'REJECTED' ? Colors.red : Colors.orange;
    final bg = fg.withAlpha(Theme.of(context).brightness == Brightness.dark ? 40 : 25);
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
            color: Theme.of(context).dividerColor.withAlpha(50),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
  );

  Widget _buildEmpty() => Center(
    child: Text(
      'No pending buses found',
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
