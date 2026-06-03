import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/package_service.dart';
import '../../services/bus_service.dart';
import '../../services/flight_service.dart';
import '../../models/package_model.dart';
import '../../models/bus_model.dart';
import '../../models/flight_model.dart';
import 'package:go_router/go_router.dart';
import '../../services/agent_service.dart';
import '../agent/add_edit_package_screen.dart';
import '../agent/agent_add_flight_screen.dart';
import '../../widgets/base64_image.dart';
import '../profile/edit_profile_screen.dart';
import '../admin/coupon_management_screen.dart';
import '../admin/offer_management_screen.dart';
import '../../widgets/earnings_tab.dart';
import '../../main.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard>
    with SingleTickerProviderStateMixin {
  // Theme aware color getters
  Color get _primary => Theme.of(context).colorScheme.primary;
  Color get _ink => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B);
  Color get _muted => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF64748B);
  Color get _surface => Theme.of(context).cardColor;
  int _selectedIndex = 0;
  final List<String> _menu = [
    'Tour Packages',
    'Bus Inventory',
    'Flight Inventory',
    'Earnings & Taxes',
    'Coupons',
    'Offers',
  ];
  Map<String, dynamic> _earnings = {};
  String _earningsPeriod = 'month';
  bool _isLoading = true;
  String? _errorMessage;
  int _partnerid = 0;
  int _userid = 0;
  List<PackageModel> _packages = [];
  List<BusModel> _buses = [];
  List<FlightModel> _flights = [];
  String _fullname = '';
  String _email = '';
  String _photo = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_session');
      Map<String, dynamic> user = {};
      if (userJson != null) {
        user = jsonDecode(userJson) as Map<String, dynamic>;
      }
      _userid =
          prefs.getInt('userid') ??
          int.tryParse(user['userid']?.toString() ?? '') ??
          0;
      _partnerid =
          prefs.getInt('partnerid') ??
          int.tryParse(user['partnerid']?.toString() ?? '') ??
          _userid;

      if (_partnerid == 0) {
        _partnerid = 1; 
      }

      _fullname = prefs.getString('fullname') ?? user['fullname'] ?? '';
      _email = prefs.getString('email') ?? user['email'] ?? '';
      _photo = prefs.getString('photo') ?? user['photo'] ?? '';

      final packages = await packageService.getAgentPackages(_partnerid);
      final buses = await busService.getAgentBuses(_partnerid);
      final flights = await flightService.getAgentFlights(_userid);
      if (_selectedIndex == 3) {
        _earnings = await AgentService.getEarnings(_partnerid, _earningsPeriod);
      }

      if (mounted) {
        setState(() {
          _packages = packages;
          _buses = buses;
          _flights = flights;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading agent data: $e')));
      }
    }
  }

  Future<void> _openBusForm([BusModel? bus]) async {
    final saved = await context.push<bool>(
      '/agent/buses/add',
      extra: {'bus': bus, 'partnerid': _partnerid, 'userid': _userid},
    );
    if (saved == true) {
      setState(() => _isLoading = true);
      await _fetchDashboardData();
    }
  }

  Future<void> _deleteBus(BusModel bus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete bus?'),
            content: Text(
              '${bus.busName} will be removed from active listings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      await busService.deleteBus(
        busid: bus.busid,
        partnerid: _partnerid,
        uid: _userid,
      );
      await _fetchDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bus deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _openFlightForm([FlightModel? flight]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgentAddFlightScreen(flight: flight),
      ),
    );
    if (result == true) {
      setState(() => _isLoading = true);
      await _fetchDashboardData();
    }
  }

  Future<void> _deleteFlight(FlightModel flight) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete flight?'),
        content: Text('${flight.airline} ${flight.flightNumber} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final success = await flightService.deleteFlight(flight.flightId.toString(), _userid.toString());
      if (success) {
        await _fetchDashboardData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flight deleted successfully')));
        }
      } else {
        throw Exception('Server returned failure');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

    Widget _buildDesktopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: _ink,
                ),
                onPressed: () {
                  themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                },
              );
            },
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            backgroundColor: _primary,
            child: Text(
              _fullname.isNotEmpty ? _fullname[0].toUpperCase() : 'A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isDesktop ? null : AppBar(
        title: Text('Agent Panel', style: GoogleFonts.poppins(color: _ink)),
        backgroundColor: _surface,
        iconTheme: IconThemeData(color: _ink),
        elevation: 1,
      ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebar(false)),
            body: Row(
        children: [
          if (isDesktop) _buildSidebar(true),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) _buildDesktopHeader(context),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? _buildErrorState()
                          : _buildCurrentScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
      floatingActionButton: !isDesktop && _selectedIndex < 3 ? FloatingActionButton(
        onPressed: () async {
          if (_selectedIndex == 0) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddEditPackageScreen(isEdit: false, partnerid: _partnerid, userid: _userid)),
            );
            if (result == true) {
              setState(() => _isLoading = true);
              await _fetchDashboardData();
            }
          } else if (_selectedIndex == 1) {
            _openBusForm();
          } else if (_selectedIndex == 2) {
            _openFlightForm();
          }
        },
        backgroundColor: _primary,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0: return _buildPackagesTab();
      case 1: return _buildBusesTab();
      case 2: return _buildFlightsTab();
      case 3: return _buildEarningsTab();
      case 4: return const CouponManagementScreen(roleView: 'agent');
      case 5: return const OfferManagementScreen(roleView: 'agent');
      default: return _buildPackagesTab();
    }
  }

  Widget _buildEarningsTab() => EarningsTab(
        earningsData: _earnings,
        isLoading: _isLoading,
        selectedPeriod: _earningsPeriod,
        onPeriodChanged: (val) {
          setState(() => _earningsPeriod = val);
          _fetchDashboardData();
        },
      );

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
      onDestinationSelected: (i) {
        setState(() {
          _selectedIndex = i;
          _isLoading = true;
        });
        _fetchDashboardData();
      },
      backgroundColor: _surface,
      indicatorColor: _primary.withAlpha(30),
      destinations: [
        NavigationDestination(icon: Icon(Icons.map, color: _selectedIndex == 0 ? _primary : _muted), label: 'Packages'),
        NavigationDestination(icon: Icon(Icons.directions_bus, color: _selectedIndex == 1 ? _primary : _muted), label: 'Buses'),
        NavigationDestination(icon: Icon(Icons.flight, color: _selectedIndex == 2 ? _primary : _muted), label: 'Flights'),
        NavigationDestination(icon: Icon(Icons.account_balance_wallet, color: _selectedIndex == 3 ? _primary : _muted), label: 'Earnings'),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to load dashboard.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchDashboardData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isDesktop) {
    return Container(
      width: isDesktop ? 260 : null,
      decoration: BoxDecoration(
        color: _surface,
        border: isDesktop ? Border(right: BorderSide(color: Theme.of(context).dividerColor)) : null,
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
                    decoration: BoxDecoration(color: _primary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.flight_takeoff, color: _primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('TripEase', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: _ink)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Icon(
                      i == 0 ? Icons.map : i == 1 ? Icons.directions_bus : i == 2 ? Icons.flight : i == 3 ? Icons.account_balance_wallet : i == 4 ? Icons.local_offer : Icons.card_giftcard,
                      color: active ? _primary : _muted,
                    ),
                    title: Text(_menu[i], style: GoogleFonts.poppins(fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? _primary : _muted)),
                    selected: active,
                    selectedTileColor: _primary.withAlpha(20),
                    onTap: () {
                      setState(() {
                        _selectedIndex = i;
                        _isLoading = true;
                      });
                      _fetchDashboardData();
                      if (!isDesktop) Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Icon(Icons.person_outline_rounded, color: _muted),
              title: Text('Edit Profile', style: GoogleFonts.poppins(color: _muted, fontWeight: FontWeight.w500)),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(
                      userData: {'userid': _userid, 'fullname': _fullname, 'email': _email, 'photo': _photo},
                    ),
                  ),
                );
                if (result == true) _fetchDashboardData();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0).copyWith(top: 0),
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: Text('Logout', style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.w500)),
              onTap: () async {
                await authService.clearSession();
                if (mounted) context.go('/login');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Packages',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (MediaQuery.of(context).size.width > 800)
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditPackageScreen(
                          isEdit: false,
                          partnerid: _partnerid,
                          userid: _userid,
                        ),
                      ),
                    );
                    if (result == true) {
                      setState(() => _isLoading = true);
                      await _fetchDashboardData();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Package'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_packages.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No packages found.'),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount =
                    constraints.maxWidth > 1000
                        ? 3
                        : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _packages.length,
                  itemBuilder: (context, index) {
                    final package = _packages[index];
                    return _buildPackageCard(package);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(PackageModel package) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child:
                  package.thumbnail != null && package.thumbnail!.isNotEmpty
                      ? Base64Image(
                        base64String: package.thumbnail!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                      : Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image,
                          size: 50,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.packagename,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${package.days} Days / ${package.nights} Nights',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${package.price}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () async {
                        try {
                          final detail = await AgentService.getPackageDetail(
                              package.packageid, _partnerid);
                          if (!mounted) return;
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditPackageScreen(
                                isEdit: true,
                                packageData: detail,
                                partnerid: _partnerid,
                                userid: _userid,
                              ),
                            ),
                          );
                          if (result == true) {
                            setState(() => _isLoading = true);
                            await _fetchDashboardData();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to load package: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Buses',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (MediaQuery.of(context).size.width > 800)
                ElevatedButton.icon(
                  onPressed: () => _openBusForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bus'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_buses.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No buses found.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _buses.length,
              itemBuilder: (context, index) {
                final bus = _buses[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: (bus.imageUrl != null && bus.imageUrl!.trim().isNotEmpty)
                          ? Base64Image(
                              base64String: bus.imageUrl!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(
                              Icons.directions_bus,
                              color: Colors.blue,
                            ),
                    ),
                    title: Text(
                      bus.busName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${bus.sourceCityName ?? 'Src'} -> ${bus.destinationCityName ?? 'Dest'}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${bus.busType} • ${bus.layoutType} • ${bus.totalSeats} Seats',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${bus.baseFare}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${bus.departureTime} - ${bus.arrivalTime}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Edit bus',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _openBusForm(bus),
                        ),
                        IconButton(
                          tooltip: 'Delete bus',
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteBus(bus),
                        ),
                      ],
                    ),
                    onTap: () => _openBusForm(bus),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFlightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Flight Listings',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (MediaQuery.of(context).size.width > 800)
                ElevatedButton.icon(
                  onPressed: () => _openFlightForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Flight'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_flights.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40.0),
                child: Text('No flights listed yet.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _flights.length,
              itemBuilder: (context, index) {
                final flight = _flights[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.flight_takeoff, color: Colors.indigo),
                    ),
                    title: Text(
                      '${flight.airline} - ${flight.flightNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${flight.fromCityName} -> ${flight.toCityName}'),
                        const SizedBox(height: 4),
                        Text('Status: ${flight.status.toUpperCase()}', 
                          style: TextStyle(
                            color: flight.status == 'approved' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${flight.price}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                            ),
                            Text('${flight.availableSeats}/${flight.totalSeats} seats'),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                          onPressed: () => _openFlightForm(flight),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteFlight(flight),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

