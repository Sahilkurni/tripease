import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard_screen.dart';

class ServiceCard extends StatelessWidget {
  final ServiceItem item;
  final VoidCallback onTap;

  const ServiceCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: item.gradient[0].withAlpha((0.35 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.20 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: Colors.white, size: 22),
            ),
            const Spacer(),
            Text(
              item.label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              item.subtitle,
              style: GoogleFonts.poppins(
                color: Colors.white.withAlpha((0.75 * 255).round()),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
