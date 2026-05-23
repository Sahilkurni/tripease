import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/offer_model.dart';
import '../services/offer_service.dart';
import '../services/auth_service.dart';
import '../widgets/base64_image.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  List<OfferModel> _offers = [];
  bool _isLoading = true;
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9, initialPage: 0);
    _loadOffers();
  }

  Future<void> _loadOffers() async {
    final user = authService.currentUser;
    final list = await offerService.getOffers(
      userId: int.tryParse(user?.userid ?? '0') ?? 0,
      roleView: 'customer',
    );

    if (mounted) {
      setState(() {
        _offers = list.where((o) => o.status == 'approved' && o.isactive == 1).toList();
        _isLoading = false;
      });
      if (_offers.isNotEmpty) {
        _startAutoScroll();
      }
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _offers.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _isLoading ? _buildLoading() : _buildPager(),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trending Offers',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Handpicked deals just for you',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () {},
            child: const Text('See All'),
          ),
        ],
      ),
    );
  }

  Widget _buildPager() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _offers.length,
      onPageChanged: (i) => _currentPage = i,
      itemBuilder: (context, index) => _buildOfferCard(_offers[index]),
    );
  }

  Widget _buildOfferCard(OfferModel offer) {
    final hasImage = offer.primaryImage != null && offer.primaryImage!.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleOfferClick(offer),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Positioned.fill(child: _buildBackground(offer)),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.black.withAlpha(180),
                            Colors.black.withAlpha(20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildContent(offer),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground(OfferModel offer) {
    if (offer.primaryImage != null && offer.primaryImage!.isNotEmpty) {
      return Base64Image(
        base64String: offer.primaryImage!,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    // Fallback Gradients
    final List<Color> colors;
    switch (offer.serviceType.toLowerCase()) {
      case 'hotel':
        colors = [const Color(0xFFF97316), const Color(0xFFEA580C)];
        break;
      case 'bus':
        colors = [const Color(0xFF2563EB), const Color(0xFF1E40AF)];
        break;
      case 'flight':
        colors = [const Color(0xFF6366F1), const Color(0xFF4338CA)];
        break;
      case 'package':
        colors = [const Color(0xFF10B981), const Color(0xFF047857)];
        break;
      default:
        colors = [const Color(0xFFF59E0B), const Color(0xFFB45309)];
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Opacity(
        opacity: 0.1,
        child: Center(
          child: Icon(
            _getServiceIcon(offer.serviceType),
            size: 150,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(OfferModel offer) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white30),
            ),
            child: Text(
              offer.serviceType.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            offer.title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (offer.description != null && offer.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                offer.description!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withAlpha(200),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _handleOfferClick(offer),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              'Book Now',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel': return Icons.hotel_rounded;
      case 'bus': return Icons.directions_bus_rounded;
      case 'flight': return Icons.flight_takeoff_rounded;
      case 'package': return Icons.tour_rounded;
      default: return Icons.local_offer_rounded;
    }
  }

  void _handleOfferClick(OfferModel offer) {
    if (offer.serviceId == null || offer.serviceId == 0) return;
    
    switch (offer.serviceType.toLowerCase()) {
      case 'hotel':
        context.push('/hotel_detail', extra: offer.serviceId.toString());
        break;
      case 'bus':
        // Bus search logic usually needs more params, but we can deep link if API supports it
        break;
      case 'package':
        context.push('/package_detail', extra: offer.serviceId.toString());
        break;
    }
  }

  Widget _buildLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 2,
      itemBuilder: (_, __) => Container(
        width: MediaQuery.of(context).size.width * 0.85,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
