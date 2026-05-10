import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeaderWidget extends StatelessWidget {
  final String userName;
  final String location;
  final VoidCallback? onRefresh;
  final VoidCallback? onMapOpen;

  const HomeHeaderWidget({
    super.key,
    required this.userName,
    required this.location,
    this.onRefresh,
    this.onMapOpen,
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF2563EB), Color(0xFFDB2777)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: safeTop + 68,
            right: isDesktop ? 170 : 36,
            child: Transform.rotate(
              angle: -0.42,
              child: Icon(
                Icons.flight_takeoff_rounded,
                color: Colors.white.withAlpha(42),
                size: isDesktop ? 92 : 58,
              ),
            ),
          ),
          Positioned(
            bottom: 38,
            right: isDesktop ? 310 : 110,
            child: Icon(
              Icons.location_on_rounded,
              color: Colors.white.withAlpha(38),
              size: isDesktop ? 52 : 36,
            ),
          ),
          Positioned(
            top: safeTop + 38,
            right: -18,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: Colors.white.withAlpha((0.05 * 255).round()),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -10,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.white.withAlpha((0.07 * 255).round()),
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: screenW * 0.4,
            child: Container(
              width: 72,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withAlpha((0.09 * 255).round()),
              ),
            ),
          ),

          // Main content
          Padding(
            padding: EdgeInsets.fromLTRB(
              hPad,
              safeTop + 16,
              hPad,
              12, // Reduced bottom padding
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(), // Prevent manual scroll but allows content to fit
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                            onPressed: () {},
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
                      GestureDetector(
                        onTap: onRefresh,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white54,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onMapOpen,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.map_outlined, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Explore Map',
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
