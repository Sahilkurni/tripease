import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = MediaQuery.of(context).size.width > 800;

    return Container(
      width: double.infinity,
      color: isDark ? AppColors.darkCard : const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 48,
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(flex: 2, child: _buildBrandSection(context, isDark)),
                const SizedBox(width: 48),
                Expanded(child: _buildLinksColumn(context, isDark, 'Company', [
                  _FooterLink('About Us', '/about'),
                  _FooterLink('Contact Us', '/contact'),
                ])),
                Expanded(child: _buildLinksColumn(context, isDark, 'Services', [
                  _FooterLink('Hotels', '/hotels'),
                  _FooterLink('Buses', '/bus_search'),
                  _FooterLink('Packages', '/packages'),
                  _FooterLink('Flights', '/flights'),
                ])),
                Expanded(child: _buildLinksColumn(context, isDark, 'Legal', [
                  _FooterLink('Privacy Policy', '/privacy'),
                  _FooterLink('Terms & Conditions', '/terms'),
                  _FooterLink('Refund Policy', '/refund'),
                ])),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandSection(context, isDark),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLinksColumn(context, isDark, 'Company', [
                      _FooterLink('About Us', '/about'),
                      _FooterLink('Contact Us', '/contact'),
                    ])),
                    Expanded(child: _buildLinksColumn(context, isDark, 'Services', [
                      _FooterLink('Hotels', '/hotels'),
                      _FooterLink('Buses', '/bus_search'),
                      _FooterLink('Packages', '/packages'),
                      _FooterLink('Flights', '/flights'),
                    ])),
                  ],
                ),
                const SizedBox(height: 32),
                _buildLinksColumn(context, isDark, 'Legal', [
                  _FooterLink('Privacy Policy', '/privacy'),
                  _FooterLink('Terms & Conditions', '/terms'),
                  _FooterLink('Refund Policy', '/refund'),
                ]),
              ],
            ),
    );
  }

  Widget _buildBrandSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Text(
              'TripEase',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Your ultimate travel companion. Book hotels, buses, flights, and curated holiday packages with ease.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _SocialIcon(icon: Icons.facebook, isDark: isDark),
            const SizedBox(width: 12),
            _SocialIcon(icon: Icons.camera_alt, isDark: isDark), // Instagram
            const SizedBox(width: 12),
            _SocialIcon(icon: Icons.alternate_email, isDark: isDark), // Twitter/X
          ],
        ),
        const SizedBox(height: 24),
        Text(
          '© ${DateTime.now().year} TripEase. All rights reserved.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLinksColumn(
      BuildContext context, bool isDark, String title, List<_FooterLink> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  context.push(link.route);
                },
                child: Text(
                  link.label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _FooterLink {
  final String label;
  final String route;
  _FooterLink(this.label, this.route);
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;

  const _SocialIcon({required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
    );
  }
}
