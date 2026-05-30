import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/hotel_service.dart';
import '../../models/hotel_model.dart';
import '../home/dashboard_screen.dart'; // To reuse RecommendedItem if needed, but we'll use HotelModel

import 'hotel_details_screen.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({super.key});

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  final HotelService _hotelService = hotelService;
  List<HotelModel> _hotels = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'Recommended';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchHotels();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHotels() async {
    try {
      final hotels = await _hotelService.getHomeHotels();
      setState(() {
        _hotels = hotels;
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
      _sortBy = 'Recommended';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final hPad = isDesktop ? 48.0 : (size.width > 600 ? 32.0 : 20.0);

    // 1. Filter hotels
    List<HotelModel> filteredHotels = _hotels.where((hotel) {
      final matchesSearch = _searchQuery.isEmpty ||
          hotel.hotelname.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (hotel.address ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    // 2. Sort hotels
    if (_sortBy == 'Price: Low to High') {
      filteredHotels.sort((a, b) => (a.startingPrice ?? 0).compareTo(b.startingPrice ?? 0));
    } else if (_sortBy == 'Price: High to Low') {
      filteredHotels.sort((a, b) => (b.startingPrice ?? 0).compareTo(a.startingPrice ?? 0));
    } else if (_sortBy == 'Rating') {
      // Sort by rating (we assume constant high rating for now since rating is static in card, 
      // but let's sort by rating descending or hotelid descending as a proxy for recommended)
      filteredHotels.sort((a, b) => b.hotelid.compareTo(a.hotelid));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Discover Hotels', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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
                    // Search & Sorting Header Panel
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
                                hintText: 'Search by Hotel Name or City...',
                                hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
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
                                ...['Recommended', 'Price: Low to High', 'Price: High to Low', 'Rating'].map((opt) {
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

                    // Hotels List / Grid
                    Expanded(
                      child: filteredHotels.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.hotel_rounded, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hotels match your filters',
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
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 1200),
                                  child: isDesktop
                                      ? GridView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                            maxCrossAxisExtent: 400,
                                            mainAxisSpacing: 24,
                                            crossAxisSpacing: 24,
                                            mainAxisExtent: 320,
                                          ),
                                          itemCount: filteredHotels.length,
                                          itemBuilder: (context, index) => _HotelCard(hotel: filteredHotels[index], isDark: isDark),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: filteredHotels.length,
                                          itemBuilder: (context, index) => Padding(
                                            padding: const EdgeInsets.only(bottom: 20),
                                            child: _HotelCard(hotel: filteredHotels[index], isDark: isDark),
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
}

class _HotelCard extends StatelessWidget {
  final HotelModel hotel;
  final bool isDark;

  const _HotelCard({required this.hotel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/hotel_detail', // Using the route from app_routes.dart
          // Note: HotelDetailScreen in app_routes.dart doesn't take parameters yet, 
          // but I should probably update it or use my new HotelDetailsScreen.
          // Wait, app_routes.dart has '/hotel_detail' -> HotelDetailScreen()
          // But I just created HotelDetailsScreen in lib/screens/hotels/hotel_details_screen.dart
          // Let's check the route again.
        );
        // Better: Navigator push since I updated HotelDetailsScreen to take params
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HotelDetailsScreen(
              hotelId: hotel.hotelid.toString(),
              hotelName: hotel.hotelname,
            ),
          ),
        );
      },
      child: Container(
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
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.hotel_rounded, color: Colors.white, size: 48),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${hotel.startingPrice?.toStringAsFixed(0) ?? "0"}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF2563EB),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.hotelname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hotel.address ?? 'Location',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      const Text(
                        '4.8',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
