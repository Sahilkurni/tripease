import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import 'widgets/home_header.dart';
import 'widgets/service_card.dart';
import 'widgets/offer_card.dart';
import 'widgets/destination_card.dart';
import 'widgets/recommended_card.dart';
import 'widgets/custom_bottom_nav.dart';

// ─── MOCK DATA MODELS ───────────────────────────────────────────────────────
// TODO: Move these to lib/models/ and fetch from PHP API

class ServiceItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  const ServiceItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id']?.toString() ?? '',
      label: json['label'] ?? json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: Icons.travel_explore, // fallback
      gradient: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
    );
  }

  static List<ServiceItem> mock() => const [
    ServiceItem(
      id: 'hotel',
      label: 'Hotels',
      subtitle: 'Luxury stays',
      icon: Icons.hotel_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
    ),
    ServiceItem(
      id: 'bus',
      label: 'Bus',
      subtitle: 'Comfortable rides',
      icon: Icons.directions_bus_rounded,
      gradient: [Color(0xFF059669), Color(0xFF047857)],
    ),
  ];
}

class OfferItem {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl; // TODO: replace with API image URL
  const OfferItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  factory OfferItem.fromJson(Map<String, dynamic> json) {
    return OfferItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
    );
  }

  static List<OfferItem> mock() => const [
    OfferItem(
      id: 'o1',
      title: 'Flat 20% Off',
      subtitle: 'On Luxury Hotels',
      imageUrl:
          'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600',
    ),
  ];
}

class DestinationItem {
  final String id;
  final String name;
  final String country;
  final String imageUrl; // TODO: replace with API image URL
  const DestinationItem({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
  });

  factory DestinationItem.fromJson(Map<String, dynamic> json) {
    return DestinationItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
    );
  }

  static List<DestinationItem> mock() => const [
    DestinationItem(
      id: 'd1',
      name: 'Goa',
      country: 'India',
      imageUrl:
          'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=400',
    ),
  ];
}

class QuickSearchChip {
  final String id;
  final String label;
  const QuickSearchChip({required this.id, required this.label});
}

class RecommendedItem {
  final String id;
  final String name;
  final String location;
  final double rating;
  final double price;
  final String type; // 'hotel' | 'bus' | 'package'
  final String imageUrl; // TODO: replace with API image URL
  const RecommendedItem({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
    required this.type,
    required this.imageUrl,
  });

  factory RecommendedItem.fromJson(Map<String, dynamic> json) {
    return RecommendedItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      rating:
          (json['rating'] is num)
              ? (json['rating'] as num).toDouble()
              : double.tryParse('${json['rating']}') ?? 0.0,
      price:
          (json['price'] is num)
              ? (json['price'] as num).toDouble()
              : double.tryParse('${json['price']}') ?? 0.0,
      type: json['type'] ?? 'hotel',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
    );
  }

  static List<RecommendedItem> mock() => const [
    RecommendedItem(
      id: 'r1',
      name: 'Taj Mahal Palace',
      location: 'Mumbai',
      rating: 4.9,
      price: 12500,
      type: 'hotel',
      imageUrl:
          'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=300',
    ),
  ];

  @override
  String toString() => 'RecommendedItem($id, $name)';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  // Dynamic data loaded from backend or fallbacks
  List<ServiceItem> _services = [];
  List<OfferItem> _offers = [];
  List<DestinationItem> _destinations = [];
  List<RecommendedItem> _recommended = [];
  List<QuickSearchChip> _searchChips = [];

  // removed unused _loading/_error fields

  // default quick search chips will be populated in initState

  // TODO: Replace with: final user = await AuthService.getCurrentUser();
  static const _userName = 'Sahil';
  static const _userLocation = 'Hubballi, Karnataka';

  late String _selectedLocation;
  Position? _currentPosition;

  late bool isMobile;
  late bool isTablet;
  late bool isDesktop;
  late double hPad;

  @override
  void initState() {
    super.initState();
    _selectedLocation = _userLocation;
    // populate with mock data initially; will be replaced when connected to API
    _services = ServiceItem.mock();
    _offers = OfferItem.mock();
    _destinations = DestinationItem.mock();
    _recommended = RecommendedItem.mock();
    _searchChips = const [
      QuickSearchChip(id: 'c1', label: 'Goa'),
      QuickSearchChip(id: 'c2', label: 'Dubai'),
      QuickSearchChip(id: 'c3', label: 'Manali'),
      QuickSearchChip(id: 'c4', label: 'Mumbai'),
      QuickSearchChip(id: 'c5', label: 'Bangalore'),
      QuickSearchChip(id: 'c6', label: 'Kerala'),
    ];
    // initialised data; not loading from network yet
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    isMobile = screenW < 600;
    isTablet = screenW >= 600 && screenW < 1024;
    isDesktop = screenW >= 1024;
    hPad =
        isDesktop
            ? 48.0
            : isTablet
            ? 32.0
            : 20.0;

    // We use a safe check for dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBot = MediaQuery.of(context).padding.bottom;

    // selected location initialized in initState

    // Main content switches based on bottom navigation index
    Widget mainContent;
    switch (_navIndex) {
      case 1:
        mainContent = _buildBookingsView(safeBot);
        break;
      case 2:
        mainContent = _buildWishlistView(safeBot);
        break;
      case 3:
        mainContent = _buildProfileView(safeBot);
        break;
      case 0:
      default:
        mainContent = CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header
            SliverToBoxAdapter(
              child: HomeHeaderWidget(
                userName: _userName,
                location: _userLocation,
              ),
            ),

            // 2. Search bar + chips (overlaps header by 24px)
            SliverToBoxAdapter(child: _buildSearchSection()),

            // 3. Quick Services
            SliverToBoxAdapter(
              child: _sectionHeader(context, 'Quick Services', '/services'),
            ),
            SliverToBoxAdapter(child: _buildServicesGrid()),

            // 4. Trending Offers
            SliverToBoxAdapter(
              child: _sectionHeader(context, 'Trending Offers', '/offers'),
            ),
            SliverToBoxAdapter(child: _buildOffersRow()),

            // 5. Popular Destinations
            SliverToBoxAdapter(
              child: _sectionHeader(
                context,
                'Popular Destinations',
                '/destinations',
              ),
            ),
            SliverToBoxAdapter(child: _buildDestinationsSection()),

            // 6. Recommended For You
            SliverToBoxAdapter(
              child: _sectionHeader(
                context,
                'Recommended For You',
                '/recommended',
              ),
            ),
            SliverToBoxAdapter(child: _buildRecommendedSection()),

            // Bottom padding for nav bar
            SliverToBoxAdapter(child: SizedBox(height: safeBot + 90)),
          ],
        );
        break;
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      body: Stack(
        children: [
          // page content
          Positioned.fill(child: mainContent),

          // Floating bottom nav (centered + constrained on large screens)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 900 : MediaQuery.of(context).size.width,
                ),
                child: CustomBottomNav(
                  currentIndex: _navIndex,
                  onTap: (i) => setState(() => _navIndex = i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _openLocationPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.03 * 255).round()),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _selectedLocation,
                        style: GoogleFonts.poppins(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Current location button
                    GestureDetector(
                      onTap: () async {
                        await _getCurrentLocation();
                      },
                      child: const Icon(
                        Icons.my_location,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Open maps button
                    GestureDetector(
                      onTap: () async {
                        await _openMaps();
                      },
                      child: const Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Location picker bottom sheet opener
        Transform.translate(
          offset: Offset(
            0,
            isDesktop
                ? 12
                : isTablet
                ? 8
                : 4,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    isDesktop ? 1100 : MediaQuery.of(context).size.width - 16,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.06 * 255).round()),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'Search hotels, buses, packages in ${_selectedLocation.split(',').first}...',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: GoogleFonts.poppins(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            children:
                _searchChips
                    .map(
                      (chip) => Padding(
                        padding: EdgeInsets.only(
                          right: chip == _searchChips.last ? 0 : 8,
                        ),
                        child: FilterChip(
                          label: Text(chip.label),
                          labelStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkCard
                                  : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.grey.withAlpha((0.2 * 255).round()),
                            ),
                          ),
                          onSelected: (val) {
                            // TODO: onSelected → pre-fill search bar with chip label
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String manual = '';
        return StatefulBuilder(
          builder: (ctx2, setState2) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Location',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _searchChips.map((c) {
                          final selected =
                              _selectedLocation
                                  .split(',')
                                  .first
                                  .toLowerCase() ==
                              c.label.toLowerCase();
                          return ChoiceChip(
                            label: Text(c.label),
                            selected: selected,
                            onSelected: (v) {
                              setState2(() {
                                _selectedLocation = c.label;
                              });
                              Navigator.of(ctx).pop();
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Or enter custom location',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'City, State or Area',
                    ),
                    onChanged: (v) => manual = v,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        setState2(() => _selectedLocation = v.trim());
                        Navigator.of(ctx).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (manual.trim().isNotEmpty) {
                              setState2(
                                () => _selectedLocation = manual.trim(),
                              );
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.my_location_outlined),
                          label: const Text('Use current location'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _getCurrentLocation().catchError((e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Location error: $e')),
                                );
                              });
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open in Maps'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _openMaps().catchError((e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Maps error: $e')),
                                );
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them from settings.',
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentPosition = pos;
        _selectedLocation =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<void> _openMaps() async {
    try {
      if (_currentPosition != null) {
        final lat = _currentPosition!.latitude;
        final lng = _currentPosition!.longitude;
        final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
        }
        return;
      }

      // If we don't have coordinates, open maps with the selected location string
      final query = Uri.encodeComponent(_selectedLocation);
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maps error: $e')));
    }
  }

  Widget _buildBookingsView(double safeBot) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, safeBot + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: 0, // TODO: wire to real bookings
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder:
                    (_, i) => ListTile(
                      title: Text('Booking #$i'),
                      subtitle: const Text('No bookings available.'),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistView(double safeBot) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, safeBot + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wishlist',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _recommended.isEmpty
                      ? Center(
                        child: Text(
                          'Your wishlist is empty',
                          style: GoogleFonts.poppins(),
                        ),
                      )
                      : ListView.builder(
                        itemCount: _recommended.length,
                        itemBuilder:
                            (_, idx) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: RecommendedCard(
                                item: _recommended[idx],
                                onTap: () {},
                              ),
                            ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(double safeBot) {
    final user = authService.currentUser;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, safeBot + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Builder(
                    builder: (_) {
                      final displayName = (user?.name ?? _userName).trim();
                      final initial =
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U';
                      return Text(initial);
                    },
                  ),
                ),
                title: Text(user?.name ?? _userName),
                subtitle: Text(user?.email ?? 'Not signed in'),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await authService.clearSession();
                if (!mounted) return;
                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    String seeAllRoute,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText
                      : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              // TODO: Navigator.pushNamed(context, seeAllRoute);
            },
            child: Text(
              'See All',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    final padding = EdgeInsets.symmetric(horizontal: hPad);
    if (isMobile) {
      return Padding(
        padding: padding,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              _services.map((s) {
                final cardW =
                    (MediaQuery.of(context).size.width - hPad * 2 - 12) / 2;
                return SizedBox(
                  width: cardW,
                  child: ServiceCard(
                    item: s,
                    onTap: () {
                      // TODO: navigate based on item.id
                    },
                  ),
                );
              }).toList(),
        ),
      );
    }
    return Padding(
      padding: padding,
      child: Row(
        children:
            _services
                .map(
                  (s) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: s == _services.last ? 0 : 12,
                      ),
                      child: ServiceCard(
                        item: s,
                        onTap: () {
                          // TODO: navigate based on item.id
                        },
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildOffersRow() {
    final cardW =
        isMobile
            ? MediaQuery.of(context).size.width * 0.72
            : isTablet
            ? 300.0
            : 340.0;
    return SizedBox(
      height: 160,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        scrollDirection: Axis.horizontal,
        itemCount: _offers.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder:
            (_, i) => SizedBox(
              width: cardW,
              child: OfferCard(
                item: _offers[i],
                onTap: () {
                  // TODO: navigate to offer detail
                },
              ),
            ),
      ),
    );
  }

  Widget _buildDestinationsSection() {
    final cardSize =
        isMobile
            ? 140.0
            : isTablet
            ? 155.0
            : 160.0;
    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Row(
          children: () {
            final items = _destinations.take(6).toList();
            return List<Widget>.generate(items.length, (i) {
              final d = items[i];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == items.length - 1 ? 0 : 12,
                  ),
                  child: SizedBox(
                    height: cardSize,
                    child: DestinationCard(
                      item: d,
                      onTap: () {
                        // TODO: navigate to destination detail
                      },
                    ),
                  ),
                ),
              );
            });
          }(),
        ),
      );
    }
    return SizedBox(
      height: cardSize,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        scrollDirection: Axis.horizontal,
        itemCount: _destinations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder:
            (_, i) => SizedBox(
              width: cardSize,
              child: DestinationCard(
                item: _destinations[i],
                onTap: () {
                  // TODO: navigate to destination detail
                },
              ),
            ),
      ),
    );
  }

  Widget _buildRecommendedSection() {
    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          children:
              _recommended
                  .map(
                    (r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RecommendedCard(
                        item: r,
                        onTap: () {
                          // TODO: navigate based on item.type
                        },
                      ),
                    ),
                  )
                  .toList(),
        ),
      );
    }
    // 2-column grid
    final pairs = <List<RecommendedItem>>[];
    for (var i = 0; i < _recommended.length; i += 2) {
      pairs.add(
        _recommended.sublist(
          i,
          i + 2 > _recommended.length ? _recommended.length : i + 2,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        children:
            pairs
                .map(
                  (pair) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children:
                          pair
                              .map(
                                (r) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: r == pair.last ? 0 : 12,
                                    ),
                                    child: RecommendedCard(
                                      item: r,
                                      onTap: () {
                                        // TODO: navigate based on item.type
                                      },
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
