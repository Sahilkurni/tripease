import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../screens/home/dashboard_screen.dart';

class HomeService {
  String get baseUrl => ApiConfig.baseUrl;

  List<Map<String, dynamic>> _dataListFromResponse(http.Response response) {
    // print(response.body);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic> && decoded['status'] == 'success') {
      final List data = decoded['data'] is List ? decoded['data'] as List : [];
      return data
          .whereType<Map>()
          .map((item) => item.map((key, value) => MapEntry('$key', value)))
          .toList();
    }
    return [];
  }

  Future<List<RecommendedItem>> getHomeHotels() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl'
          'get_home_hotels.php',
        ),
      );
      // print("Home Hotels Response: ${response.body}");
      final rows = _dataListFromResponse(response);
      return rows.map(RecommendedItem.fromHotelJson).toList();
    } catch (e, st) {
      // debugPrint('getHomeHotels error: $e');
      // debugPrint('$st');
      return [];
    }
  }

  Future<List<RecommendedItem>> getHomePackages() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl'
          'get_home_packages.php',
        ),
      );
      // print("Home Packages Response: ${response.body}");
      final rows = _dataListFromResponse(response);
      return rows.map(RecommendedItem.fromPackageJson).toList();
    } catch (e, st) {
      // debugPrint('getHomePackages error: $e');
      // debugPrint('$st');
      return [];
    }
  }

  Future<List<RecommendedItem>> getHomeBuses() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl'
          'get_bus_trips.php',
        ),
      );
      // print("Home Buses Response: ${response.body}");
      final rows = _dataListFromResponse(response);
      return rows.map((row) {
        final source =
            row['source']?.toString() ??
            row['source_city_name']?.toString() ??
            '';
        final destination =
            row['destination']?.toString() ??
            row['destination_city_name']?.toString() ??
            '';
        return RecommendedItem(
          id: row['tripid']?.toString() ?? row['busid']?.toString() ?? '',
          name:
              row['busname']?.toString() ??
              row['bus_name']?.toString() ??
              'Bus',
          location: [
            if (source.isNotEmpty) source,
            if (destination.isNotEmpty) destination,
          ].join(' to '),
          rating: 4.5,
          price:
              double.tryParse(
                (row['price'] ?? row['base_fare'] ?? row['fare'] ?? '0')
                    .toString(),
              ) ??
              0,
          type: 'bus',
          imageUrl:
              row['imageUrl']?.toString() ?? row['image']?.toString() ?? '',
          images:
              (row['images'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          subType: row['bus_type'] ?? row['bustype'] ?? 'Standard',
          source: source,
          destination: destination,
          departureTime:
              row['departure']?.toString() ??
              row['departure_time']?.toString() ??
              '',
          arrivalTime:
              row['arrival']?.toString() ??
              row['arrival_time']?.toString() ??
              '',
          totalSeats:
              int.tryParse(
                (row['totalseats'] ?? row['total_seats'] ?? '').toString(),
              ) ??
              0,
          latitude: double.tryParse(row['latitude']?.toString() ?? ''),
          longitude: double.tryParse(row['longitude']?.toString() ?? ''),
        );
      }).toList();
    } catch (e, st) {
      // debugPrint('getHomeBuses error: $e');
      // debugPrint('$st');
      return [];
    }
  }

  Future<List<BookingItem>> getRecentBookings({String? userid}) async {
    try {
      final query = (userid == null || userid.isEmpty) ? '' : '?userid=$userid';
      final response = await http.get(
        Uri.parse(
          '$baseUrl'
          'get_bookings.php$query',
        ),
      );
      // print("Recent Bookings Response: ${response.body}");
      final rows = _dataListFromResponse(response);
      return rows.map(BookingItem.fromJson).toList();
    } catch (e, st) {
      // debugPrint('getRecentBookings error: $e');
      // debugPrint('$st');
      return [];
    }
  }
}

final homeService = HomeService();
