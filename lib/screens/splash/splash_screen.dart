import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await authService.initSession();
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    if (authService.currentUser != null) {
      final role = authService.currentUser!.rolename;
      final r = role?.toUpperCase().trim();
      debugPrint(
        'Splash found session roleid=${authService.currentUser!.roleid} rolename=$role (normalized=$r)',
      );
      if (r == 'CUSTOMER') {
        context.go('/home');
      } else if (r == 'HOTEL_PARTNER' || r == 'HOTEL_OWNER') {
        context.go('/hotel_dashboard');
      } else if (r == 'AGENT' || r == 'TRAVEL_AGENT') {
        context.go('/agent_dashboard');
      } else if (r == 'BUS_PARTNER' || r == 'BUS_OWNER') {
        // Map bus partner roles to the agent dashboard for now
        context.go('/agent_dashboard');
      } else if (r == 'ADMIN') {
        context.go('/admin_dashboard');
      } else {
        context.go('/home');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.travel_explore, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'TripEase',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Book. Pack. Go.',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
