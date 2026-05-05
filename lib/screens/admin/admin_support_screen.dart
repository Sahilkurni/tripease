import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Tickets',
            style: GoogleFonts.poppins(
              color: const Color(0xFF0F172A),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }
}
