import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/travel_image_placeholder.dart';
import '../../services/package_service.dart';
import '../../models/package_model.dart';
import '../../widgets/base64_image.dart';
import '../../widgets/fullscreen_gallery.dart';
import 'package_guest_details_screen.dart';
import '../../services/customer_service.dart';

class PackageDetailsScreen extends StatefulWidget {
  final String packageId;
  final String packageName;
  final double price;
  final String? imageUrl;
  final List<String>? images;

  const PackageDetailsScreen({
    super.key,
    required this.packageId,
    required this.packageName,
    required this.price,
    this.imageUrl,
    this.images,
  });

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  PackageModel? _package;
  bool _fetchingDetails = true;
  bool _isWishlisted = false;

  final PageController _heroCtrl = PageController();
  int _heroIndex = 0;
  late List<String> _heroImages;

  bool _transitionCompleted = false;
  Animation<double>? _routeAnimation;

  String get currentPackageName => widget.packageName.isNotEmpty ? widget.packageName : (_package?.packagename ?? 'Loading Package...');
  double get currentPrice => widget.price > 0 ? widget.price : (_package?.price ?? 0.0);

  @override
  void initState() {
    super.initState();
    _heroImages = [];
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _heroImages.add(widget.imageUrl!);
    }
    if (widget.images != null && widget.images!.isNotEmpty) {
      for (var img in widget.images!) {
        if (!_heroImages.contains(img)) {
          _heroImages.add(img);
        }
      }
    }
    _fetchPackageDetails();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) return;
    try {
      final list = await customerService.getWishlist(user.userid);
      if (mounted) {
        setState(() {
          _isWishlisted = list.any((item) =>
              item.itemType.toLowerCase() == 'package' &&
              item.itemId.toString() == widget.packageId);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to wishlist packages')),
      );
      return;
    }

    final oldState = _isWishlisted;
    setState(() {
      _isWishlisted = !_isWishlisted;
    });

    bool success;
    if (oldState) {
      success = await customerService.removeFromWishlist(
        userid: user.userid,
        itemType: 'package',
        itemId: int.parse(widget.packageId),
      );
    } else {
      success = await customerService.addToWishlist(
        userid: user.userid,
        itemType: 'package',
        itemId: int.parse(widget.packageId),
      );
    }

    if (!success) {
      if (mounted) {
        setState(() {
          _isWishlisted = oldState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update wishlist')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(oldState
                ? 'Removed from wishlist'
                : 'Added to wishlist'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _fetchPackageDetails() async {
    if (mounted) setState(() => _fetchingDetails = true);
    try {
      final list = await packageService.getHomePackages();
      final pkg = list.firstWhere((p) => p.packageid.toString() == widget.packageId);
      if (mounted) {
        setState(() {
          _package = pkg;
          _fetchingDetails = false;
          if (pkg.images.isNotEmpty) {
            for (var img in pkg.images) {
              if (!_heroImages.contains(img)) {
                _heroImages.add(img);
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _fetchingDetails = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load package details: $e')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.animation != null) {
      _routeAnimation = route.animation;
      if (_routeAnimation!.isCompleted) {
        _transitionCompleted = true;
      } else {
        _routeAnimation!.addStatusListener(_handleRouteAnimationStatus);
      }
    } else {
      _transitionCompleted = true;
    }
  }

  void _handleRouteAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (mounted) {
        setState(() {
          _transitionCompleted = true;
        });
      }
      _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    }
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_handleRouteAnimationStatus);
    _heroCtrl.dispose();
    super.dispose();
  }

  void _bookPackage() {
    final user = authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PackageGuestDetailsScreen(
          packageId: widget.packageId,
          packageName: currentPackageName,
          price: currentPrice,
          imageUrl: widget.imageUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      ignoring: !_transitionCompleted,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 350,
              pinned: true,
              stretch: true,
              backgroundColor: const Color(0xFF1E293B),
              leading: Padding(
                padding: const EdgeInsets.all(8),
                child: CircleAvatar(
                  backgroundColor: Colors.black38,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black38,
                    child: IconButton(
                      icon: Icon(
                        _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: _isWishlisted ? const Color(0xFFEF4444) : Colors.white,
                        size: 18,
                      ),
                      onPressed: _toggleWishlist,
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: _buildHero(),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPackageInfoCard(isDark),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Tour Itinerary',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildItinerarySection(isDark),
                  _buildLocationSection(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(isDark),
      ),
    );
  }

  Widget _buildHero() {
    if (_heroImages.isEmpty) return _heroFallback();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_heroImages.length == 1)
          GestureDetector(
            onTap: () => openFullscreenGallery(context, _heroImages, initialIndex: 0),
            child: Base64Image(base64String: _heroImages.first, fit: BoxFit.cover),
          )
        else
          PageView.builder(
            controller: _heroCtrl,
            onPageChanged: (i) => setState(() => _heroIndex = i),
            itemCount: _heroImages.length,
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => openFullscreenGallery(context, _heroImages, initialIndex: index),
              child: Base64Image(base64String: _heroImages[index], fit: BoxFit.cover),
            ),
          ),
        // Dark overlay gradient for readable app bar buttons
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withAlpha(100), Colors.transparent, Colors.black.withAlpha(120)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        if (_heroImages.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _heroImages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _heroIndex == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _heroIndex == i ? Colors.white : Colors.white.withAlpha(120),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _heroFallback() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.explore_rounded, size: 80, color: Colors.white24),
      ),
    );
  }

  Widget _buildPackageInfoCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  currentPackageName,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                    SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_package?.categoryName != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _package!.categoryName!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (_package?.cityName != null) ...[
                const Icon(Icons.location_on_rounded, color: Color(0xFFEC4899), size: 16),
                const SizedBox(width: 4),
                Text(
                  _package!.cityName!,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                Icons.wb_sunny_outlined,
                '${_package?.days ?? (widget.price > 0 ? (widget.price / 3000).ceil() : 3)} Days',
                'Duration',
                isDark,
              ),
              _buildStatItem(
                Icons.nights_stay_outlined,
                '${_package?.nights ?? (widget.price > 0 ? (widget.price / 3000).ceil() - 1 : 2)} Nights',
                'Night Stay',
                isDark,
              ),
              _buildStatItem(
                Icons.groups_outlined,
                '${_package?.maxpersons ?? 4} Max',
                'Group Size',
                isDark,
              ),
            ],
          ),
          if (_package?.description != null && _package!.description!.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              'About This Package',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _package!.description!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8B5CF6), size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildItinerarySection(bool isDark) {
    final itineraries = _package?.itineraries ?? [];
    if (_fetchingDetails) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (itineraries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          'No itinerary specified for this package.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? Colors.white60 : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itineraries.length,
        itemBuilder: (context, index) {
          final itin = itineraries[index];
          final isLast = index == itineraries.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF8B5CF6), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withAlpha(80),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 3,
                          color: const Color(0xFF8B5CF6).withAlpha(80),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withAlpha(30),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'DAY ${itin.dayno}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                itin.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (itin.description != null && itin.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            itin.description!,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationSection(bool isDark) {
    if (_package?.latitude == null || _package?.longitude == null) return const SizedBox.shrink();
    final latLng = LatLng(_package!.latitude!, _package!.longitude!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Location',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: latLng,
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tripease.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latLng,
                        width: 60,
                        height: 60,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_package?.cityName != null) ...[
            const SizedBox(height: 12),
            Text(
              _package!.cityName!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 10),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price Starts At',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  '₹${currentPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEC4899),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _bookPackage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                minimumSize: const Size(150, 54),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Book Package',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
