import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/bus_service.dart';
import '../../models/bus_model.dart';

class BusListScreen extends StatefulWidget {
  final String? source;
  final String? destination;
  final String? date;

  const BusListScreen({
    super.key,
    this.source,
    this.destination,
    this.date,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  final BusService _busService = busService;
  List<BusModel> _buses = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'Recommended';
  String? _selectedSource;
  String? _selectedDestination;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.source == 'Source' ? null : widget.source;
    _selectedDestination = widget.destination == 'Destination' ? null : widget.destination;
    _fetchBuses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBuses() async {
    try {
      // Fetch all trips so the user can filter dynamically
      final buses = await _busService.getHomeBusTrips();
      setState(() {
        _buses = buses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedSource = null;
      _selectedDestination = null;
      _sortBy = 'Recommended';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final hPad = isDesktop ? 48.0 : (size.width > 600 ? 32.0 : 20.0);

    // 1. Extract unique cities dynamically from loaded buses
    final sourceCities = _buses
        .map((b) => 'Source')
        .whereType<String>()
        .toSet()
        .toList();
    sourceCities.sort();

    final destCities = _buses
        .map((b) => 'Destination')
        .whereType<String>()
        .toSet()
        .toList();
    destCities.sort();

    // 2. Filter buses locally
    List<BusModel> filteredBuses = _buses.where((bus) {
      final matchesSearch = _searchQuery.isEmpty ||
          bus.busname.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          bus.bustype.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ('Source').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ('Destination').toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesSource = _selectedSource == null || 'Source' == _selectedSource;
      final matchesDest = _selectedDestination == null || 'Destination' == _selectedDestination;

      return matchesSearch && matchesSource && matchesDest;
    }).toList();

    // 3. Sort buses (removed baseFare sorting since no price exists)
    if (_sortBy == 'Price: Low to High') {
      // no-op
    } else if (_sortBy == 'Price: High to Low') {
      // no-op
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Available Bus Trips',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    // Filters Header
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Search field
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _searchController.clear();
                                          });
                                        },
                                      )
                                    : null,
                                hintText: 'Search by Bus Operator or City...',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // From/To Selectors
                          Row(
                            children: [
                              // From Dropdown
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedSource,
                                      hint: Row(
                                        children: [
                                          const Icon(Icons.directions_bus_filled_rounded, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('From', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                      items: sourceCities.map((city) {
                                        return DropdownMenuItem<String>(
                                          value: city,
                                          child: Text(
                                            city,
                                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedSource = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  Icons.swap_horiz_rounded,
                                  color: const Color(0xFF2563EB).withOpacity(0.6),
                                  size: 20,
                                ),
                              ),
                              // To Dropdown
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedDestination,
                                      hint: Row(
                                        children: [
                                          const Icon(Icons.location_city_rounded, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('To', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                      items: destCities.map((city) {
                                        return DropdownMenuItem<String>(
                                          value: city,
                                          child: Text(
                                            city,
                                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          _selectedDestination = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              
                              if (_selectedSource != null || _selectedDestination != null)
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.redAccent),
                                  tooltip: 'Reset Cities',
                                  onPressed: () {
                                    setState(() {
                                      _selectedSource = null;
                                      _selectedDestination = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Sort Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                Text(
                                  'Sort By: ',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                ...['Recommended', 'Price: Low to High', 'Price: High to Low'].map((opt) {
                                  final selected = _sortBy == opt;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: ChoiceChip(
                                      label: Text(
                                        opt == 'Recommended' ? 'Popular' : opt,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                          color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xDD000000)),
                                        ),
                                      ),
                                      selected: selected,
                                      selectedColor: const Color(0xFF2563EB),
                                      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                                      onSelected: (v) {
                                        if (v) {
                                          setState(() {
                                            _sortBy = opt;
                                          });
                                        }
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Buses list
                    Expanded(
                      child: filteredBuses.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_bus_rounded, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No buses match your filters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _resetFilters,
                                    child: const Text('Reset All Filters'),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1200),
                                  child: isDesktop
                                      ? GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 450,
                                            mainAxisSpacing: 24,
                                            crossAxisSpacing: 24,
                                            mainAxisExtent: 220,
                                          ),
                                          itemCount: filteredBuses.length,
                                          itemBuilder: (context, index) => _BusTripCard(bus: filteredBuses[index], isDark: isDark),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: filteredBuses.length,
                                          itemBuilder: (context, index) => Padding(
                                            padding: const EdgeInsets.only(bottom: 20),
                                            child: _BusTripCard(bus: filteredBuses[index], isDark: isDark),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No buses found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 450,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: 220,
      ),
      itemCount: _buses.length,
      itemBuilder: (context, index) => _BusTripCard(bus: _buses[index], isDark: isDark),
    );
  }

  Widget _buildList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _buses.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _BusTripCard(bus: _buses[index], isDark: isDark),
      ),
    );
  }
}

class _BusTripCard extends StatelessWidget {
  final BusModel bus;
  final bool isDark;

  const _BusTripCard({required this.bus, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus.busname,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                '₹${0.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bus.bustype,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeLoc('N/A', 'Source' ?? 'Source', false),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF2563EB), size: 20),
              _buildTimeLoc('N/A', 'Destination' ?? 'Dest', true),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/bus/seats', extra: bus),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB).withAlpha(30),
                foregroundColor: const Color(0xFF2563EB),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Select Seats', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLoc(String time, String loc, bool alignEnd) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        Text(
          loc,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}
