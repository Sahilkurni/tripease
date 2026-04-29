import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeaderWidget extends StatelessWidget {
  final String userName;
  final String location;

  const HomeHeaderWidget({
    super.key,
    required this.userName,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW >= 1024;
    final isTablet = screenW >= 600 && screenW < 1024;
    final hPad =
        isDesktop
            ? 48.0
            : isTablet
            ? 32.0
            : 20.0;

    // Responsive header height
    final headerHeight =
        isDesktop
            ? 280.0
            : isTablet
            ? 240.0
            : 200.0;

    final safeTop = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      height: headerHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Subtle bokeh effect circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((0.05 * 255).round()),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((0.07 * 255).round()),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: screenW * 0.4,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withAlpha((0.12 * 255).round()),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              safeTop + 16,
              hPad,
              48,
            ), // Bottom padding for overlap
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  children: [
                    const Icon(
                      Icons.travel_explore,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'TripEase',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // TODO: Open notifications screen
                          },
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Hello, $userName 👋',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withAlpha((0.80 * 255).round()),
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Where do you want',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'to go today?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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
}
