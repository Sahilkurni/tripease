import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../dashboard_screen.dart';

class RecommendedCard extends StatelessWidget {
  final RecommendedItem item;
  final VoidCallback onTap;

  const RecommendedCard({super.key, required this.item, required this.onTap});

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return const Color(0xFF2563EB);
      case 'bus':
        return const Color(0xFF059669);
      case 'package':
        return const Color(0xFFDB2777);
      default:
        return const Color(0xFF7C3AED);
    }
  }

  String _formatPrice(double p) {
    if (p >= 1000) {
      return '${(p / 1000).toStringAsFixed(1)}k';
    }
    return p.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    item.imageUrl.trim().isEmpty
                        ? Container(
                          width: 90,
                          height: 90,
                          color: _typeColor(item.type).withAlpha(35),
                          child: Icon(
                            item.type == 'package'
                                ? Icons.card_travel_rounded
                                : Icons.hotel_rounded,
                            color: _typeColor(item.type),
                          ),
                        )
                        : Image.network(
                          item.imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 90,
                                height: 90,
                                color: const Color(0xFF1E3A5F),
                                child: const Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white38,
                                ),
                              ),
                          loadingBuilder:
                              (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : Container(
                                        width: 90,
                                        height: 90,
                                        color: const Color(0xFFE2E8F0),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      ),
                        ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Type badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _typeColor(
                          item.type,
                        ).withAlpha((0.12 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _typeColor(item.type),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            item.location,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color:
                                  isDark
                                      ? AppColors.darkSubtext
                                      : AppColors.lightSubtext,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppColors.darkText
                                    : AppColors.lightText,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            item.price > 0
                                ? '₹${_formatPrice(item.price)}'
                                : 'View',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Book button
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(56, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Book',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
