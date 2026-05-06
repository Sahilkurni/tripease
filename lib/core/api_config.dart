import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 10.0.2.2 for Android Emulator to access localhost
  // Use localhost for Web and Windows
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/tripease_api/';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2/tripease_api/';
      }
    } catch (_) {}
    return 'http://localhost/tripease_api/';
  }

  // Common endpoints
  static String get login => '${baseUrl}login.php';
  static String get register => '${baseUrl}register.php';

  // Hotel endpoints
  static String get hotels => '${baseUrl}get_hotels.php';
  static String get rooms => '${baseUrl}get_hotel_rooms.php';

  // Booking endpoints
  static String get createBooking => '${baseUrl}create_booking.php';
  static String get createPackageBooking =>
      '${baseUrl}create_package_booking.php';

  // Travel Agent endpoints
  static String get packages => '${baseUrl}get_home_packages.php';
  static String get buses => '${baseUrl}get_buses.php';

  // Public endpoints
  static String get searchBuses => '${baseUrl}get_buses.php';
  static String get searchHotels => '${baseUrl}get_home_hotels.php';
  static String get searchPackages => '${baseUrl}get_home_packages.php';
}
