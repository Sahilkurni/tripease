import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/admin_service.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
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
    String type = 'PERCENT';

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
                            value: 'PERCENT',
                            child: Text('Percentage (%)'),
                          ),
                          DropdownMenuItem(
                            value: 'FLAT',
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
                        (item['couponcode'] ?? '-').toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, color: _ink),
                      ),
                    ),
                    DataCell(Text((item['discounttype'] ?? '-').toString(), style: TextStyle(color: _ink))),
                    DataCell(
                      Text(
                        item['discounttype'] == 'PERCENT'
                            ? '${item['discountvalue']}%'
                            : '₹${item['discountvalue']}', style: TextStyle(color: _ink),
                      ),
                    ),
                    DataCell(Text('₹${item['minamount'] ?? '0'}', style: TextStyle(color: _ink))),
                    DataCell(Text(_lifetime(item['expirydate']), style: TextStyle(color: _ink))),
                    DataCell(_statusChip(item['status'] ?? (isActive ? 'approved' : 'inactive'))),
                    DataCell(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item['status'] == 'pending') ...[
                              _actionButton(
                                icon: Icons.check_rounded,
                                color: Colors.green,
                                tooltip: 'Approve',
                                onTap: _updating || id == null ? null : () => _updateApproval(id!, 'approved'),
                              ),
                              const SizedBox(width: 8),
                              _actionButton(
                                icon: Icons.close_rounded,
                                color: Colors.red,
                                tooltip: 'Reject',
                                onTap: _updating || id == null ? null : () => _updateApproval(id!, 'rejected'),
                              ),
                              const SizedBox(width: 12),
                              Container(width: 1, height: 20, color: _muted.withAlpha(50)),
                              const SizedBox(width: 12),
                            ],
                            _actionButton(
                              icon: isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: isActive ? Colors.orange : Colors.blue,
                              tooltip: isActive ? 'Disable' : 'Enable',
                              onTap: _updating || id == null ? null : () => _toggleStatus(id, isActive ? 1 : 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(Theme.of(context).brightness == Brightness.dark ? 30 : 15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withAlpha(50), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
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
        final isActive = int.tryParse((item['isactive'] ?? '0').toString()) == 1;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (item['couponcode'] ?? '-').toString(),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: _ink, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'Type: ${(item['discounttype'] ?? '-').toString()} | Value: ${item['discounttype'] == 'PERCENT' ? '${item['discountvalue']}%' : '₹${item['discountvalue']}'}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 12),
              _statusChip(item['status'] ?? (isActive ? 'ACTIVE' : 'INACTIVE')),
              const Divider(height: 24),
              Row(
                children: [
                  if (item['status'] == 'pending') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _updating || id == null ? null : () => _updateApproval(id!, 'approved'),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _updating || id == null ? null : () => _updateApproval(id!, 'rejected'),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _updating || id == null ? null : () => _toggleStatus(id, isActive ? 1 : 0),
                      icon: Icon(isActive ? Icons.block : Icons.check_circle_outline, size: 16),
                      label: Text(isActive ? 'Disable' : 'Enable'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateApproval(int id, String status) async {
    setState(() => _updating = true);
    final response = await adminService.updateCouponApproval(
      couponId: id,
      status: status,
    );
    if (!mounted) return;
    setState(() => _updating = false);

    if (response['status'] == 'success') {
      _showMessage('Coupon $status');
      await _fetchData();
    } else {
      _showMessage(response['message']?.toString() ?? 'Failed', isError: true);
    }
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    Color fg;
    switch (s) {
      case 'approved':
      case 'active':
        fg = Colors.green;
        break;
      case 'pending':
        fg = Colors.orange;
        break;
      case 'rejected':
      case 'inactive':
        fg = Colors.red;
        break;
      default:
        fg = Colors.grey;
    }
    final bg = fg.withAlpha(Theme.of(context).brightness == Brightness.dark ? 40 : 25);
    return Chip(
      label: Text(
        s.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
      backgroundColor: bg,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
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
            color: Theme.of(context).dividerColor.withAlpha(50),
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
