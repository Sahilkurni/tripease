import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/custom_footer.dart';

class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Refund Policy',
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
                    'Cancellation & Refund Policy',
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
                    _buildSection('1. General Cancellation Rules', 
                      'TripEase acts as an intermediary between you and the travel service providers (Airlines, Hotels, Bus Operators). The cancellation and refund rules of the respective service providers apply to all bookings made through TripEase.', isDark),
                    _buildSection('2. Flight Bookings', 
                      'Flight cancellations are subject to the airline\'s specific fare rules. Convenience fees paid to TripEase at the time of booking are non-refundable. Refunds will be processed to the original payment method within 7-10 working days after receiving the refund from the airline.', isDark),
                    _buildSection('3. Hotel Bookings', 
                      'Hotel cancellation policies vary by property and room type. Some bookings are strictly non-refundable. If you cancel a refundable booking within the permitted window, the refund will be processed within 5-7 working days. No-shows are generally non-refundable.', isDark),
                    _buildSection('4. Bus Bookings', 
                      'Bus ticket cancellations must be made at least 4 hours before the departure time to be eligible for a partial refund. Cancellation charges vary based on the time of cancellation before departure. Please check the specific bus operator\'s policy at the time of booking.', isDark),
                    _buildSection('5. Holiday Packages', 
                      'Package cancellations are subject to strict timelines. Cancellations made 30 days prior to the travel date may incur a 20% cancellation fee. Cancellations within 15 days of travel are typically non-refundable. Customized packages may have different cancellation terms.', isDark),
                    _buildSection('6. Refund Processing', 
                      'Once a cancellation is confirmed and eligible for a refund, the amount will be credited back to the original mode of payment (Credit Card, Debit Card, Net Banking, UPI) within 5 to 10 business days.', isDark),
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
