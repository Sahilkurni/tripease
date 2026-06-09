import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/home/hotel_owner_dashboard.dart';
import '../screens/home/agent_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/agent/add_edit_package_screen.dart';
import '../screens/hotel_partner/add_edit_hotel_screen.dart';
import '../screens/hotel_partner/manage_rooms_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/hotels/hotel_list_screen.dart';
import '../screens/hotels/hotel_detail_screen.dart';
import '../screens/bus/bus_search_screen.dart';
import '../screens/bus/bus_list_screen.dart';
import '../screens/bus/bus_seat_selection_screen.dart';
import '../screens/bus/passenger_details_screen.dart';
import '../screens/bus_partner/add_edit_bus_screen.dart';
import '../models/bus_model.dart';
import '../models/user_model.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/home/package_list_screen.dart';
import '../screens/hotels/hotel_details_screen.dart';
import '../screens/flights/flight_list_screen.dart';
import '../screens/flights/flight_bookings_screen.dart';
import '../screens/admin/admin_flights_screen.dart';
import '../screens/agent/agent_add_flight_screen.dart';
import '../screens/info/about_us_screen.dart';
import '../screens/info/contact_us_screen.dart';
import '../screens/info/privacy_policy_screen.dart';
import '../screens/info/refund_policy_screen.dart';
import '../screens/info/terms_conditions_screen.dart';
import '../services/auth_service.dart';
import '../core/constants/role_constants.dart';

bool _hasShownSplash = false;

final appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authService,
  redirect: (context, state) {
    if (!_hasShownSplash && state.uri.path != '/') {
      _hasShownSplash = true;
      return '/?target=${Uri.encodeComponent(state.uri.toString())}';
    }
    if (state.uri.path == '/') {
      _hasShownSplash = true;
    }

    final loggedIn = authService.currentUser != null;
    final isLoggingIn =
        state.uri.path == '/login' ||
        state.uri.path == '/register' ||
        state.uri.path == '/onboarding';

    // If not logged in and trying to access protected route, go to login
    // List of protected routes (can be expanded)
    final protectedRoutes = [
      '/home',
      '/hotel_dashboard',

      '/agent_dashboard',
      '/admin_dashboard',
      '/role_selection',
      '/passenger_details',
      '/flight_bookings',
      '/agent_add_flight',
      '/admin_flights',
      '/bookings',
    ];

    final isProtectedRoute =
        protectedRoutes.any((route) => state.uri.path.startsWith(route)) ||
        state.uri.path.startsWith('/owner/') ||
        state.uri.path.startsWith('/agent/');

    if (!loggedIn && isProtectedRoute) {
      return '/login';
    }

    // If logged in and trying to go to login/register, go home (or dashboard)
    if (loggedIn && isLoggingIn) {
      final user = authService.currentUser!;
      return routeByRole(roleId: user.roleid, roleName: user.rolename);
    }

    // Strict role-based route guarding for direct URL navigation
    if (loggedIn && !isLoggingIn) {
      final user = authService.currentUser!;
      final parsedRoleId = int.tryParse((user.roleid ?? '').trim());
      final normalizedRoleName = (user.rolename ?? '').toUpperCase().trim();

      final isHotelOwner =
          parsedRoleId == RoleConstants.hotelOwner ||
          normalizedRoleName == 'HOTEL_OWNER' ||
          normalizedRoleName == 'HOTEL_PARTNER';

      final isAgent =
          parsedRoleId == RoleConstants.travelAgent ||
          normalizedRoleName == 'TRAVEL_AGENT' ||
          normalizedRoleName == 'AGENT' ||
          normalizedRoleName == 'BUS_PARTNER' ||
          normalizedRoleName == 'BUS_OWNER';

      final isAdmin =
          parsedRoleId == RoleConstants.admin || normalizedRoleName == 'ADMIN';

      final targetPath = state.uri.path;
      // debugPrint('GoRouter Redirecting: targetPath=$targetPath, roleid=${user.roleid}, rolename=${user.rolename}, parsedRoleId=$parsedRoleId');
      // debugPrint('isHotelOwner=$isHotelOwner, isAdmin=$isAdmin, isAgent=$isAgent');

      // Prevent non-owners from accessing owner routes
      if ((targetPath.startsWith('/hotel_dashboard') ||
              targetPath.startsWith('/owner/')) &&
          !isHotelOwner &&
          !isAdmin) {
        // debugPrint('GUARD: Redirecting non-owner away from hotel_dashboard to routeByRole');
        return routeByRole(roleId: user.roleid, roleName: user.rolename);
      }

      // Prevent non-agents from accessing agent routes
      if ((targetPath.startsWith('/agent_dashboard') ||
              targetPath.startsWith('/agent/')) &&
          !isAgent &&
          !isAdmin) {
        // debugPrint('GUARD: Redirecting non-agent away from agent_dashboard to routeByRole');
        return routeByRole(roleId: user.roleid, roleName: user.rolename);
      }

      // Prevent non-admins from accessing admin routes
      if ((targetPath.startsWith('/admin_dashboard') ||
              targetPath.startsWith('/admin_flights')) &&
          !isAdmin) {
        // debugPrint('GUARD: Redirecting non-admin away from admin_dashboard to routeByRole');
        return routeByRole(roleId: user.roleid, roleName: user.rolename);
      }
    }

    return null;
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) {
        final target = state.uri.queryParameters['target'];
        return SplashScreen(targetPath: target);
      },
    ),
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
      path: '/bookings',
      builder: (context, state) => const DashboardScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/hotels',
      builder: (context, state) => const HotelListScreen(),
    ),
    GoRoute(
      path: '/packages',
      builder: (context, state) => const PackageListScreen(),
    ),
    GoRoute(
      path: '/flights',
      builder: (context, state) => const FlightListScreen(),
    ),
    GoRoute(
      path: '/flight_bookings',
      builder: (context, state) => const FlightBookingsScreen(),
    ),
    GoRoute(
      path: '/admin_flights',
      builder: (context, state) => const AdminFlightsScreen(),
    ),
    GoRoute(
      path: '/agent_add_flight',
      builder: (context, state) => const AgentAddFlightScreen(),
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
          source: args?['source'],
          destination: args?['destination'],
          date: args?['date'],
        );
      },
    ),
    GoRoute(
      path: '/bus/seats',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is BusModel) {
          return BusSeatSelectionScreen(bus: extra);
        } else if (extra is RecommendedItem) {
          // Map RecommendedItem to a BusModel shell
          final bus = BusModel(
            busid: int.tryParse(extra.id) ?? 0,
            partnerid: 0,
            busname: extra.name,
            busnumber: '',
            bustype: extra.subType ?? 'Standard',
            totalseats: extra.totalSeats > 0 ? extra.totalSeats : 40,
            amenities: '',
            uid: 0,
            seats: [], // Will be loaded by the screen
            baseFare: extra.price,
            departureTime: extra.departureTime,
            arrivalTime: extra.arrivalTime,
            sourceCityName: extra.source,
            destinationCityName: extra.destination,
            imageUrl: extra.imageUrl,
            images: extra.images,
          );
          return BusSeatSelectionScreen(bus: bus);
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Seat Layout')),
          body: const Center(child: Text('Bus data not provided.')),
        );
      },
    ),
    GoRoute(
      path: '/owner/hotels/add',
      builder: (context, state) {
        final args = state.extra;
        if (args is Map<String, dynamic>) {
          return AddEditHotelScreen(
            isEdit: false,
            partnerid: int.tryParse(args['partnerid'].toString()) ?? 0,
            userid: int.tryParse(args['userid'].toString()) ?? 0,
          );
        }
        return const AddEditHotelScreen(isEdit: false, partnerid: 0, userid: 0);
      },
    ),
    GoRoute(
      path: '/owner/hotels/:id/rooms',
      builder: (context, state) {
        final args = state.extra;
        if (args is Map<String, dynamic>) {
          return ManageRoomsScreen(
            hotelid:
                int.tryParse(
                  (args['hotelid'] ?? state.pathParameters['id']).toString(),
                ) ??
                0,
            hotelname: (args['hotelname'] ?? 'Hotel').toString(),
            partnerid: int.tryParse(args['partnerid'].toString()) ?? 0,
            userid: int.tryParse(args['userid'].toString()) ?? 0,
          );
        }
        return ManageRoomsScreen(
          hotelid: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
          hotelname: 'Hotel',
          partnerid: 0,
          userid: 0,
        );
      },
    ),
    GoRoute(
      path: '/agent/packages/add',
      builder: (context, state) {
        final args = state.extra;
        if (args is Map<String, dynamic>) {
          return AddEditPackageScreen(
            partnerid: int.tryParse(args['partnerid'].toString()) ?? 0,
            userid: int.tryParse(args['userid'].toString()) ?? 0,
          );
        }
        return const AddEditPackageScreen(partnerid: 0, userid: 0);
      },
    ),
    GoRoute(
      path: '/agent/buses/add',
      builder: (context, state) {
        final args = state.extra;
        if (args is Map<String, dynamic>) {
          return AddEditBusScreen(
            bus: args['bus'] is BusModel ? args['bus'] as BusModel : null,
            partnerid: int.tryParse(args['partnerid'].toString()) ?? 0,
            userid: int.tryParse(args['userid'].toString()) ?? 0,
          );
        }
        return const AddEditBusScreen(partnerid: 0, userid: 0);
      },
    ),
    GoRoute(
      path: '/passenger_details',
      builder: (context, state) {
        final args = state.extra;
        if (args is Map<String, dynamic> && args['bus'] is BusModel) {
          final bus = args['bus'] as BusModel;
          final seats = args['seats'];

          List<BusSeatModel> selectedSeats = [];
          if (seats is List<BusSeatModel>) {
            selectedSeats = seats;
          } else if (seats is List<String>) {
            selectedSeats =
                seats
                    .map(
                      (s) => BusSeatModel(
                        seatid: 0,
                        busid: bus.busid,
                        seatNo: s,
                        rowNo: 0,
                        colNo: 0,
                      ),
                    )
                    .toList();
          }

          if (selectedSeats.isNotEmpty) {
            return PassengerDetailsScreen(
              bus: bus,
              selectedSeats: selectedSeats,
            );
          }
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Passenger Details')),
          body: const Center(child: Text('Required booking data missing.')),
        );
      },
    ),
    GoRoute(path: '/about', builder: (context, state) => const AboutUsScreen()),
    GoRoute(
      path: '/contact',
      builder: (context, state) => const ContactUsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/refund',
      builder: (context, state) => const RefundPolicyScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsConditionsScreen(),
    ),
  ],
);
