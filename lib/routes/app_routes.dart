import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/home/hotel_owner_dashboard.dart';
import '../screens/home/agent_dashboard.dart';
import '../screens/home/admin_dashboard.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/hotels/hotel_list_screen.dart';
import '../screens/hotels/hotel_detail_screen.dart';
import '../screens/bus/bus_search_screen.dart';
import '../screens/bus/bus_list_screen.dart';
import '../screens/bus/seat_layout_screen.dart';
import '../screens/bus/passenger_details_screen.dart';
import '../models/bus_model.dart';
import '../models/user_model.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/role_selection',
      builder: (context, state) {
        final maybeUser = state.extra;
        if (maybeUser is UserModel) {
          return RoleSelectionScreen(user: maybeUser);
        }
        // If no user provided, redirect to login screen
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: '/hotel_dashboard',
      builder: (context, state) => const HotelOwnerDashboard(),
    ),
    GoRoute(
      path: '/agent_dashboard',
      builder: (context, state) => const AgentDashboard(),
    ),
    GoRoute(
      path: '/admin_dashboard',
      builder: (context, state) => const AdminDashboard(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/hotels',
      builder: (context, state) => const HotelListScreen(),
    ),
    GoRoute(
      path: '/hotel_detail',
      builder: (context, state) => const HotelDetailScreen(),
    ),
    GoRoute(
      path: '/bus_search',
      builder: (context, state) => const BusSearchScreen(),
    ),
    GoRoute(
      path: '/bus_list',
      builder: (context, state) {
        final Map<String, dynamic>? args = state.extra as Map<String, dynamic>?;
        return BusListScreen(
          source: args?['source'] ?? 'Source',
          destination: args?['destination'] ?? 'Destination',
        );
      },
    ),
    GoRoute(
      path: '/seat_layout',
      builder: (context, state) {
        final maybeBus = state.extra;
        if (maybeBus is BusModel) {
          return SeatLayoutScreen(bus: maybeBus);
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Seat Layout')),
          body: const Center(child: Text('Bus data not provided.')),
        );
      },
    ),
    GoRoute(
      path: '/passenger_details',
      builder: (context, state) {
        final args = state.extra;
        if (args is Map<String, dynamic> &&
            args['bus'] is BusModel &&
            args['seats'] is List<String>) {
          final bus = args['bus'] as BusModel;
          final seats = args['seats'] as List<String>;
          return PassengerDetailsScreen(bus: bus, seats: seats);
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Passenger Details')),
          body: const Center(child: Text('Required booking data missing.')),
        );
      },
    ),
  ],
);
