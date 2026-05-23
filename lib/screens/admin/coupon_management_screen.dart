import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/coupon_model.dart';
import '../../services/coupon_service.dart';
import '../../services/auth_service.dart';
import 'add_edit_coupon_screen.dart';

class CouponManagementScreen extends StatefulWidget {
  final String roleView; // admin, owner, agent

  const CouponManagementScreen({super.key, required this.roleView});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  List<CouponModel> _coupons = [];
  bool _isLoading = true;
  int _userid = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndCoupons();
  }

  Future<void> _loadUserAndCoupons() async {
    final prefs = await SharedPreferences.getInstance();
    _userid = prefs.getInt('userid') ?? 0;
    _fetchCoupons();
  }

  Future<void> _fetchCoupons() async {
    setState(() => _isLoading = true);
    final coupons = await couponService.getCoupons(
      userId: _userid,
      roleView: widget.roleView,
    );
    setState(() {
      _coupons = coupons;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).cardColor;
    final ink = isDark ? Colors.white : const Color(0xFF172033);
    final muted = isDark ? Colors.white70 : const Color(0xFF64748B);
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Coupons',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _fetchCoupons,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditCouponScreen(
                roleView: widget.roleView,
                userid: _userid,
              ),
            ),
          );
          if (result == true) _fetchCoupons();
        },
        label: const Text('Add Coupon'),
        icon: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined, size: 64, color: muted),
                      const SizedBox(height: 16),
                      Text(
                        'No coupons found',
                        style: GoogleFonts.poppins(fontSize: 18, color: muted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = _coupons[index];
                    return _buildCouponCard(coupon, primary, surface, ink, muted);
                  },
                ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon, Color primary, Color surface, Color ink, Color muted) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    coupon.couponcode,
                    style: GoogleFonts.poppins(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                _buildStatusBadge(coupon.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              coupon.title ?? 'No Title',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            if (coupon.description != null) ...[
              const SizedBox(height: 4),
              Text(
                coupon.description!,
                style: GoogleFonts.poppins(color: muted, fontSize: 14),
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                _buildInfoItem(Icons.sell_outlined, '${coupon.discounttype == 'PERCENT' ? '${coupon.discountvalue}%' : '₹${coupon.discountvalue}'} OFF', muted),
                const SizedBox(width: 20),
                _buildInfoItem(Icons.category_outlined, coupon.serviceType.toUpperCase(), muted),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoItem(Icons.event_available_outlined, coupon.expirydate ?? 'No Expiry', muted),
                const SizedBox(width: 20),
                _buildInfoItem(Icons.group_outlined, 'Used: ${coupon.usedCount}/${coupon.usageLimit == 0 ? '∞' : coupon.usageLimit}', muted),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditCouponScreen(
                          roleView: widget.roleView,
                          userid: _userid,
                          coupon: coupon,
                        ),
                      ),
                    );
                    if (result == true) _fetchCoupons();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(coupon),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(color: color, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(CouponModel coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Coupon'),
        content: Text('Are you sure you want to delete coupon "${coupon.couponcode}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await couponService.deleteCoupon(coupon.couponid, _userid);
      if (success) {
        _fetchCoupons();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete coupon')),
        );
      }
    }
  }
}
