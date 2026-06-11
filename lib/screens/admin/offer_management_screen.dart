import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/offer_model.dart';
import '../../services/offer_service.dart';
import 'add_edit_offer_screen.dart';
import 'dart:convert';

class OfferManagementScreen extends StatefulWidget {
  final String roleView;

  const OfferManagementScreen({super.key, required this.roleView});

  @override
  State<OfferManagementScreen> createState() => _OfferManagementScreenState();
}

class _OfferManagementScreenState extends State<OfferManagementScreen> {
  List<OfferModel> _offers = [];
  bool _isLoading = true;
  int _userid = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndOffers();
  }

  Future<void> _loadUserAndOffers() async {
    final prefs = await SharedPreferences.getInstance();
    _userid = prefs.getInt('userid') ?? 0;
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() => _isLoading = true);
    final offers = await offerService.getOffers(
      userId: _userid,
      roleView: widget.roleView,
    );
    setState(() {
      _offers = offers;
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
          'Manage Offers',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(onPressed: _fetchOffers, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditOfferScreen(
                roleView: widget.roleView,
                userid: _userid,
              ),
            ),
          );
          if (result == true) _fetchOffers();
        },
        label: const Text('Add Offer'),
        icon: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 64, color: muted),
                      const SizedBox(height: 16),
                      Text(
                        'No offers found',
                        style: GoogleFonts.poppins(fontSize: 18, color: muted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    return _buildOfferCard(offer, primary, surface, ink, muted);
                  },
                ),
    );
  }

  Widget _buildOfferCard(OfferModel offer, Color primary, Color surface, Color ink, Color muted) {
    final bool isAdmin = widget.roleView == 'admin';
    final bool isPending = offer.status.toLowerCase() == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: thumbnail + details ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Small image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: offer.primaryImage != null
                      ? Image.memory(
                          base64Decode(offer.primaryImage!),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: primary.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.local_offer_outlined,
                            size: 32,
                            color: primary.withValues(alpha: 0.4),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildStatusBadge(offer.status),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              offer.serviceType.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        offer.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (offer.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          offer.description!,
                          style: GoogleFonts.poppins(color: muted, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.date_range_outlined, size: 12, color: muted),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.validFrom ?? 'Start'} → ${offer.validTo ?? 'End'}',
                            style: GoogleFonts.poppins(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // ── Action buttons row ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Approve / Reject — admin only, pending only
                if (isAdmin && isPending) ...[
                  TextButton.icon(
                    onPressed: () => _approveOffer(offer, 'approved'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                    icon: const Icon(Icons.check_circle_outline, size: 17),
                    label: Text('Approve', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: () => _approveOffer(offer, 'rejected'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                    icon: const Icon(Icons.cancel_outlined, size: 17),
                    label: Text('Reject', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  Container(width: 1, height: 20, color: Theme.of(context).dividerColor),
                  const SizedBox(width: 4),
                ],
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditOfferScreen(
                          roleView: widget.roleView,
                          userid: _userid,
                          offer: offer,
                        ),
                      ),
                    );
                    if (result == true) _fetchOffers();
                  },
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  label: Text('Edit', style: GoogleFonts.poppins(fontSize: 13)),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(offer),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: Text('Delete', style: GoogleFonts.poppins(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveOffer(OfferModel offer, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(newStatus == 'approved' ? 'Approve Offer' : 'Reject Offer'),
        content: Text(
          newStatus == 'approved'
              ? 'Approve "${offer.title}"? It will be visible to customers.'
              : 'Reject "${offer.title}"?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'approved' ? Colors.green : Colors.orange,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              newStatus == 'approved' ? 'Approve' : 'Reject',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await offerService.approveOffer(offer.offerid, _userid, newStatus);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Offer ${newStatus == 'approved' ? 'approved' : 'rejected'} successfully'
            : 'Failed to update offer status'),
        backgroundColor: success
            ? (newStatus == 'approved' ? Colors.green : Colors.orange)
            : Colors.red,
      ),
    );
    if (success) _fetchOffers();
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

  Future<void> _confirmDelete(OfferModel offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offer'),
        content: Text('Are you sure you want to delete offer "${offer.title}"?'),
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
      final success = await offerService.deleteOffer(offer.offerid, _userid);
      if (!mounted) return;
      if (success) {
        _fetchOffers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete offer')),
        );
      }
    }
  }
}
