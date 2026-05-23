import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import '../services/auth_service.dart';

class CouponSelector extends StatefulWidget {
  final String serviceType;
  final int? serviceId;
  final double amount;
  final Function(CouponModel) onSelect;

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
    required Function(CouponModel) onSelect,
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
  List<CouponModel> _coupons = [];
  List<CouponModel> _filteredCoupons = [];
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

    final list = await couponService.getCoupons(
      userId: int.parse(user.userid),
      serviceType: widget.serviceType,
      serviceId: widget.serviceId,
    );

    if (mounted) {
      setState(() {
        _coupons = list.where((c) => c.isValidFor(widget.amount, widget.serviceType, widget.serviceId)).toList();
        _filteredCoupons = _coupons;
        _isLoading = false;
      });
    }
  }

  void _filterCoupons() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredCoupons = _coupons.where((c) => 
        c.couponcode.toLowerCase().contains(query) || 
        (c.title?.toLowerCase().contains(query) ?? false)
      ).toList();
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
                'Available Coupons',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              Text(
                'Select a coupon to save on your booking',
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
          hintText: 'Search coupon code...',
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
    if (_filteredCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'No coupons found',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _filteredCoupons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final coupon = _filteredCoupons[index];
        return _buildCouponCard(coupon, isDark);
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
