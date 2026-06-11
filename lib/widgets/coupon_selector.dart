import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/coupon_model.dart';
import '../models/offer_model.dart';
import '../services/coupon_service.dart';
import '../services/offer_service.dart';
import '../services/auth_service.dart';

class CouponSelector extends StatefulWidget {
  final String serviceType;
  final int? serviceId;
  final double amount;
  final Function(dynamic) onSelect;

  const CouponSelector({
    super.key,
    required this.serviceType,
    this.serviceId,
    required this.amount,
    required this.onSelect,
  });

  static Future<void> show({
    required BuildContext context,
    required String serviceType,
    int? serviceId,
    required double amount,
    required Function(dynamic) onSelect,
  }) async {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 600),
            child: CouponSelector(
              serviceType: serviceType,
              serviceId: serviceId,
              amount: amount,
              onSelect: (c) {
                Navigator.pop(context);
                onSelect(c);
              },
            ),
          ),
        ),
      );
    } else {
      return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: CouponSelector(
            serviceType: serviceType,
            serviceId: serviceId,
            amount: amount,
            onSelect: (c) {
              Navigator.pop(context);
              onSelect(c);
            },
          ),
        ),
      );
    }
  }

  @override
  State<CouponSelector> createState() => _CouponSelectorState();
}

class _CouponSelectorState extends State<CouponSelector> {
  List<dynamic> _items = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCoupons();
    _searchCtrl.addListener(_filterCoupons);
  }

  Future<void> _loadCoupons() async {
    final user = authService.currentUser;
    if (user == null) return;

    final couponsList = await couponService.getCoupons(
      userId: int.parse(user.userid),
      serviceType: widget.serviceType,
      serviceId: widget.serviceId,
    );

    final offersList = await offerService.getOffers(
      userId: int.parse(user.userid),
      serviceType: widget.serviceType,
      serviceId: widget.serviceId,
    );

    if (mounted) {
      setState(() {
        final validCoupons = couponsList.where((c) => c.isValidFor(widget.amount, widget.serviceType, widget.serviceId)).toList();
        final validOffers = offersList.where((o) => o.isValidFor(widget.amount, widget.serviceType, widget.serviceId)).toList();
        
        _items = [...validCoupons, ...validOffers];
        _filteredItems = _items;
        _isLoading = false;
      });
    }
  }

  void _filterCoupons() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredItems = _items.where((item) {
        if (item is CouponModel) {
          return item.couponcode.toLowerCase().contains(query) || (item.title?.toLowerCase().contains(query) ?? false);
        } else if (item is OfferModel) {
          return item.title.toLowerCase().contains(query);
        }
        return false;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _buildHeader(isDark),
        _buildSearch(isDark),
        Expanded(
          child: _isLoading ? _buildLoading() : _buildList(isDark),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Offers & Coupons',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Select an offer or coupon to save on your booking',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search offers or coupons...',
          prefixIcon: const Icon(Icons.search_rounded),
          filled: true,
          fillColor: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildList(bool isDark) {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'No offers or coupons found',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        if (item is CouponModel) {
          return _buildCouponCard(item, isDark);
        } else if (item is OfferModel) {
          return _buildOfferCard(item, isDark);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildCouponCard(CouponModel coupon, bool isDark) {
    final savings = coupon.calculateSavings(widget.amount);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelect(coupon),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF2563EB).withAlpha(isDark ? 50 : 30),
              width: 2,
            ),
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.white, const Color(0xFFF8FAFC)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_offer_rounded, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coupon.couponcode,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    Text(
                      coupon.title ?? 'Special Discount',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Valid till: ${coupon.expirydate ?? 'Unlimited'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SAVE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '₹${savings.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard(OfferModel offer, bool isDark) {
    final savings = offer.calculateSavings(widget.amount);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelect(offer),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.orange.withAlpha(isDark ? 50 : 30),
              width: 2,
            ),
            gradient: LinearGradient(
              colors: isDark 
                ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                : [Colors.white, const Color(0xFFFFF7ED)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.discount_rounded, color: Colors.orange),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROMO OFFER',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.orange,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      offer.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Valid till: ${offer.validTo ?? 'Unlimited'}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SAVE',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    '₹${savings.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
