import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/auth_service.dart';
import '../../services/hotel_service.dart';
import '../../models/room_model.dart';
import '../../models/hotel_model.dart';
import 'guest_details_screen.dart';
import '../../widgets/base64_image.dart';
import '../../services/hotel_partner_service.dart';
import '../../widgets/fullscreen_gallery.dart';
import '../../services/customer_service.dart';

class HotelDetailsScreen extends StatefulWidget {
  final String hotelId;
  final String hotelName;
  final String? imageUrl;
  final List<String>? images;

  const HotelDetailsScreen({
    super.key,
    required this.hotelId,
    required this.hotelName,
    this.imageUrl,
    this.images,
  });

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  final HotelService _hotelService = hotelService;
  final AuthService _authService = authService;
  List<RoomModel> _rooms = [];
  HotelModel? _hotelModel;
  bool _isLoading = true;
  String? _error;
  bool _isWishlisted = false;

  final PageController _heroCtrl = PageController();
  int _heroIndex = 0;
  late List<String> _heroImages;
  final Map<String, Uint8List> _heroBytes = {};

  @override
  void initState() {
    super.initState();
    _heroImages = (widget.images != null && widget.images!.isNotEmpty)
        ? widget.images!
        : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty
            ? [widget.imageUrl!]
            : []);
    _preDecodeAll();
    _loadData();
    if (_heroImages.isEmpty) _fetchHeroImages();
    _startAutoSlide();
    _checkWishlistStatus();
  }

  Future<void> _checkWishlistStatus() async {
    final user = _authService.currentUser;
    if (user == null || user.userid.isEmpty) return;
    try {
      final list = await customerService.getWishlist(user.userid);
      if (mounted) {
        setState(() {
          _isWishlisted = list.any((item) =>
              item.itemType.toLowerCase() == 'hotel' &&
              item.itemId.toString() == widget.hotelId);
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleWishlist() async {
    final user = _authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to wishlist hotels')),
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
        itemType: 'hotel',
        itemId: int.parse(widget.hotelId),
      );
    } else {
      success = await customerService.addToWishlist(
        userid: user.userid,
        itemType: 'hotel',
        itemId: int.parse(widget.hotelId),
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

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _hotelService.getHotelRooms(int.parse(widget.hotelId)),
        _fetchHotelDetails(),
      ]);
      
      if (!mounted) return;
      setState(() {
        _rooms = results[0] as List<RoomModel>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchHotelDetails() async {
    try {
      final hotels = await _hotelService.getHomeHotels();
      final hotel = hotels.firstWhere((h) => h.hotelid.toString() == widget.hotelId);
      if (mounted) {
        setState(() {
          _hotelModel = hotel;
        });
      }
    } catch (_) {}
  }

  void _preDecodeAll() {
    if (_heroImages.isEmpty) return;
    for (var img in _heroImages) {
      try {
        final clean = img.replaceAll(RegExp(r'\s+'), '');
        _heroBytes[img] = base64Decode(clean);
      } catch (_) {}
    }
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_heroImages.length > 1) {
        int next = (_heroIndex + 1) % _heroImages.length;
        if (_heroCtrl.hasClients) {
          _heroCtrl.animateToPage(
            next,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
        _startAutoSlide();
      }
    });
  }

  Future<void> _fetchHeroImages() async {
    try {
      final imgs = await _hotelService.getHotelImages(int.parse(widget.hotelId));
      if (mounted && imgs.isNotEmpty) {
        setState(() {
          _heroImages = imgs;
          _preDecodeAll();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }



  Future<void> _bookRoom(RoomModel room) async {
    final user = _authService.currentUser;
    if (user == null || user.userid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to book')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GuestDetailsScreen(
          hotelId: widget.hotelId,
          hotelName: widget.hotelName,
          room: room,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF1E293B),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.black38,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
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
              background: Hero(
                tag: 'hotel_image_${widget.hotelId}',
                child: _buildHero(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHotelNameCard(isDark),
                _buildAmenitiesRow(isDark),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 22,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Available Rooms',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_rooms.length} types',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text('Error: $_error')),
                  )
                else if (_rooms.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child:
                        Center(child: Text('No rooms available at this moment.')),
                  )
                else
                  ...(_rooms.map((r) => _buildRoomCard(r, isDark))),
                
                // Location Section
                if (_hotelModel != null && _hotelModel!.latitude != null && _hotelModel!.longitude != null)
                  _buildLocationSection(isDark),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(bool isDark) {
    final latLng = LatLng(_hotelModel!.latitude!, _hotelModel!.longitude!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
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
          const SizedBox(height: 12),
          Text(
            _hotelModel!.address ?? 'Address not specified',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero ────────────────────────────────────────────────────────────────

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
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            allowImplicitScrolling: true,
            onPageChanged: (i) => setState(() => _heroIndex = i),
            itemCount: _heroImages.length,
            itemBuilder: (_, i) {
              final img = _heroImages[i];
              final bytes = _heroBytes[img];
              return GestureDetector(
                onTap: () => openFullscreenGallery(context, _heroImages, initialIndex: i),
                child: bytes != null
                    ? Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        cacheWidth: 800,
                      )
                    : Base64Image(
                        base64String: img,
                        fit: BoxFit.cover,
                        cacheWidth: 800,
                      ),
              );
            },
          ),
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withAlpha(10),
                  Colors.transparent,
                  Colors.black.withAlpha(180),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hotelName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    shadows: [
                      Shadow(color: Colors.black.withAlpha(180), blurRadius: 8)
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Mumbai, India', // This should probably be dynamic
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF59E0B), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_heroImages.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _heroImages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _heroIndex == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _heroIndex == i
                              ? Colors.white
                              : Colors.white.withAlpha(120),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroPill(
      IconData icon, String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _heroFallback() {
    return Stack(fit: StackFit.expand, children: [
      DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1D4ED8), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      Center(
        child:
            Icon(Icons.hotel_rounded, size: 90, color: Colors.white.withAlpha(60)),
      ),
      Positioned(
        left: 20,
        right: 20,
        bottom: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.hotelName,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star_rounded,
                color: Color(0xFFF59E0B), size: 16),
            const SizedBox(width: 4),
            Text('4.8 Rating',
                style:
                    GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          ]),
        ]),
      ),
    ]);
  }

  // ── Hotel name card ──────────────────────────────────────────────────────

  Widget _buildHotelNameCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF14B8A6)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hotel_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.hotelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF1E293B))),
                Text('Premium Hotel & Resort',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const Icon(Icons.star_rounded,
                  color: Color(0xFFF59E0B), size: 16),
              const SizedBox(width: 3),
              Text('4.8',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ]),
            Text('Excellent',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: const Color(0xFF10B981))),
          ]),
        ],
      ),
    );
  }

  // ── Amenities strip ──────────────────────────────────────────────────────

  Widget _buildAmenitiesRow(bool isDark) {
    const amenities = [
      (Icons.wifi_rounded, 'Free WiFi'),
      (Icons.pool_rounded, 'Pool'),
      (Icons.restaurant_rounded, 'Restaurant'),
      (Icons.local_parking_rounded, 'Parking'),
      (Icons.ac_unit_rounded, 'A/C'),
    ];
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        itemCount: amenities.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (icon, label) = amenities[i];
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF334155))),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Room card ─────────────────────────────────────────────────────────────
  // Horizontal layout: 120px image thumbnail (left) | room info (right)

  Widget _buildRoomCard(RoomModel room, bool isDark) {
    final hasImages = room.images.isNotEmpty;
    final isUrgent = room.availableRooms > 0 && room.availableRooms <= 3;
    final isSoldOut = room.availableRooms == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top: thumbnail + info ─────────────────────────────────
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Thumbnail (120px wide, stretches to match info height)
                SizedBox(
                  width: 120,
                  child: hasImages
                      ? _RoomThumbnail(images: room.images)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2563EB).withAlpha(200),
                                const Color(0xFF14B8A6).withAlpha(200),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.king_bed_rounded,
                                size: 40,
                                color: Colors.white.withAlpha(210)),
                          ),
                        ),
                ),
                // Info panel
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Room name + price in a row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                room.roomtype,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${room.price.toStringAsFixed(0)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                Text('per night',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Feature chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _chip(Icons.people_rounded,
                                '${room.capacity ?? 2} Guests', isDark),
                            _chip(Icons.king_bed_rounded, 'King Bed', isDark),
                            _chip(Icons.wifi_rounded, 'WiFi', isDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────
          Divider(
            color: isDark ? Colors.white12 : const Color(0xFFE8EDF2),
            height: 1,
          ),

          // ── Bottom: availability + book button ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSoldOut
                        ? Colors.red.withAlpha(18)
                        : isUrgent
                            ? Colors.orange.withAlpha(18)
                            : const Color(0xFF10B981).withAlpha(18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSoldOut
                              ? Colors.red
                              : isUrgent
                                  ? Colors.orange
                                  : const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSoldOut
                            ? 'Sold Out'
                            : isUrgent
                                ? 'Only ${room.availableRooms} left!'
                                : '${room.availableRooms} available',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSoldOut
                              ? Colors.red
                              : isUrgent
                                  ? Colors.orange
                                  : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: !isSoldOut ? () => _bookRoom(room) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isSoldOut
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF14B8A6)]),
                      color:
                          isSoldOut ? const Color(0xFFE2E8F0) : null,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isSoldOut
                          ? []
                          : [
                              BoxShadow(
                                  color:
                                      const Color(0xFF2563EB).withAlpha(70),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ],
                    ),
                    child: Text(
                      isSoldOut ? 'Unavailable' : 'Book Now',
                      style: GoogleFonts.poppins(
                          color: isSoldOut
                              ? const Color(0xFF94A3B8)
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
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

  Widget _chip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(15)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF2563EB)),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white70
                      : const Color(0xFF475569))),
        ],
      ),
    );
  }
}

// ── Room thumbnail slider (vertical swipe to see more images) ───────────────

class _RoomThumbnail extends StatefulWidget {
  final List<String> images;
  const _RoomThumbnail({required this.images});

  @override
  State<_RoomThumbnail> createState() => _RoomThumbnailState();
}

class _RoomThumbnailState extends State<_RoomThumbnail> {
  final PageController _ctrl = PageController();
  int _index = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openFullscreenGallery(context, widget.images, initialIndex: _index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _ctrl,
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            allowImplicitScrolling: true,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.images.length,
            itemBuilder: (_, i) => Base64Image(
              base64String: widget.images[i],
              fit: BoxFit.cover,
              cacheWidth: 200, // Small cache for thumbnails
            ),
          ),
          // Counter badge
          if (widget.images.length > 1)
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_index + 1}/${widget.images.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
