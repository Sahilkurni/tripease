import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final List<String> _menu = [
    'Overview',
    'Users',
    'Hotels',
    'Bookings',
    'Settings',
  ];

  final List<Map<String, String>> _roles = const [
    {'id': '1', 'name': 'CUSTOMER'},
    {'id': '2', 'name': 'HOTEL_OWNER'},
    {'id': '3', 'name': 'TRAVEL_AGENT'},
    {'id': '4', 'name': 'ADMIN'},
  ];

  bool _loading = false;

  void _changeRole(UserModel user, String roleId) async {
    setState(() => _loading = true);
    final res = await authService.updateRole(user.userid, roleId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated: ${res['rolename']}')),
      );
      setState(
        () {},
      ); // refresh UI (authService.currentUser updated inside service)
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${res['message'] ?? 'error'}')),
      );
    }
  }

  Widget _buildSidebar(bool isDesktop) {
    return Container(
      width: isDesktop ? 260 : 72,
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          if (isDesktop) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Text(
                'Admin',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: ListView.builder(
              itemCount: _menu.length,
              itemBuilder: (_, i) {
                final active = _selectedIndex == i;
                return ListTile(
                  dense: true,
                  leading: Icon(
                    i == 0
                        ? Icons.dashboard_rounded
                        : i == 1
                        ? Icons.group_rounded
                        : i == 2
                        ? Icons.hotel_rounded
                        : i == 3
                        ? Icons.directions_bus_rounded
                        : Icons.settings_rounded,
                    color:
                        active
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                  ),
                  title:
                      isDesktop
                          ? Text(
                            _menu[i],
                            style: GoogleFonts.poppins(fontSize: 14),
                          )
                          : null,
                  selected: active,
                  onTap: () => setState(() => _selectedIndex = i),
                );
              },
            ),
          ),
          if (isDesktop)
            ListTile(
              leading: const Icon(Icons.logout_outlined),
              title: Text('Sign out', style: GoogleFonts.poppins()),
              onTap: () async {
                await authService.clearSession();
                if (context.mounted) context.go('/login');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUsersPanel() {
    final user = authService.currentUser;
    if (user == null) {
      return Center(
        child: Text('No user session found. Login as admin to manage users.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  CircleAvatar(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Role',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 6),
                      _loading
                          ? const SizedBox(
                            width: 100,
                            child: LinearProgressIndicator(),
                          )
                          : DropdownButton<String>(
                            value: user.roleid ?? '1',
                            items:
                                _roles
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r['id'],
                                        child: Text(r['name']!),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) _changeRole(user, val);
                            },
                          ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1024;
    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(
                title: Text('Admin Panel', style: GoogleFonts.poppins()),
              ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(false)),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(true),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child:
                  _selectedIndex == 1
                      ? _buildUsersPanel()
                      : Center(
                        child: Text(
                          _menu[_selectedIndex],
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
