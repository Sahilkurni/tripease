import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../services/package_service.dart';
import '../../models/package_model.dart';
import 'package:tripease/screens/home/package_details_screen.dart';

class PackageListScreen extends StatefulWidget {
  const PackageListScreen({super.key});

  @override
  State<PackageListScreen> createState() => _PackageListScreenState();
}

class _PackageListScreenState extends State<PackageListScreen> {
  final PackageService _packageService = packageService;
  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'Recommended';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPackages() async {
    try {
      final packages = await _packageService.getHomePackages();
      setState(() {
        _packages = packages;
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

    // 1. Filter packages
    List<PackageModel> filteredPackages = _packages.where((package) {
      final matchesSearch = _searchQuery.isEmpty ||
          package.packagename.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (package.cityName ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (package.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    // 2. Sort packages
    if (_sortBy == 'Price: Low to High') {
      filteredPackages.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'Price: High to Low') {
      filteredPackages.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'Duration') {
      filteredPackages.sort((a, b) => a.days.compareTo(b.days));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Tour Packages', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
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
                    // Search & Sorting Header Container
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
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B5CF6)),
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
                                hintText: 'Search by Tour Name or Destination...',
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
                                      selectedColor: const Color(0xFF8B5CF6),
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

                    // Packages List / Grid
                    Expanded(
                      child: filteredPackages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.explore_rounded, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No packages match your filters',
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
                                          itemCount: filteredPackages.length,
                                          itemBuilder: (context, index) => _PackageCard(package: filteredPackages[index], isDark: isDark),
                                        )
                                      : ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: filteredPackages.length,
                                          itemBuilder: (context, index) => Padding(
                                            padding: const EdgeInsets.only(bottom: 20),
                                            child: _PackageCard(package: filteredPackages[index], isDark: isDark),
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
          Icon(Icons.card_travel_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No packages available',
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
        maxCrossAxisExtent: 400,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: 320,
      ),
      itemCount: _packages.length,
      itemBuilder: (context, index) => _PackageCard(package: _packages[index], isDark: isDark),
    );
  }

  Widget _buildList(BuildContext context, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _packages.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _PackageCard(package: _packages[index], isDark: isDark),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final PackageModel package;
  final bool isDark;

  const _PackageCard({required this.package, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PackageDetailsScreen(
              packageId: package.packageid.toString(),
              packageName: package.packagename,
              price: package.price,
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
                        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.explore_rounded, color: Colors.white, size: 48),
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
                        '₹${package.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF8B5CF6),
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
                    package.packagename,
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
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        '${package.days} Days',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      const Text(
                        '4.9',
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
