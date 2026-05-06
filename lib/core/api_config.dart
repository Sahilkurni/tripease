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
}
