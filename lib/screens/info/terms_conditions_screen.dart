import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_footer.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms & Conditions',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              color: isDark ? AppColors.darkCard : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms of Service',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last updated: ${DateTime.now().year}-05-10',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('1. Agreement to Terms', 
                      'These Terms of Use constitute a legally binding agreement made between you and TripEase, concerning your access to and use of the TripEase application and website. You agree that by accessing the Services, you have read, understood, and agreed to be bound by all of these Terms of Use.', isDark),
                    _buildSection('2. Booking and Payments', 
                      'By booking through our platform, you agree to pay the specified amount, including any applicable taxes and fees. TripEase uses secure third-party payment gateways. We do not store your credit card details.', isDark),
                    _buildSection('3. Role of TripEase', 
                      'TripEase acts solely as an aggregator and intermediary between users and third-party travel service providers (hotels, airlines, bus operators). We are not responsible for the actual provision of the travel services or any deficiencies therein.', isDark),
                    _buildSection('4. User Responsibilities', 
                      'You are responsible for ensuring that all details provided during the booking process are accurate. You must ensure you have the necessary valid travel documents (ID proofs, visas, passports) as required by the service providers or authorities.', isDark),
                    _buildSection('5. Intellectual Property Rights', 
                      'Unless otherwise indicated, the Services are our proprietary property and all source code, databases, functionality, software, website designs, audio, video, text, photographs, and graphics on the Services (collectively, the “Content”) are owned or controlled by us.', isDark),
                    _buildSection('6. Modifications to Terms', 
                      'We reserve the right, in our sole discretion, to make changes or modifications to these Terms of Use at any time and for any reason. We will alert you about any changes by updating the "Last updated" date of these Terms of Use.', isDark),
                  ],
                ),
              ),
            ),
            
            // Footer
            const CustomFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
