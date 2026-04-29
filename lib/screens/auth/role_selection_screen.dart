import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  final UserModel user;
  const RoleSelectionScreen({super.key, required this.user});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _loading = false;

  void _submit() async {
    if (_selectedRole == null) return;
    setState(() => _loading = true);

    final result = await authService.updateRole(
      widget.user.userid,
      _selectedRole!,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      final roleName = result['rolename'];
      if (roleName == 'CUSTOMER') {
        context.go('/home');
      } else if (roleName == 'HOTEL_OWNER') {
        context.go('/hotel_dashboard');
      } else if (roleName == 'TRAVEL_AGENT') {
        context.go('/agent_dashboard');
      } else {
        context.go('/home');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to set role'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      appBar: AppBar(
        title: Text(
          'Choose Your Role',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome ${widget.user.name.split(' ')[0]}!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'How would you like to use TripEase?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                _RoleCard(
                  title: 'Explorer',
                  subtitle: 'Book flights, hotels, and buses.',
                  icon: Icons.explore_rounded,
                  value: '1',
                  groupValue: _selectedRole,
                  onChanged: (v) => setState(() => _selectedRole = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _RoleCard(
                  title: 'Hotel Property Owner',
                  subtitle: 'List and manage your hotel rooms.',
                  icon: Icons.hotel_rounded,
                  value: '2',
                  groupValue: _selectedRole,
                  onChanged: (v) => setState(() => _selectedRole = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                _RoleCard(
                  title: 'Travel Agent',
                  subtitle: 'Manage bookings for your clients.',
                  icon: Icons.card_travel_rounded,
                  value: '3',
                  groupValue: _selectedRole,
                  onChanged: (v) => setState(() => _selectedRole = v),
                  isDark: isDark,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        (_selectedRole != null && !_loading) ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _loading
                            ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                            : Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                selected
                    ? AppColors.primary
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: AppColors.primary.withAlpha((0.15 * 255).round()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    selected
                        ? AppColors.primary.withAlpha((0.1 * 255).round())
                        : (isDark ? Colors.white10 : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    selected
                        ? AppColors.primary
                        : (isDark ? Colors.white : Colors.black87),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
