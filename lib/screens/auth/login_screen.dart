import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/role_constants.dart';
import '../../core/utils/responsive.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _redirectByRole({String? roleId, String? roleName}) {
    context.go(routeByRole(roleId: roleId, roleName: roleName));
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final result = await authService.login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success']) {
      final user = result['user'];
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful!')));
      // Show role briefly for debugging (remove in production)
      debugPrint(
        'Logged in user roleid=${user.roleid} rolename=${user.rolename}',
      );
      _redirectByRole(roleId: user.roleid, roleName: user.rolename);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _googleLoading = true);

    final googleUser = await GoogleAuthService.signInWithGoogle();
    if (googleUser == null) {
      setState(() => _googleLoading = false);
      return;
    }

    final result = await authService.googleSync(
      googleUser.email ?? '',
      googleUser.displayName ?? 'Google User',
      googleUser.photoURL ?? '',
      googleUser.uid,
    );

    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result['success']) {
      if (result['is_new_user'] == true) {
        context.push('/role_selection', extra: result['user']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Login successful!')),
        );
        _redirectByRole(
          roleId: result['user'].roleid,
          roleName: result['user'].rolename,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Google sync failed'),
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
    final illustH = math.min(
      180.0,
      MediaQuery.of(context).size.height * 0.35,
    ); // Approx responsive

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
                      'assets/img1.jpg',
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
                            onPressed: () {
                              themeNotifier.value =
                                  isDark ? ThemeMode.light : ThemeMode.dark;
                            },
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
                  'assets/img1.jpg',
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
                        onPressed: () {
                          themeNotifier.value =
                              isDark ? ThemeMode.light : ThemeMode.dark;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: size.height - illustH),
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
            'Welcome Back!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: R.fontSize(context, 24, tablet: 28),
              color: isDark ? AppColors.darkText : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Login to continue your journey',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline_rounded),
              hintText: 'Email',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter email';
              return null;
            },
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
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter password';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? false),
              ),
              Text(
                'Remember me',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
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
                        'Login',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Or continue with',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _googleLoading ? null : _loginWithGoogle,
                  icon:
                      _googleLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          )
                          : const Icon(
                            Icons.g_mobiledata_rounded,
                            color: AppColors.google,
                            size: 28,
                          ),
                  label: Text(
                    'Google',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: BorderSide(
                      color:
                          isDark
                              ? AppColors.darkInputBorder.withAlpha(
                                (0.3 * 255).round(),
                              )
                              : AppColors.lightInputBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () => context.push('/register'),
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account?  ",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color:
                        isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign up',
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
