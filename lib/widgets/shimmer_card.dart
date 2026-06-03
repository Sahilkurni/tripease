import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer loading placeholder that mirrors a card shape.
/// Shows a rounded rectangle with fake image + title + subtitle bars.
class ShimmerCard extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.width,
    this.height = 220,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E293B) : Colors.grey.shade300;
    final highlight = isDark ? const Color(0xFF334155) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fake image
            Container(
              height: height! * 0.55,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius),
                  topRight: Radius.circular(borderRadius),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fake title bar
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Fake subtitle bar (shorter)
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        height: 10,
                        width: 60,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 10,
                        width: 50,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal row of shimmer cards for list loading states.
class ShimmerCardRow extends StatelessWidget {
  final int count;
  final double cardWidth;
  final double cardHeight;

  const ShimmerCardRow({
    super.key,
    this.count = 3,
    this.cardWidth = 200,
    this.cardHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (_, __) => ShimmerCard(
          width: cardWidth,
          height: cardHeight,
        ),
      ),
    );
  }
}

/// A full-width shimmer list item placeholder.
class ShimmerListItem extends StatelessWidget {
  const ShimmerListItem({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1E293B) : Colors.grey.shade300;
    final highlight = isDark ? const Color(0xFF334155) : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 14,
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(7))),
                  const SizedBox(height: 8),
                  Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 8),
                  Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
