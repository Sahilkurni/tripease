import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 10.0.2.2 for Android Emulator to access localhost
  // Use localhost for Web and Windows
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/tripease_api';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2/tripease_api';
    } else {
      return 'http://localhost/tripease_api';
    }
  }

  // Common endpoints
  static String get login => '$baseUrl/auth/login.php';
  static String get register => '$baseUrl/auth/register.php';
  
  // Hotel Owner endpoints
  static String get hotels => '$baseUrl/owner/hotels.php';
  static String get rooms => '$baseUrl/owner/rooms.php';
  
  // Travel Agent endpoints
  static String get packages => '$baseUrl/agent/packages.php';
  static String get buses => '$baseUrl/agent/buses.php';
  
  // Public endpoints
  static String get searchBuses => '$baseUrl/public/search_buses.php';
  static String get searchHotels => '$baseUrl/public/search_hotels.php';
  static String get searchPackages => '$baseUrl/public/search_packages.php';
}
