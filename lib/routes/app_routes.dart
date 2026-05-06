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
      path: '/packages',
      builder: (context, state) => const PackageListScreen(),
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
          date: args?['date'] ?? DateTime.now().toIso8601String(),
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
            busName: extra.name,
            busType: 'Standard',
            layoutType: '2x2',
            totalSeats: 40,
            sourceCityId: 0,
            destinationCityId: 0,
            departureTime: '00:00',
            arrivalTime: '00:00',
            sourceCityName: extra.location.contains(' to ') ? extra.location.split(' to ').first : 'Source',
            destinationCityName: extra.location.contains(' to ') ? extra.location.split(' to ').last : 'Destination',
            baseFare: extra.price,
            seats: [], // Will be loaded by the screen
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
            selectedSeats = seats.map((s) => BusSeatModel(
              seatid: 0,
              busid: bus.busid,
              seatNo: s,
              rowNo: 0,
              colNo: 0,
            )).toList();
          }

          if (selectedSeats.isNotEmpty) {
            return PassengerDetailsScreen(bus: bus, selectedSeats: selectedSeats);
          }
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Passenger Details')),
          body: const Center(child: Text('Required booking data missing.')),
        );
      },
    ),
  ],
);
