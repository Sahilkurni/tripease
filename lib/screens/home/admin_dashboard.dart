import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../hotel_partner/add_edit_hotel_screen.dart';
import '../hotel_partner/manage_rooms_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF2563EB);
  static const Color _surface = Colors.white;
  static const Color _bg = Color(0xFFF6F8FB);
  static const Color _ink = Color(0xFF172033);
  static const Color _muted = Color(0xFF64748B);

  final Dio _dio = Dio();
  late final AnimationController _fadeController;

  int _selectedIndex = 0;
  int _partnerid = 0;
  int _userid = 0;
  bool _roleLoading = false;
  bool _hotelsLoading = true;
  bool _bookingsLoading = true;
  String? _hotelsError;

  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _bookings = [];

  final List<String> _menu = const [
    'Overview',
    'Users',
    'Hotels',
    'Bookings',
    'Settings',
  ];

  final List<Map<String, String>> _roles = const [
    {'id': '1', 'name': 'ADMIN'},
    {'id': '2', 'name': 'CUSTOMER'},
    {'id': '3', 'name': 'HOTEL_OWNER'},
    {'id': '4', 'name': 'TRAVEL_AGENT'},
  ];

  String get _apiBase {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return 'http://10.0.2.2/tripease_api';
      }
    } catch (_) {}
    return 'http://localhost/tripease_api';
  }

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _bootstrap();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final user = authService.currentUser;
    _partnerid = prefs.getInt('partnerid') ?? 0;
    _userid = prefs.getInt('userid') ?? _asInt(user?.userid);
    await _refreshDashboardData();
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _text(
    Map<String, dynamic> data,
    List<String> keys, [
    String fallback = '',
  ]) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return fallback;
  }

  List<Map<String, dynamic>> _listFromApi(dynamic data) {
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data is Map && data['data'] is List) {
      return List<Map<String, dynamic>>.from(data['data'] as List);
    }
    return [];
  }

  Future<void> _refreshDashboardData() async {
    setState(() {
      _hotelsLoading = true;
      _bookingsLoading = true;
      _hotelsError = null;
    });
    await Future.wait([_loadHotels(), _loadBookings()]);
    if (mounted) _fadeController.forward(from: 0);
  }

  Future<void> _loadHotels() async {
    try {
      final res = await _dio.get('$_apiBase/get_hotels.php');
      final hotels = _listFromApi(res.data);
      if (!mounted) return;
      setState(() {
        _hotels = hotels;
        _hotelsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hotelsLoading = false;
        _hotelsError =
            'Failed to load hotels. Please check the API and try again.';
      });
    }
  }

  Future<void> _loadBookings() async {
    try {
      final res = await _dio.get('$_apiBase/get_bookings.php');
      final bookings = _listFromApi(res.data);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _bookingsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _bookingsLoading = false);
    }
  }

  Future<void> _changeRole(UserModel user, String roleId) async {
    setState(() => _roleLoading = true);
    final res = await authService.updateRole(user.userid, roleId);
    if (!mounted) return;
    setState(() => _roleLoading = false);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Role updated: ${res['rolename']}')),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: ${res['message'] ?? 'error'}')),
      );
    }
  }

  bool _isHotelActive(Map<String, dynamic> hotel) {
    final approval = _text(hotel, ['approvalstatus', 'status']).toUpperCase();
    if (approval == 'PENDING') return false;
    return _asInt(hotel['isactive'], 1) == 1;
  }

  Future<void> _navigateToAddHotel() async {
    if (_partnerid == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select or login as an approved hotel partner before adding a hotel.',
          ),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddEditHotelScreen(
              isEdit: false,
              partnerid: _partnerid,
              userid: _userid,
            ),
      ),
    );
    if (result == true) _refreshDashboardData();
  }

  Future<void> _editHotel(Map<String, dynamic> hotel) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddEditHotelScreen(
              isEdit: true,
              hotelData: hotel,
              partnerid: _asInt(hotel['partnerid'], _partnerid),
              userid: _userid,
            ),
      ),
    );
    if (result == true) _refreshDashboardData();
  }

  void _manageRooms(Map<String, dynamic> hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ManageRoomsScreen(
              hotelid: _asInt(hotel['hotelid']),
              hotelname: _text(hotel, ['hotelname', 'name'], 'Hotel'),
              partnerid: _asInt(hotel['partnerid'], _partnerid),
              userid: _userid,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Scaffold(
      backgroundColor: _bg,
      appBar:
          isDesktop
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: _ink),
                title: Text(
                  'Admin Panel',
                  style: GoogleFonts.poppins(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(false)),
      floatingActionButton:
          (_selectedIndex == 2 && !isDesktop)
              ? FloatingActionButton.extended(
                onPressed: _navigateToAddHotel,
                backgroundColor: _primary,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'Add Hotel',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
              : null,
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(true),
          Expanded(
            child: Column(
              children: [
                _buildHeader(width),
                Expanded(child: _buildSelectedPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPanel() {
    switch (_selectedIndex) {
      case 1:
        return _buildUsersPanel();
      case 2:
        return _buildHotelsPanel();
      case 3:
        return _buildBookingsPanel();
      case 4:
        return Center(
          child: Text('Settings', style: GoogleFonts.poppins(fontSize: 20)),
        );
      default:
        return _buildOverviewPanel();
    }
  }

  Widget _buildSidebar(bool isDesktop) {
    return Container(
      width: isDesktop ? 260 : null,
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            isDesktop
                ? Border(right: BorderSide(color: Colors.grey.shade200))
                : null,
      ),
      child: Column(
        children: [
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: _primary.withAlpha(22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.travel_explore, color: _primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TripEase',
                    style: GoogleFonts.poppins(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _menu.length,
              itemBuilder: (_, i) {
                final active = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      i == 0
                          ? Icons.grid_view_rounded
                          : i == 1
                          ? Icons.group_rounded
                          : i == 2
                          ? Icons.domain_rounded
                          : i == 3
                          ? Icons.confirmation_number_rounded
                          : Icons.settings_rounded,
                      color: active ? _primary : _muted,
                    ),
                    title:
                        isDesktop
                            ? Text(
                              _menu[i],
                              style: GoogleFonts.poppins(
                                color: active ? _primary : _muted,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                              ),
                            )
                            : null,
                    selected: active,
                    selectedTileColor: _primary.withAlpha(18),
                    onTap: () {
                      setState(() => _selectedIndex = i);
                      if (!isDesktop) Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title:
                  isDesktop
                      ? Text(
                        'Sign out',
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                      : null,
              onTap: () async {
                await authService.clearSession();
                if (context.mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double width) {
    final user = authService.currentUser;
    final compact = width < 700;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 40,
        vertical: compact ? 18 : 26,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin dashboard',
                  style: GoogleFonts.poppins(
                    color: _ink,
                    fontSize: compact ? 23 : 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Monitor hotels, bookings, partners, and operational health.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(color: _muted, fontSize: 14),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 20),
            CircleAvatar(
              radius: 22,
              backgroundColor: _primary,
              child: Text(
                (user?.name.isNotEmpty ?? false)
                    ? user!.name[0].toUpperCase()
                    : 'A',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewPanel() {
    final width = MediaQuery.of(context).size.width;
    final activeHotels = _hotels.where(_isHotelActive).length;
    final stats = [
      _StatData(
        'Total Hotels',
        '${_hotels.length}',
        Icons.domain_rounded,
        const Color(0xFF2563EB),
      ),
      _StatData(
        'Active Hotels',
        '$activeHotels',
        Icons.verified_rounded,
        const Color(0xFF059669),
      ),
      _StatData(
        'Pending Review',
        '${_hotels.length - activeHotels}',
        Icons.pending_actions_rounded,
        const Color(0xFFF59E0B),
      ),
      _StatData(
        'Bookings',
        '${_bookings.length}',
        Icons.confirmation_number_rounded,
        const Color(0xFFDB2777),
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(width >= 900 ? 40 : 20),
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (_, constraints) {
                final cols =
                    constraints.maxWidth >= 1100
                        ? 4
                        : constraints.maxWidth >= 650
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                    childAspectRatio: cols == 1 ? 3.1 : 2.25,
                  ),
                  itemBuilder:
                      (_, i) =>
                          (_hotelsLoading || _bookingsLoading)
                              ? const _ShimmerCard()
                              : _StatCard(data: stats[i]),
                );
              },
            ),
            const SizedBox(height: 28),
            _buildHotelsSection(inOverview: true),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelsPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width >= 900 ? 40 : 20,
      ),
      child: FadeTransition(
        opacity: _fadeController,
        child: _buildHotelsSection(inOverview: false),
      ),
    );
  }

  Widget _buildHotelsSection({required bool inOverview}) {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Hotels',
                    style: GoogleFonts.poppins(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hotels table records with city, rating, status, and room controls.',
                    style: GoogleFonts.poppins(color: _muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (width >= 700) _AddHotelButton(onPressed: _navigateToAddHotel),
          ],
        ),
        const SizedBox(height: 20),
        if (_hotelsLoading)
          _buildHotelSkeletons(width)
        else if (_hotelsError != null)
          _buildHotelErrorState()
        else if (_hotels.isEmpty)
          _buildHotelEmptyState()
        else
          _buildHotelGrid(width, inOverview: inOverview),
      ],
    );
  }

  Widget _buildHotelSkeletons(double width) {
    final cols =
        width >= 1280 ? 4 : (width >= 900 ? 3 : (width >= 600 ? 2 : 1));
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: cols == 1 ? 1.55 : 0.9,
      ),
      itemBuilder: (_, __) => const _ShimmerCard(isHotel: true),
    );
  }

  Widget _buildHotelErrorState() {
    return _StateShell(
      icon: Icons.cloud_off_rounded,
      iconColor: Colors.redAccent,
      title: _hotelsError!,
      subtitle:
          'Your dashboard data is still protected; this only needs a reload.',
      action: ElevatedButton.icon(
        onPressed: _refreshDashboardData,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: Text(
          'Retry',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(backgroundColor: _primary),
      ),
    );
  }

  Widget _buildHotelEmptyState() {
    return _StateShell(
      icon: Icons.apartment_rounded,
      iconColor: _primary,
      title: 'No hotels added yet',
      subtitle: 'Start by adding your first hotel',
      action: _AddHotelButton(onPressed: _navigateToAddHotel),
    );
  }

  Widget _buildHotelGrid(double width, {required bool inOverview}) {
    final hotels =
        inOverview && _hotels.length > 8 ? _hotels.take(8).toList() : _hotels;

    if (width < 600) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: hotels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder:
            (_, i) => _AnimatedEntry(
              index: i,
              child: _HotelCard(
                hotel: hotels[i],
                isActive: _isHotelActive(hotels[i]),
                textOf: _text,
                intOf: _asInt,
                onEdit: () => _editHotel(hotels[i]),
                onManageRooms: () => _manageRooms(hotels[i]),
              ),
            ),
      );
    }

    final cols = width >= 1280 ? 4 : (width >= 900 ? 3 : 2);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hotels.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: cols >= 3 ? 0.88 : 1.0,
      ),
      itemBuilder:
          (_, i) => _AnimatedEntry(
            index: i,
            child: _HotelCard(
              hotel: hotels[i],
              isActive: _isHotelActive(hotels[i]),
              textOf: _text,
              intOf: _asInt,
              onEdit: () => _editHotel(hotels[i]),
              onManageRooms: () => _manageRooms(hotels[i]),
            ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Users',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _primary,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.email,
                          style: GoogleFonts.poppins(color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _roleLoading
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsPanel() {
    if (_bookingsLoading)
      return const Center(child: CircularProgressIndicator());
    if (_bookings.isEmpty) {
      return Center(
        child: Text('No bookings available', style: GoogleFonts.poppins()),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _bookings.length,
      itemBuilder: (_, i) {
        final booking = _bookings[i];
        return Card(
          elevation: 0,
          color: Colors.white,
          child: ListTile(
            title: Text(_text(booking, ['bookingno', 'service'], 'Booking')),
            subtitle: Text(
              'Type: ${_text(booking, ['bookingtype'], 'HOTEL')} • ${_text(booking, ['bookingdate', 'bookdate'])}',
            ),
            trailing: Text(
              '₹${_text(booking, ['finalamount', 'amount'], '0')}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatData(this.label, this.value, this.icon, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: data.color.withAlpha(20),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: _AdminDashboardState._muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  data.value,
                  style: GoogleFonts.poppins(
                    color: _AdminDashboardState._ink,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddHotelButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AddHotelButton({required this.onPressed});

  @override
  State<_AddHotelButton> createState() => _AddHotelButtonState();
}

class _AddHotelButtonState extends State<_AddHotelButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 0.97).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapCancel: _controller.reverse,
      onTapUp: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text(
            'Add Hotel',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _AdminDashboardState._primary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}

class _StateShell extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget action;

  const _StateShell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 64),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: iconColor),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _AdminDashboardState._ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: _AdminDashboardState._muted),
          ),
          const SizedBox(height: 28),
          action,
        ],
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedEntry({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + (index.clamp(0, 8) * 45)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _HotelCard extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final bool isActive;
  final String Function(Map<String, dynamic>, List<String>, [String]) textOf;
  final int Function(dynamic, [int]) intOf;
  final VoidCallback onEdit;
  final VoidCallback onManageRooms;

  const _HotelCard({
    required this.hotel,
    required this.isActive,
    required this.textOf,
    required this.intOf,
    required this.onEdit,
    required this.onManageRooms,
  });

  @override
  State<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<_HotelCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 0.985).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
    final hotelId = widget.intOf(hotel['hotelid']);
    final name = widget.textOf(hotel, ['hotelname', 'name'], 'Untitled Hotel');
    final city = widget.textOf(hotel, [
      'cityname',
      'city',
      'city_name',
    ], 'City ID: ${widget.textOf(hotel, ['cityid'], 'Unknown')}');
    final description = widget.textOf(hotel, [
      'description',
    ], 'Manage rooms, pricing, availability, and guest experience.');
    final rating = widget.intOf(hotel['star_rating'], 0).clamp(0, 5);
    final badgeColor =
        widget.isActive ? const Color(0xFF059669) : const Color(0xFFF59E0B);
    final gradients = const [
      [Color(0xFF2563EB), Color(0xFF14B8A6)],
      [Color(0xFFDB2777), Color(0xFFF59E0B)],
      [Color(0xFF7C3AED), Color(0xFF2563EB)],
      [Color(0xFF0F766E), Color(0xFF84CC16)],
    ];
    final gradient = gradients[hotelId.abs() % gradients.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapCancel: _controller.reverse,
        onTapUp: (_) => _controller.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    _hovered
                        ? _AdminDashboardState._primary.withAlpha(70)
                        : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(_hovered ? 22 : 8),
                  blurRadius: _hovered ? 26 : 14,
                  offset: Offset(0, _hovered ? 12 : 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 62,
                          color: Colors.white30,
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: _StatusBadge(
                          label: widget.isActive ? 'Active' : 'Pending',
                          color: badgeColor,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white70,
                                  size: 15,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    city,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withAlpha(225),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < rating
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 18,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: _AdminDashboardState._muted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _AdminDashboardState._ink,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onManageRooms,
                                icon: const Icon(
                                  Icons.meeting_room_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                label: Text(
                                  'Rooms',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      _AdminDashboardState._primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  final bool isHotel;

  const _ShimmerCard({this.isHotel = false});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _color = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder:
          (_, __) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child:
                widget.isHotel
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _color.value,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _SkeletonLine(width: 160, color: _color.value),
                        const SizedBox(height: 10),
                        _SkeletonLine(width: 110, color: _color.value),
                        const Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: _SkeletonLine(
                                height: 42,
                                color: _color.value,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SkeletonLine(
                                height: 42,
                                color: _color.value,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SkeletonLine(
                          width: 54,
                          height: 46,
                          color: _color.value,
                        ),
                        const SizedBox(height: 14),
                        _SkeletonLine(width: 125, color: _color.value),
                        const SizedBox(height: 10),
                        _SkeletonLine(
                          width: 80,
                          height: 24,
                          color: _color.value,
                        ),
                      ],
                    ),
          ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final Color? color;

  const _SkeletonLine({this.width, this.height = 14, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
