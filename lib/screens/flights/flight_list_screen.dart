import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/flight_model.dart';
import '../../services/flight_service.dart';
import '../../widgets/animated_flight_card.dart';
import '../home/dashboard_screen.dart';
import 'flight_details_screen.dart';

class FlightListScreen extends StatefulWidget {
  const FlightListScreen({super.key});

  @override
  State<FlightListScreen> createState() => _FlightListScreenState();
}

class _FlightListScreenState extends State<FlightListScreen> {
  List<FlightModel> _flights = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'Recommended';
  String? _selectedFromCity;
  String? _selectedToCity;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final flights = await flightService.getHomeFlights();
      setState(() {
        _flights = flights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load flights';
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedFromCity = null;
      _selectedToCity = null;
      _sortBy = 'Recommended';
    });
  }

  int _parseDuration(String d) {
    try {
      final hours = RegExp(r'(\d+)h').firstMatch(d)?.group(1);
      final minutes = RegExp(r'(\d+)m').firstMatch(d)?.group(1);
      final h = hours != null ? int.parse(hours) : 0;
      final m = minutes != null ? int.parse(minutes) : 0;
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;
    final hPad = screenW > 900 ? 48.0 : (screenW > 600 ? 32.0 : 20.0);

    // 1. Extract unique from/to cities dynamically
    final fromCities = _flights
        .map((f) => f.fromCityName)
        .whereType<String>()
        .toSet()
        .toList();
    fromCities.sort();

    final toCities = _flights
        .map((f) => f.toCityName)
        .whereType<String>()
        .toSet()
        .toList();
    toCities.sort();

    // 2. Filter flights
    List<FlightModel> filteredFlights = _flights.where((flight) {
      final matchesSearch = _searchQuery.isEmpty ||
          flight.airline.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          flight.flightNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (flight.fromCityName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (flight.toCityName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFrom = _selectedFromCity == null || flight.fromCityName == _selectedFromCity;
      final matchesTo = _selectedToCity == null || flight.toCityName == _selectedToCity;

      return matchesSearch && matchesFrom && matchesTo;
    }).toList();

    // 3. Sort flights
    if (_sortBy == 'Price: Low to High') {
      filteredFlights.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      filteredFlights.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Duration') {
      filteredFlights.sort((a, b) => _parseDuration(a.duration).compareTo(_parseDuration(b.duration)));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      appBar: AppBar(
        title: Text(
          'Discover Flights',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: GoogleFonts.poppins()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFlights,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search and Filter Header Container
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
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
                          // Search Input Field
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
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
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
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
                                hintText: 'Search by Airline or City...',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // From & To Selectors Row
                          Row(
                            children: [
                              // From Dropdown
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedFromCity,
                                      hint: Row(
                                        children: [
                                          const Icon(Icons.flight_takeoff_rounded, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('From', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                      items: fromCities.map((city) {
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
                                          _selectedFromCity = val;
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
                                  color: AppColors.primary.withOpacity(0.6),
                                  size: 20,
                                ),
                              ),
                              // To Dropdown
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : Colors.grey[200]!,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedToCity,
                                      hint: Row(
                                        children: [
                                          const Icon(Icons.flight_land_rounded, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text('To', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                      items: toCities.map((city) {
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
                                          _selectedToCity = val;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              
                              if (_selectedFromCity != null || _selectedToCity != null)
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.redAccent),
                                  tooltip: 'Reset Cities',
                                  onPressed: () {
                                    setState(() {
                                      _selectedFromCity = null;
                                      _selectedToCity = null;
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
                                ...['Recommended', 'Price: Low to High', 'Price: High to Low', 'Duration'].map((opt) {
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
                                      selectedColor: AppColors.primary,
                                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
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

                    // Flight Cards List / Grid
                    Expanded(
                      child: filteredFlights.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.flight_rounded, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No flights matches your criteria',
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
                              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1200),
                                  child: Wrap(
                                    spacing: 20,
                                    runSpacing: 20,
                                    children: filteredFlights.map((flight) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FlightDetailsScreen(flight: flight),
                                            ),
                                          );
                                        },
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 350),
                                          child: AnimatedFlightCard(
                                            flight: flight,
                                            delay: const Duration(milliseconds: 200),
                                          ),
                                        ),
                                      );
                                    }).toList(),
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

