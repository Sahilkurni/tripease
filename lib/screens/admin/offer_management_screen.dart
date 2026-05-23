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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer.primaryImage != null)
            Image.memory(
              base64Decode(offer.primaryImage!),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              color: primary.withOpacity(0.05),
              child: Icon(Icons.image_outlined, size: 40, color: primary.withOpacity(0.3)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(offer.status),
                    Text(
                      offer.serviceType.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  offer.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                if (offer.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    offer.description!,
                    style: GoogleFonts.poppins(color: muted, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(Icons.date_range_outlined, size: 14, color: muted),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.validFrom ?? 'Start'} to ${offer.validTo ?? 'End'}',
                      style: GoogleFonts.poppins(color: muted, fontSize: 12),
                    ),
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
                            builder: (context) => AddEditOfferScreen(
                              roleView: widget.roleView,
                              userid: _userid,
                              offer: offer,
                            ),
                          ),
                        );
                        if (result == true) _fetchOffers();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(offer),
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
