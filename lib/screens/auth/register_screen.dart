import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/role_constants.dart';
import '../../core/utils/responsive.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../core/utils/validators.dart';
import '../../widgets/otp_verification_dialog.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl =
      TextEditingController(); // mobile isn't in API yet but kept for UI
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _selectedRole = RoleConstants.customer.toString();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _redirectByRole({String? roleId, String? roleName}) {
    context.go(routeByRole(roleId: roleId, roleName: roleName));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();

    // 1. Send OTP first
    final otpResult = await authService.sendOtp(email);

    if (!mounted) return;
    setState(() => _loading = false);

    if (otpResult['success'] == true) {
      // 2. Show OTP Verification Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpVerificationDialog(
          email: email,
          onSuccess: () async {
            // 3. Proceed with actual registration on success
            setState(() => _loading = true);
            final result = await authService.register(
              _nameCtrl.text.trim(),
              email,
              _passCtrl.text,
              _selectedRole!,
            );

            if (!mounted) return;
            setState(() => _loading = false);

            if (result['success']) {
              final user = result['user'];
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registration successful!')),
              );
              _redirectByRole(roleId: user.roleid, roleName: user.rolename);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Registration failed'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      );
    } else {
      // Failed to send OTP
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpResult['message'] ?? 'Failed to send OTP email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final safeBot = MediaQuery.of(context).padding.bottom;
    final illustH = math.min(180.0, size.height * 0.25);

    if (size.width >= 900) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/img2.jpg',
                      height: double.infinity,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Icon(
                            Icons.travel_explore,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'TripEase',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color:
                                  isDark ? Colors.white : AppColors.lightText,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.light_mode : Icons.dark_mode,
                              color:
                                  isDark ? Colors.white : AppColors.lightText,
                              size: 20,
                            ),
                            onPressed:
                                () =>
                                    themeNotifier.value =
                                        isDark
                                            ? ThemeMode.light
                                            : ThemeMode.dark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                  child: _buildForm(context, isDark),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/img2.jpg',
                  height: illustH,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Icon(
                        Icons.travel_explore,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'TripEase',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isDark ? Colors.white : AppColors.lightText,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isDark ? Colors.white : AppColors.lightText,
                          size: 20,
                        ),
                        onPressed:
                            () =>
                                themeNotifier.value =
                                    isDark ? ThemeMode.light : ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).round()),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                R.isMobile(context) ? 24 : 40,
                28,
                R.isMobile(context) ? 24 : 40,
                safeBot + 24,
              ),
              child: _buildForm(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Account',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: R.fontSize(context, 24, tablet: 28),
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start your journey with us',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded),
              hintText: 'Full Name',
            ),
            validator:
                (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'Email Address',
            ),
            validator: Validators.validateEmail,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _mobileCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_outlined),
              hintText: 'Mobile Number',
            ),
            validator: Validators.validatePhone,
          ),

          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.work_outline_rounded),
              hintText: 'Select Role',
            ),
            items: const [
              DropdownMenuItem(
                value: '${RoleConstants.customer}',
                child: Text('Explorer (Customer)'),
              ),
              DropdownMenuItem(
                value: '${RoleConstants.hotelOwner}',
                child: Text('Hotel Property Owner'),
              ),
              DropdownMenuItem(
                value: '${RoleConstants.travelAgent}',
                child: Text('Travel Agent'),
              ),
            ],
            onChanged: (v) => setState(() => _selectedRole = v),
            validator: (v) => v == null ? 'Please select a role' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator:
                (v) => (v != null && v.length < 6) ? 'Min 6 chars' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscure,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_reset_rounded),
              hintText: 'Confirm Password',
            ),
            validator:
                (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _register,
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
                        'Create Account',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account?  ',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
