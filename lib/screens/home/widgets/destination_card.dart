import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard_screen.dart';

class DestinationCard extends StatelessWidget {
  final DestinationItem item;
  final VoidCallback onTap;

  const DestinationCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background image
            Image.network(
              item.imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder:
                  (_, __, ___) => Container(
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
                            color: const Color(0xFFE2E8F0),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha((0.60 * 255).round()),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Text at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.country,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withAlpha((0.75 * 255).round()),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // Wishlist icon at top right
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  // TODO: add to wishlist via WishlistService
                },
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha((0.25 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_border_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
