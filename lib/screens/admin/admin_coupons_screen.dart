import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
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

    final response = await adminService.getAllCoupons();
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
        _error = response['message']?.toString() ?? 'Failed to load coupons';
      });
    }
  }

  Future<void> _toggleStatus(int id, int currentStatus) async {
    setState(() => _updating = true);
    final response = await adminService.updateCouponStatus(
      couponId: id,
      isActive: currentStatus == 1 ? 0 : 1,
    );
    if (!mounted) return;
    setState(() => _updating = false);

    if (response['status'] == 'success') {
      _showMessage('Coupon updated');
      await _fetchData();
    } else {
      _showMessage(
        response['message']?.toString() ?? 'Failed to update coupon',
        isError: true,
      );
    }
  }

  void _openCreateDialog() {
    final codeCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    String type = 'PERCENTAGE';

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text(
                    'Create Coupon',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Coupon Code (e.g. SUMMER50)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(
                            value: 'PERCENTAGE',
                            child: Text('Percentage (%)'),
                          ),
                          DropdownMenuItem(
                            value: 'FIXED',
                            child: Text('Fixed Amount (₹)'),
                          ),
                        ],
                        onChanged: (v) => setDialogState(() => type = v!),
                        decoration: const InputDecoration(
                          labelText: 'Discount Type',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: valCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discount Value',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final code = codeCtrl.text.trim();
                        final val = double.tryParse(valCtrl.text.trim());
                        if (code.isEmpty || val == null || val <= 0) {
                          _showMessage('Invalid input', isError: true);
                          return;
                        }
                        Navigator.pop(ctx);
                        setState(() => _updating = true);
                        final res = await adminService.createCoupon(
                          code: code,
                          discountType: type,
                          discountValue: val,
                        );
                        setState(() => _updating = false);
                        if (res['status'] == 'success') {
                          _showMessage('Coupon created');
                          _fetchData();
                        } else {
                          _showMessage(
                            res['message']?.toString() ?? 'Failed to create',
                            isError: true,
                          );
                        }
                      },
                      child: const Text('Create'),
                    ),
                  ],
                ),
          ),
    );
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
                      'Coupons Management',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create and manage promotional coupons.',
                      style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                children: [
                  ElevatedButton.icon(
                    onPressed: _loading || _updating ? null : _openCreateDialog,
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _loading || _updating ? null : _fetchData,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                    ),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
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
            DataColumn(label: Text('Code')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Value')),
            DataColumn(label: Text('Min Booking')),
            DataColumn(label: Text('Valid Until')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows:
              _data.map((item) {
                final id = int.tryParse((item['couponid'] ?? '').toString());
                final isActive =
                    int.tryParse((item['isactive'] ?? '0').toString()) == 1;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        (item['code'] ?? '-').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataCell(Text((item['discount_type'] ?? '-').toString())),
                    DataCell(
                      Text(
                        item['discount_type'] == 'PERCENTAGE'
                            ? '${item['discount_value']}%'
                            : '₹${item['discount_value']}',
                      ),
                    ),
                    DataCell(Text('₹${item['min_booking_amount'] ?? '0'}')),
                    DataCell(Text(_lifetime(item['valid_until']))),
                    DataCell(_statusChip(isActive ? 'ACTIVE' : 'INACTIVE')),
                    DataCell(
                      id == null
                          ? const Text('-')
                          : OutlinedButton(
                            onPressed:
                                _updating
                                    ? null
                                    : () => _toggleStatus(id, isActive ? 1 : 0),
                            child: Text(isActive ? 'Disable' : 'Enable'),
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
        final id = int.tryParse((item['couponid'] ?? '').toString());
        final isActive =
            int.tryParse((item['isactive'] ?? '0').toString()) == 1;
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
                (item['code'] ?? '-').toString(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Type: ${(item['discount_type'] ?? '-').toString()} | Value: ${item['discount_type'] == 'PERCENTAGE' ? '${item['discount_value']}%' : '₹${item['discount_value']}'}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              Text(
                'Valid Until: ${_lifetime(item['valid_until'])}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 12),
              _statusChip(isActive ? 'ACTIVE' : 'INACTIVE'),
              const Divider(height: 24),
              OutlinedButton(
                onPressed:
                    _updating || id == null
                        ? null
                        : () => _toggleStatus(id, isActive ? 1 : 0),
                child: Text(isActive ? 'Disable' : 'Enable'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    final isActive = status == 'ACTIVE';
    final fg = isActive ? Colors.green.shade800 : Colors.red.shade800;
    final bg = isActive ? Colors.green.shade50 : Colors.red.shade50;
    return Chip(
      label: Text(
        status,
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

  String _lifetime(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Lifetime' : text;
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
      'No coupons found',
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
