import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/role_constants.dart';
import '../../services/admin_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF2563EB);
  static const String _allRoles = 'ALL';

  bool _loading = true;
  bool _updatingStatus = false;
  String? _error;
  String _searchQuery = '';
  String _roleFilter = _allRoles;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await adminService.getAllUsers();
    if (!mounted) return;

    if (response['status'] == 'success') {
      final list = response['data'];
      setState(() {
        _users = list is List
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
        _error = response['message']?.toString() ?? 'Failed to load users';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((user) {
      final fullName = (user['fullname'] ?? user['name'] ?? '')
          .toString()
          .toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final roleId = (user['roleid'] ?? '').toString();
      final query = _searchQuery.toLowerCase().trim();

      final searchMatch =
          query.isEmpty || fullName.contains(query) || email.contains(query);
      final roleMatch = _roleFilter == _allRoles || roleId == _roleFilter;
      return searchMatch && roleMatch;
    }).toList();
  }

  Future<void> _toggleStatus(Map<String, dynamic> user) async {
    final targetUserId = int.tryParse((user['userid'] ?? '').toString());
    final roleId = int.tryParse((user['roleid'] ?? '').toString());
    final currentActive = (user['isactive'] ?? '0').toString() == '1';
    if (targetUserId == null) return;

    if (roleId == RoleConstants.admin && currentActive) {
      _showMessage('Active admin user cannot be deactivated.', isError: true);
      return;
    }

    setState(() => _updatingStatus = true);
    final response = await adminService.updateUserStatus(
      targetUserId: targetUserId,
      isActive: !currentActive,
    );
    if (!mounted) return;
    setState(() => _updatingStatus = false);

    if (response['status'] == 'success') {
      _showMessage(
        !currentActive ? 'User activated successfully' : 'User deactivated',
      );
      await _fetchUsers();
    } else {
      _showMessage(
        response['message']?.toString() ?? 'Failed to update user status',
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
    final users = _filteredUsers;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users Management',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search users, filter by role, and manage account status.',
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
                  ? _buildShimmer(isDesktop: isDesktop)
                  : _error != null
                      ? _buildError()
                      : users.isEmpty
                          ? _buildEmpty()
                          : isDesktop
                              ? _buildDesktopTable(users)
                              : _buildMobileCards(users),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters({required bool isDesktop}) {
    final roleOptions = const [
      DropdownMenuItem(value: _allRoles, child: Text('All Roles')),
      DropdownMenuItem(
        value: '${RoleConstants.admin}',
        child: Text('Admin'),
      ),
      DropdownMenuItem(
        value: '${RoleConstants.customer}',
        child: Text('Customer'),
      ),
      DropdownMenuItem(
        value: '${RoleConstants.hotelOwner}',
        child: Text('Hotel Owner'),
      ),
      DropdownMenuItem(
        value: '${RoleConstants.travelAgent}',
        child: Text('Travel Agent'),
      ),
    ];

    final searchField = TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Search by name or email',
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );

    final roleDropdown = DropdownButtonFormField<String>(
      value: _roleFilter,
      items: roleOptions,
      onChanged: (value) => setState(() => _roleFilter = value ?? _allRoles),
      decoration: InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );

    final refreshButton = ElevatedButton.icon(
      onPressed: _loading || _updatingStatus ? null : _fetchUsers,
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
          Expanded(flex: 3, child: roleDropdown),
          const SizedBox(width: 12),
          refreshButton,
        ],
      );
    }

    return Column(
      children: [
        searchField,
        const SizedBox(height: 10),
        roleDropdown,
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: refreshButton),
      ],
    );
  }

  Widget _buildDesktopTable(List<Map<String, dynamic>> users) {
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
            DataColumn(label: Text('User ID')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Action')),
          ],
          rows: users.map((u) {
            final isActive = (u['isactive'] ?? '0').toString() == '1';
            return DataRow(
              cells: [
                DataCell(Text('${u['userid'] ?? '-'}')),
                DataCell(Text((u['fullname'] ?? u['name'] ?? '-').toString())),
                DataCell(Text((u['email'] ?? '-').toString())),
                DataCell(Text(_roleLabel((u['roleid'] ?? '').toString()))),
                DataCell(_statusChip(isActive)),
                DataCell(
                  Switch(
                    value: isActive,
                    onChanged: _updatingStatus ? null : (_) => _toggleStatus(u),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileCards(List<Map<String, dynamic>> users) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final u = users[index];
        final isActive = (u['isactive'] ?? '0').toString() == '1';
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
                (u['fullname'] ?? u['name'] ?? '-').toString(),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (u['email'] ?? '-').toString(),
                style: GoogleFonts.poppins(fontSize: 13, color: _muted),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(
                      'ID: ${u['userid'] ?? '-'}',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  Chip(
                    label: Text(
                      _roleLabel((u['roleid'] ?? '').toString()),
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  _statusChip(isActive),
                ],
              ),
              const Divider(height: 22),
              Row(
                children: [
                  Text(
                    'Active',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: _ink,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isActive,
                    onChanged: _updatingStatus ? null : (_) => _toggleStatus(u),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(bool isActive) {
    return Chip(
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.poppins(
          color: isActive ? Colors.green.shade800 : Colors.red.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isActive ? Colors.green.shade50 : Colors.red.shade50,
    );
  }

  Widget _buildShimmer({required bool isDesktop}) {
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: List.generate(
            8,
            (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              height: 40,
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
        height: 110,
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
        'No users found',
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
            onPressed: _fetchUsers,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String roleId) {
    switch (int.tryParse(roleId)) {
      case RoleConstants.admin:
        return 'Admin';
      case RoleConstants.customer:
        return 'Customer';
      case RoleConstants.hotelOwner:
        return 'Hotel Owner';
      case RoleConstants.travelAgent:
        return 'Travel Agent';
      default:
        return 'Unknown';
    }
  }
}
