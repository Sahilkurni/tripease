import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/hotel_partner_service.dart';
import 'package:go_router/go_router.dart';
import '../hotel_partner/add_edit_hotel_screen.dart';
import '../hotel_partner/manage_rooms_screen.dart';

class HotelOwnerDashboard extends StatefulWidget {
  const HotelOwnerDashboard({super.key});

  @override
  State<HotelOwnerDashboard> createState() => _HotelOwnerDashboardState();
}

class _HotelOwnerDashboardState extends State<HotelOwnerDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isError = false;

  int _partnerid = 0;
  int _userid = 0;
  String _fullname = '';

  Map<String, dynamic> _stats = {
    'total_hotels': 0,
    'active_bookings': 0,
    'total_revenue': 0.0,
    'net_earnings': 0.0,
    'total_rooms': 0,
    'recent_bookings': 0,
  };
  List<Map<String, dynamic>> _hotels = [];
  List<dynamic> _inventory = [];
  Map<String, dynamic> _earnings = {};
  String _earningsPeriod = 'month';

  final List<String> _menu = [
    'Dashboard',
    'My Hotels',
    'Room Inventory',
    'Earnings & Taxes',
  ];

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initSession();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initSession() async {
    final prefs = await SharedPreferences.getInstance();
    _userid = prefs.getInt('userid') ?? 0;
    _partnerid = prefs.getInt('partnerid') ?? 1;
    _fullname = prefs.getString('fullname') ?? 'Partner';
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    try {
      if (_selectedIndex == 0) {
        _stats = await HotelPartnerService.getDashboardStats(_partnerid);
      } else if (_selectedIndex == 1) {
        _hotels = await HotelPartnerService.getHotels(_partnerid);
      } else if (_selectedIndex == 2) {
        _inventory = await HotelPartnerService.getRoomInventory(_partnerid);
      } else if (_selectedIndex == 3) {
        _earnings = await HotelPartnerService.getEarnings(
          _partnerid,
          _earningsPeriod,
        );
      }
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
          _isError = true;
        });
    }
  }

  String _formatAmount(dynamic val) {
    final d = (val is int ? val.toDouble() : (val as double?) ?? 0.0);
    if (d >= 100000) return '${(d / 100000).toStringAsFixed(1)}L';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)}k';
    return d.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar:
          isDesktop
              ? null
              : AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black87),
                title: Text(
                  'Partner Panel',
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(false)),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(true),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildHeader(),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (_isError) return _buildErrorState();
                      switch (_selectedIndex) {
                        case 0:
                          return _buildOverviewTab();
                        case 1:
                          return _buildHotelsTab();
                        case 2:
                          return _buildRoomsTab();
                        case 3:
                          return _buildEarningsTab();
                        default:
                          return const Center(child: Text('Invalid Tab'));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          (_selectedIndex == 1 && !isDesktop)
              ? FloatingActionButton.extended(
                onPressed: _navigateToAddHotel,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Add Hotel',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: const Color(0xFF2563EB),
              )
              : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Failed to load data',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchDashboardData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              backgroundColor: const Color(0xFF2563EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $_fullname',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your hotels and bookings',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    _fullname.isNotEmpty ? _fullname[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.all(32.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business_center,
                      color: Color(0xFF2563EB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TripEase',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _menu.length,
              itemBuilder: (context, i) {
                final active = _selectedIndex == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      i == 0
                          ? Icons.grid_view_rounded
                          : i == 1
                          ? Icons.domain_rounded
                          : i == 2
                          ? Icons.meeting_room_rounded
                          : Icons.account_balance_wallet_rounded,
                      color:
                          active
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                    ),
                    title: Text(
                      _menu[i],
                      style: GoogleFonts.poppins(
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                        color:
                            active
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B),
                      ),
                    ),
                    selected: active,
                    selectedTileColor: const Color(0xFF2563EB).withAlpha(20),
                    onTap: () {
                      setState(() {
                        _selectedIndex = i;
                        _fetchDashboardData();
                      });
                      if (!isDesktop)
                        Navigator.pop(context); // close drawer on mobile
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: Text(
                'Logout',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
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

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width > 800 ? 40 : 24,
      ),
      child: FadeTransition(
        opacity: _fadeController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (MediaQuery.of(context).size.width <= 800) ...[
              Text(
                'Welcome back, $_fullname',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
            ],
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount =
                    constraints.maxWidth > 1000
                        ? 4
                        : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: 2.2,
                  children: [
                    _isLoading
                        ? const _ShimmerCard()
                        : _PremiumStatCard(
                          label: 'Total Hotels',
                          value: '${_stats['total_hotels']}',
                          icon: Icons.domain_rounded,
                          colors: const [
                            Color(0xFFF43F5E),
                            Color(0xFFE11D48),
                          ], // Rose
                        ),
                    _isLoading
                        ? const _ShimmerCard()
                        : _PremiumStatCard(
                          label: 'Active Bookings',
                          value: '${_stats['active_bookings']}',
                          icon: Icons.confirmation_number_rounded,
                          colors: const [
                            Color(0xFF3B82F6),
                            Color(0xFF2563EB),
                          ], // Primary Blue
                        ),
                    _isLoading
                        ? const _ShimmerCard()
                        : _PremiumStatCard(
                          label: 'Total Revenue',
                          value: '₹${_formatAmount(_stats['total_revenue'])}',
                          icon: Icons.currency_rupee_rounded,
                          colors: const [
                            Color(0xFF2DD4BF),
                            Color(0xFF14B8A6),
                          ], // Secondary Teal
                        ),
                    _isLoading
                        ? const _ShimmerCard()
                        : _PremiumStatCard(
                          label: 'Net Earnings',
                          value: '₹${_formatAmount(_stats['net_earnings'])}',
                          icon: Icons.account_balance_wallet_rounded,
                          colors: const [
                            Color(0xFFA78BFA),
                            Color(0xFF8B5CF6),
                          ], // Accent Purple
                        ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelsTab() {
    final w = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(w > 800 ? 40 : 24).copyWith(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Properties',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (w > 800)
                  ElevatedButton.icon(
                    onPressed: _navigateToAddHotel,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      'Add Hotel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFF2563EB).withAlpha(100),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? _buildHotelSkeletons(w)
                    : _hotels.isEmpty
                    ? _buildEmptyState()
                    : _buildHotelGrid(w),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelSkeletons(double w) {
    int crossAxisCount = w > 1200 ? 4 : (w > 900 ? 3 : (w > 600 ? 2 : 1));
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: w > 800 ? 40 : 24,
      ).copyWith(bottom: 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _ShimmerCard(isHotel: true),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.domain_add_outlined,
              size: 64,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No hotels added yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first hotel to the platform',
            style: GoogleFonts.poppins(color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _navigateToAddHotel,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Add Hotel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelGrid(double w) {
    if (w <= 600) {
      // Mobile full width list
      return ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ).copyWith(bottom: 40),
        itemCount: _hotels.length,
        itemBuilder:
            (ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _PremiumHotelCard(
                hotel: _hotels[i],
                onEdit: () => _editHotel(_hotels[i]),
                onManageRooms: () => _manageRooms(_hotels[i]),
              ),
            ),
      );
    }

    // Tablet/Desktop Grid
    int crossAxisCount = w > 1200 ? 4 : (w > 900 ? 3 : 2);
    return GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: w > 800 ? 40 : 24,
      ).copyWith(bottom: 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.85,
      ),
      itemCount: _hotels.length,
      itemBuilder:
          (ctx, i) => _PremiumHotelCard(
            hotel: _hotels[i],
            onEdit: () => _editHotel(_hotels[i]),
            onManageRooms: () => _manageRooms(_hotels[i]),
          ),
    );
  }

  void _navigateToAddHotel() async {
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
    if (result == true) _fetchDashboardData();
  }

  void _editHotel(Map<String, dynamic> h) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddEditHotelScreen(
              isEdit: true,
              hotelData: {'hotelid': h['hotelid'], 'hotelname': h['hotelname']},
              partnerid: _partnerid,
              userid: _userid,
            ),
      ),
    );
    if (result == true) _fetchDashboardData();
  }

  void _manageRooms(Map<String, dynamic> h) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ManageRoomsScreen(
              hotelid: h['hotelid'],
              hotelname: h['hotelname'],
              partnerid: _partnerid,
              userid: _userid,
            ),
      ),
    );
  }

  // Inventory tab with premium design
  Widget _buildRoomsTab() {
    final w = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _fadeController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(w > 800 ? 40 : 24).copyWith(bottom: 16),
            child: Text(
              'Room Inventory',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _inventory.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No inventory available',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: w > 800 ? 40 : 24,
                      ).copyWith(bottom: 40),
                      itemCount: _inventory.length,
                      itemBuilder: (context, i) {
                        final item = _inventory[i];
                        return _PremiumInventoryCard(inventory: item);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() =>
      const Center(child: Text('Earnings Tab Pending Next Phase Design'));
}

class _PremiumStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> colors;

  const _PremiumStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, size: 80, color: Colors.white.withAlpha(40)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white.withAlpha(220),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumHotelCard extends StatefulWidget {
  final Map<String, dynamic> hotel;
  final VoidCallback onEdit;
  final VoidCallback onManageRooms;

  const _PremiumHotelCard({
    required this.hotel,
    required this.onEdit,
    required this.onManageRooms,
  });

  @override
  State<_PremiumHotelCard> createState() => _PremiumHotelCardState();
}

class _PremiumHotelCardState extends State<_PremiumHotelCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Generate a placeholder gradient based on hotel id to look premium if no image
    final colors = [
      [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
      [const Color(0xFF14B8A6), const Color(0xFF3B82F6)],
      [const Color(0xFFF43F5E), const Color(0xFFF97316)],
    ];
    final hid = widget.hotel['hotelid'] as int? ?? 0;
    final gradient = colors[hid % colors.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _animCtrl.forward(),
        onTapUp: (_) => _animCtrl.reverse(),
        onTapCancel: () => _animCtrl.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(_isHovered ? 25 : 10),
                  blurRadius: _isHovered ? 25 : 10,
                  offset: Offset(0, _isHovered ? 12 : 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Placeholder image gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(
                            Icons.domain_rounded,
                            size: 64,
                            color: Colors.white30,
                          ),
                        ),
                        // Bottom shadow overlay
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(180),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.6, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Status Badge
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(230),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Active',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Text Overlay
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.hotel['hotelname'],
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.5',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '• City ID: ${widget.hotel['cityid'] ?? "Unknown"}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
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
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Manage your rooms, rates, and availability for this premium property.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: Text(
                                  'Edit',
                                  style: GoogleFonts.poppins(),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onManageRooms,
                                icon: const Icon(
                                  Icons.meeting_room_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Rooms',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: Size.zero,
                                  backgroundColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
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

class _ShimmerCard extends StatefulWidget {
  final bool isHotel;
  const _ShimmerCard({this.isHotel = false});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _colorAnim = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnim,
      builder:
          (context, child) => Container(
            decoration: BoxDecoration(
              color: _colorAnim.value,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
    );
  }
}

class _PremiumInventoryCard extends StatelessWidget {
  final Map<String, dynamic> inventory;

  const _PremiumInventoryCard({required this.inventory});

  @override
  Widget build(BuildContext context) {
    final String hotelName = inventory['hotelname'] ?? 'Unknown Hotel';
    final List<dynamic> rooms = inventory['rooms'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.domain_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hotelName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${rooms.length} Room Types',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No rooms added for this hotel yet.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final room = rooms[index];
                final String roomName = room['roomname'] ?? 'Unnamed Room';
                final String typeName = room['typename'] ?? 'Standard';
                final int totalRooms = int.tryParse(room['totalrooms']?.toString() ?? '0') ?? 0;
                final int availableCount = int.tryParse(room['available_count']?.toString() ?? '0') ?? 0;
                final int bookedCount = int.tryParse(room['booked_count']?.toString() ?? '0') ?? 0;
                final double price = double.tryParse(room['price']?.toString() ?? '0') ?? 0.0;
                
                final double occupancy = totalRooms > 0 ? (bookedCount / totalRooms) : 0;
                final Color statusColor = occupancy >= 0.9 ? Colors.red : (occupancy >= 0.7 ? Colors.orange : Colors.green);

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    roomName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    typeName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${price.toStringAsFixed(0)} / night',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInventoryStat(
                                'Total',
                                totalRooms.toString(),
                                Icons.meeting_room_rounded,
                                Colors.blue,
                              ),
                            ),
                            Expanded(
                              child: _buildInventoryStat(
                                'Booked',
                                bookedCount.toString(),
                                Icons.bookmark_added_rounded,
                                statusColor,
                              ),
                            ),
                            Expanded(
                              child: _buildInventoryStat(
                                'Available',
                                availableCount.toString(),
                                Icons.check_circle_outline_rounded,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInventoryStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color.withAlpha(150)),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
