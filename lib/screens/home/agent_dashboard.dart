import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/package_service.dart';
import '../../services/bus_service.dart';
import '../../models/package_model.dart';
import '../../models/bus_model.dart';
import 'package:go_router/go_router.dart';

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  int _partnerid = 0;
  int _userid = 0;
  List<PackageModel> _packages = [];
  List<BusModel> _buses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        // Fallback to 1 (default user/partner in db seeds) to avoid crashes 
        // when session is stale or backend omits it
        _partnerid = 1; 
      }

      final packages = await packageService.getAgentPackages(_partnerid);
      final buses = await busService.getAgentBuses(_partnerid);

      if (mounted) {
        setState(() {
          _packages = packages;
          _buses = buses;
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width > 800) _buildSidebar(context),
          Expanded(
            child: NestedScrollView(
              headerSliverBuilder:
                  (context, innerBoxIsScrolled) => [_buildAppBar(context)],
              body:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? _buildErrorState()
                      : TabBarView(
                        controller: _tabController,
                        children: [_buildPackagesTab(), _buildBusesTab()],
                      ),
            ),
          ),
        ],
      ),
      floatingActionButton:
          MediaQuery.of(context).size.width <= 800
              ? FloatingActionButton(
                onPressed: () {
                  if (_tabController.index == 0) {
                    context.push('/agent/packages/add');
                  } else {
                    _openBusForm();
                  }
                },
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.add),
              )
              : null,
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

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(Icons.flight_takeoff, color: Colors.blueAccent, size: 28),
                SizedBox(width: 12),
                Text(
                  'Agent Panel',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blueAccent),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Tour Packages'),
            onTap: () => _tabController.animateTo(0),
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus),
            title: const Text('Bus Inventory'),
            onTap: () => _tabController.animateTo(1),
          ),
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('Earnings & Taxes'),
            onTap: () {},
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authService.clearSession();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        title: Text(
          'Welcome, Travel Agent',
          style: TextStyle(
            color: Colors.blueGrey[900],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        tabs: const [
          Tab(icon: Icon(Icons.map), text: 'Packages'),
          Tab(icon: Icon(Icons.directions_bus), text: 'Buses'),
        ],
      ),
      actions: [
        if (MediaQuery.of(context).size.width <= 800)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await authService.clearSession();
              if (context.mounted) context.go('/login');
            },
          ),
      ],
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
                  onPressed: () => context.push('/agent/packages/add'),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                      ? Image.network(
                        package.thumbnail!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                      )
                      : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 50,
                          color: Colors.grey,
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
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${package.price}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {},
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
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
}
