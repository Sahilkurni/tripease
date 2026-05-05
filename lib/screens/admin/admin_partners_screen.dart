import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/admin_service.dart';

class AdminPartnersScreen extends StatefulWidget {
  const AdminPartnersScreen({super.key});

  @override
  State<AdminPartnersScreen> createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF2563EB);
  static const String _allStatus = 'ALL';

  bool _loading = true;
  bool _updating = false;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = _allStatus;
  List<Map<String, dynamic>> _partners = [];

  @override
  void initState() {
    super.initState();
    _fetchPartners();
  }

  Future<void> _fetchPartners() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await adminService.getAllPartners();
    if (!mounted) return;

    if (response['status'] == 'success') {
      final list = response['data'];
      setState(() {
        _partners = list is List
            ? list
                .whereType<Map>()
                .map((e) => e.map((key, value) => MapEntry('$key', value)))
                .toList()
            : [];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response['message']?.toString() ?? 'Failed to load partners';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPartners {
    final q = _searchQuery.toLowerCase().trim();
    return _partners.where((partner) {
      final company = (partner['companyname'] ?? '').toString().toLowerCase();
      final owner = (partner['ownername'] ?? '').toString().toLowerCase();
      final status = (partner['status'] ?? '').toString().toUpperCase();
      final searchMatch = q.isEmpty || company.contains(q) || owner.contains(q);
      final statusMatch = _statusFilter == _allStatus || status == _statusFilter;
      return searchMatch && statusMatch;
    }).toList();
  }

  Future<void> _setStatus({
    required int partnerId,
    required String status,
    double? commission,
  }) async {
    setState(() => _updating = true);
    final response = await adminService.updatePartnerStatus(
      partnerId: partnerId,
      status: status,
      commission: commission,
    );
    if (!mounted) return;
    setState(() => _updating = false);

    if (response['status'] == 'success') {
      _showMessage('Partner updated successfully');
      await _fetchPartners();
    } else {
      _showMessage(
        response['message']?.toString() ?? 'Failed to update partner',
        isError: true,
      );
    }
  }

  Future<void> _openCommissionDialog(Map<String, dynamic> partner) async {
    final partnerId = int.tryParse((partner['partnerid'] ?? '').toString());
    if (partnerId == null) return;

    final controller = TextEditingController(
      text: (partner['commission'] ?? '').toString(),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Commission %'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Enter commission (e.g. 10)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed == null || parsed < 0 || parsed > 100) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter valid commission between 0 and 100')),
                  );
                  return;
                }
                Navigator.pop(ctx, parsed);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (value == null) return;
    await _setStatus(partnerId: partnerId, status: 'APPROVED', commission: value);
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final partners = _filteredPartners;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partners Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Approve/reject partners and manage commission settings.',
            style: GoogleFonts.poppins(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 16),
          _buildFilters(isDesktop: isDesktop),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _loading
                  ? _buildLoading(isDesktop: isDesktop)
                  : _error != null
                      ? _buildError()
                      : partners.isEmpty
                          ? _buildEmpty()
                          : isDesktop
                              ? _buildDesktopTable(partners)
                              : _buildMobileCards(partners),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters({required bool isDesktop}) {
    final searchField = TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search by company or owner',
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );

    final statusFilter = DropdownButtonFormField<String>(
      value: _statusFilter,
      items: const [
        DropdownMenuItem(value: _allStatus, child: Text('All Status')),
        DropdownMenuItem(value: 'PENDING', child: Text('Pending')),
        DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
        DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
      ],
      onChanged: (value) => setState(() => _statusFilter = value ?? _allStatus),
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );

    final refresh = ElevatedButton.icon(
      onPressed: _loading || _updating ? null : _fetchPartners,
      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
      label: const Text('Refresh'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(130, 48),
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 5, child: searchField),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: statusFilter),
          const SizedBox(width: 12),
          refresh,
        ],
      );
    }
    return Column(
      children: [
        searchField,
        const SizedBox(height: 10),
        statusFilter,
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: refresh),
      ],
    );
  }

  Widget _buildDesktopTable(List<Map<String, dynamic>> partners) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          columns: const [
            DataColumn(label: Text('Company Name')),
            DataColumn(label: Text('Owner Name')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Commission')),
            DataColumn(label: Text('Actions')),
          ],
          rows: partners.map((p) {
            final partnerId = int.tryParse((p['partnerid'] ?? '').toString());
            return DataRow(
              cells: [
                DataCell(Text((p['companyname'] ?? '-').toString())),
                DataCell(Text((p['ownername'] ?? '-').toString())),
                DataCell(Text((p['city'] ?? '-').toString())),
                DataCell(_statusChip((p['status'] ?? '').toString())),
                DataCell(Text('${p['commission'] ?? 0}%')),
                DataCell(
                  partnerId == null
                      ? const Text('-')
                      : Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _updating
                                  ? null
                                  : () => _setStatus(
                                        partnerId: partnerId,
                                        status: 'APPROVED',
                                      ),
                              child: const Text('Approve'),
                            ),
                            OutlinedButton(
                              onPressed: _updating
                                  ? null
                                  : () => _setStatus(
                                        partnerId: partnerId,
                                        status: 'REJECTED',
                                      ),
                              child: const Text('Reject'),
                            ),
                            ElevatedButton(
                              onPressed:
                                  _updating ? null : () => _openCommissionDialog(p),
                              child: const Text('Set Commission %'),
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

  Widget _buildMobileCards(List<Map<String, dynamic>> partners) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: partners.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = partners[i];
        final partnerId = int.tryParse((p['partnerid'] ?? '').toString());
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (p['companyname'] ?? '-').toString(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Owner: ${(p['ownername'] ?? '-').toString()}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              Text(
                'City: ${(p['city'] ?? '-').toString()}',
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip((p['status'] ?? '').toString()),
                  Chip(
                    label: Text(
                      'Commission: ${p['commission'] ?? 0}%',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Divider(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _updating || partnerId == null
                        ? null
                        : () => _setStatus(
                              partnerId: partnerId,
                              status: 'APPROVED',
                            ),
                    child: const Text('Approve'),
                  ),
                  OutlinedButton(
                    onPressed: _updating || partnerId == null
                        ? null
                        : () => _setStatus(
                              partnerId: partnerId,
                              status: 'REJECTED',
                            ),
                    child: const Text('Reject'),
                  ),
                  ElevatedButton(
                    onPressed: _updating || partnerId == null
                        ? null
                        : () => _openCommissionDialog(p),
                    child: const Text('Set Commission %'),
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
    final fg = isApproved
        ? Colors.green.shade800
        : isRejected
            ? Colors.red.shade800
            : Colors.orange.shade800;
    final bg = isApproved
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
    );
  }

  Widget _buildLoading({required bool isDesktop}) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List.generate(
            8,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Text(
        'No partners found',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _muted,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchPartners,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
