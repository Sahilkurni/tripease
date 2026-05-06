import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/role_constants.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';

import 'admin_users_screen.dart';
import 'admin_partners_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_packages_screen.dart';
import 'admin_buses_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_payments_screen.dart';
import 'admin_coupons_screen.dart';
import 'admin_support_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const Color _primary = Color(0xFF2563EB);
  static const Color _accent = Color(0xFF8B5CF6);
  static const Color _bg = Color(0xFFF8FAFC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _chartData;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_rounded},
    {'title': 'Users', 'icon': Icons.people_rounded},
    {'title': 'Partners', 'icon': Icons.handshake_rounded},
    {'title': 'Hotels', 'icon': Icons.apartment_rounded},
    {'title': 'Packages', 'icon': Icons.card_travel_rounded},
    {'title': 'Buses', 'icon': Icons.directions_bus_rounded},
    {'title': 'Bookings', 'icon': Icons.confirmation_number_rounded},
    {'title': 'Payments', 'icon': Icons.payment_rounded},
    {'title': 'Coupons', 'icon': Icons.local_offer_rounded},
    {'title': 'Support', 'icon': Icons.support_agent_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _checkSessionAndLoad();
  }

  Future<void> _checkSessionAndLoad() async {
    final user = authService.currentUser;
    if (user == null ||
        int.tryParse(user.roleid.toString()) != RoleConstants.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return;
    }
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final resStats = await adminService.getDashboardStats();
    final resCharts = await adminService.getDashboardCharts();

    if (!mounted) return;

    if (resStats['status'] == 'success' && resCharts['status'] == 'success') {
      setState(() {
        _dashboardData = resStats['data'];
        _chartData = resCharts['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error =
            resStats['message'] ??
            resCharts['message'] ??
            'Failed to load data';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await authService.clearSession();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

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
          drawer:
              isDesktop ? null : Drawer(child: _buildSidebar(isDesktop: false)),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop) _buildSidebar(isDesktop: true),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: _buildContentArea(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool isDesktop}) {
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
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded, color: _primary),
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, i) {
                final item = _menuItems[i];
                final isActive = _selectedIndex == i;
                return _SidebarItem(
                  title: item['title'],
                  icon: item['icon'],
                  isActive: isActive,
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    if (!isDesktop) Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _SidebarItem(
              title: 'Sign Out',
              icon: Icons.logout_rounded,
              isActive: false,
              isDestructive: true,
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    switch (_selectedIndex) {
      case 0:
        if (_isLoading) return _buildShimmerLoading();
        if (_error != null) return _buildErrorState();
        return _buildDashboardSuccess();
      case 1:
        return const AdminUsersScreen();
      case 2:
        return const AdminPartnersScreen();
      case 3:
        return const AdminHotelsScreen();
      case 4:
        return const AdminPackagesScreen();
      case 5:
        return const AdminBusesScreen();
      case 6:
        return const AdminBookingsScreen();
      case 7:
        return const AdminPaymentsScreen();
      case 8:
        return const AdminCouponsScreen();
      case 9:
        return const AdminSupportScreen();
      default:
        return Container();
    }
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 40, width: 250, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          Container(height: 20, width: 350, color: Colors.grey.shade200),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 350,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 2.2,
            ),
            itemCount: 4,
            itemBuilder:
                (_, __) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardSuccess() {
    final stats = _dashboardData ?? {};
    final charts = _chartData ?? {};

    final users = stats['total_users']?.toString() ?? '0';
    final partners = stats['total_partners']?.toString() ?? '0';
    final bookings = stats['total_bookings']?.toString() ?? '0';

    final revenueRaw =
        double.tryParse(stats['total_revenue']?.toString() ?? '0') ?? 0;
    final formatCurrency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final revenueStr = formatCurrency.format(revenueRaw);

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Overview',
            style: GoogleFonts.poppins(
              color: _ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Monitor platform health, bookings, and revenue.',
            style: GoogleFonts.poppins(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 32),

          if (isMobile)
            Column(
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: users,
                  icon: Icons.group_rounded,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Total Partners',
                  value: partners,
                  icon: Icons.handshake_rounded,
                  gradientColors: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Total Bookings',
                  value: bookings,
                  icon: Icons.airplane_ticket_rounded,
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                const SizedBox(height: 16),
                _StatCard(
                  title: 'Total Revenue',
                  value: revenueStr,
                  icon: Icons.attach_money_rounded,
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ],
            )
          else
            GridView.count(
              crossAxisCount: screenWidth >= 1200 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: screenWidth >= 1400 ? 2.5 : 2.0,
              children: [
                _StatCard(
                  title: 'Total Users',
                  value: users,
                  icon: Icons.group_rounded,
                  gradientColors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                _StatCard(
                  title: 'Total Partners',
                  value: partners,
                  icon: Icons.handshake_rounded,
                  gradientColors: const [Color(0xFF14B8A6), Color(0xFF0D9488)],
                ),
                _StatCard(
                  title: 'Total Bookings',
                  value: bookings,
                  icon: Icons.airplane_ticket_rounded,
                  gradientColors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                _StatCard(
                  title: 'Total Revenue',
                  value: revenueStr,
                  icon: Icons.attach_money_rounded,
                  gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
              ],
            ),

          const SizedBox(height: 32),
          if (isMobile || screenWidth < 1100) ...[
            _buildRevenueChart(charts['monthly_revenue'] as List<dynamic>?),
            const SizedBox(height: 24),
            _buildBookingTrends(charts['booking_trends'] as List<dynamic>?),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRevenueChart(
                    charts['monthly_revenue'] as List<dynamic>?,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: _buildBookingTrends(
                    charts['booking_trends'] as List<dynamic>?,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List<dynamic>? monthlyRevenue) {
    if (monthlyRevenue == null || monthlyRevenue.isEmpty) {
      return _ChartContainer(
        title: 'Monthly Revenue',
        child: const Center(child: Text('No revenue data available')),
      );
    }

    final spots = <FlSpot>[];
    double maxRev = 0;

    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = 0; i < monthlyRevenue.length; i++) {
      final rev = double.tryParse(monthlyRevenue[i]['revenue'].toString()) ?? 0;
      if (rev > maxRev) maxRev = rev;
      spots.add(FlSpot(i.toDouble(), rev));
    }

    // fallback for empty chart drawing correctly
    if (spots.isEmpty) {
      spots.add(const FlSpot(0, 0));
    }

    return _ChartContainer(
      title: 'Monthly Revenue',
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxRev > 0 ? maxRev / 4 : 100,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 44),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < monthlyRevenue.length) {
                    final mIdx =
                        int.tryParse(
                          monthlyRevenue[index]['month'].toString(),
                        ) ??
                        1;
                    final mName = monthNames[(mIdx - 1).clamp(0, 11)];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        mName,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: _primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTrends(List<dynamic>? bookingTrends) {
    if (bookingTrends == null || bookingTrends.isEmpty) {
      return _ChartContainer(
        title: 'Booking Trends',
        child: const Center(child: Text('No booking trends data')),
      );
    }

    final barGroups = <BarChartGroupData>[];
    double maxBookings = 0;
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = 0; i < bookingTrends.length; i++) {
      final count =
          double.tryParse(bookingTrends[i]['bookings'].toString()) ?? 0;
      if (count > maxBookings) maxBookings = count;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count,
              color: _accent,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return _ChartContainer(
      title: 'Booking Trends',
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxBookings == 0 ? 10 : maxBookings * 1.2,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < bookingTrends.length) {
                    final mIdx =
                        int.tryParse(
                          bookingTrends[index]['month'].toString(),
                        ) ??
                        1;
                    final mName = monthNames[(mIdx - 1).clamp(0, 11)];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        mName,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}

class _ChartContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradientColors;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(
              icon,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isDestructive
            ? Colors.redAccent
            : widget.isActive
            ? const Color(0xFF2563EB)
            : const Color(0xFF64748B);

    final bgColor =
        widget.isActive
            ? const Color(0xFF2563EB).withValues(alpha: 0.1)
            : _isHovered
            ? Colors.grey.shade100
            : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: color, size: 22),
                const SizedBox(width: 14),
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight:
                        widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
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
