import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // IMPORTANT: For Physical Device testing, change this to your PC's Local IP Address (e.g. 192.168.1.5)
  // For Android Emulator, keep it as 10.0.2.2
  static const String hostIp = '192.168.1.8';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/tripease_api/';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://$hostIp/tripease_api/';
      }
    } catch (_) {}
    return 'http://localhost/tripease_api/';
  }

  // Common endpoints
  static String get login => '${baseUrl}login.php';
  static String get register => '${baseUrl}register.php';
  static String get sendOtp => '${baseUrl}send_otp.php';
  static String get verifyOtp => '${baseUrl}verify_otp.php';

  // Hotel endpoints
  static String get hotels => '${baseUrl}get_hotels.php';
  static String get rooms => '${baseUrl}get_hotel_rooms.php';

  // Booking endpoints
  static String get createBooking => '${baseUrl}create_booking.php';
  static String get createPackageBooking =>
      '${baseUrl}create_package_booking.php';

  // Travel Agent endpoints
  static String get packages => '${baseUrl}get_home_packages.php';
  static String get buses => '${baseUrl}agent/buses.php';

  // Public endpoints
  static String get searchBuses => '${baseUrl}agent/buses.php';
  static String get searchHotels => '${baseUrl}get_home_hotels.php';
  static String get searchPackages => '${baseUrl}get_home_packages.php';

  // Flight endpoints
  static String get flightHome => '${baseUrl}get_home_flights.php';
  static String get flightSeats => '${baseUrl}get_flight_seats.php';
  static String get flightBooking => '${baseUrl}create_flight_booking.php';
  static String get userFlightBookings => '${baseUrl}get_user_flight_bookings.php';
  static String get adminFlights => '${baseUrl}admin/get_all_flights.php';
  static String get updateFlightStatus => '${baseUrl}admin/update_flight_status.php';
  static String get createFlight => '${baseUrl}create_flight.php';
  static String get updateFlight => '${baseUrl}update_flight.php';
  static String get deleteFlight => '${baseUrl}delete_flight.php';
  static String get nearbyItems => '${baseUrl}get_nearby_items.php';

  // Coupon endpoints
  static String get createCoupon => '${baseUrl}create_coupon.php';
  static String get updateCoupon => '${baseUrl}update_coupon.php';
  static String get deleteCoupon => '${baseUrl}delete_coupon.php';
  static String get getCoupons => '${baseUrl}get_coupons.php';
  static String get applyCoupon => '${baseUrl}apply_coupon.php';
  static String get recordCouponUsage => '${baseUrl}record_coupon_usage.php';
  static String get approveCoupon => '${baseUrl}admin/approve_coupon.php';
  static String get getCouponUsage => '${baseUrl}get_coupon_usage.php';

  // Offer endpoints
  static String get createOffer => '${baseUrl}create_offer.php';
  static String get updateOffer => '${baseUrl}update_offer.php';
  static String get deleteOffer => '${baseUrl}delete_offer.php';
  static String get getOffers => '${baseUrl}get_offers.php';
  static String get offerDetails => '${baseUrl}get_offer_details.php';
  static String get applyOffer => '${baseUrl}apply_offer.php';
  static String get approveOffer => '${baseUrl}approve_offer.php';
}
