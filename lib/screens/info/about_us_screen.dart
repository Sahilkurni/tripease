import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_footer.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About Us',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      backgroundColor: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.flight_takeoff,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to TripEase',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your trusted partner for seamless travel experiences across the globe.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Our Mission', isDark),
                  _buildSectionText(
                    'At TripEase, our mission is to make travel accessible, enjoyable, and stress-free for everyone. We believe that exploring new places should be exciting, not exhausting. That\'s why we\'ve built a comprehensive platform that brings together the best deals on flights, hotels, buses, and curated holiday packages.',
                    isDark,
                  ),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('What We Offer', isDark),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.hotel_rounded,
                    title: 'Premium Hotels',
                    description: 'From luxury resorts to cozy boutique stays, find the perfect accommodation for your trip with verified reviews and competitive prices.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.directions_bus_rounded,
                    title: 'Comfortable Buses',
                    description: 'Travel inter-city with ease. Choose from a wide range of A/C, non-A/C, and sleeper buses to fit your budget and comfort needs.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.flight_rounded,
                    title: 'Affordable Flights',
                    description: 'Book domestic and international flights at the best rates. Compare airlines and choose the most convenient schedules.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.card_travel_rounded,
                    title: 'Curated Packages',
                    description: 'Discover our specially designed holiday packages that bundle travel, stay, and sightseeing for a hassle-free vacation.',
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Why Choose Us?', isDark),
                  _buildSectionText(
                    'TripEase is built on a foundation of trust, transparency, and technology. We provide an intuitive user interface, secure payment gateways, and 24/7 customer support to ensure your bookings are seamless. Our platform continuously evolves to offer you the most modern and personalized travel booking experience.',
                    isDark,
                  ),
                ],
              ),
            ),
            
            // Footer
            const CustomFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
        height: 1.6,
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
