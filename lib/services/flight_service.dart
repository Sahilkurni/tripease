import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_config.dart';
import '../models/flight_model.dart';
import '../models/seat_model.dart';

class FlightService {
  Future<List<FlightModel>> getHomeFlights() async {
    final url = ApiConfig.flightHome;
    print("API URL (Flights Home): $url");
    try {
      final response = await http.get(Uri.parse(url));
      print("Flights Home Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          final data = decoded['data'];
          if (data is List) {
            return data.map((e) => FlightModel.fromJson(e)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      print("Error fetching home flights: $e");
      return [];
    }
  }

  Future<List<SeatModel>> getFlightSeats(int flightId) async {
    final url = '${ApiConfig.flightSeats}?flightid=$flightId';
    print("API URL (Flight Seats): $url");
    try {
      final response = await http.get(Uri.parse(url));
      print("Flight Seats Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          final data = decoded['data'];
          if (data is List) {
            return data.map((e) => SeatModel.fromJson(e)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      print("Error fetching flight seats: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> createFlightBooking({
    required int userId,
    required int flightId,
    required List<int> selectedSeats,
    required List<Map<String, dynamic>> passengers,
    String? paymentId,
  }) async {
    final url = ApiConfig.flightBooking;
    print("API URL (Create Flight Booking): $url");
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userid': userId,
          'flightid': flightId,
          'selected_seats': selectedSeats,
          'passengers': passengers,
          'payment_id': paymentId,
        }),
      );
      print("Create Flight Booking Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Error creating flight booking: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> getUserFlightBookings(int userId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.userFlightBookings}?userid=$userId"),
      );
      print("User Flight Bookings Response: ${response.body}");

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      return [];
    } catch (e) {
      print("Error fetching user flight bookings: $e");
      return [];
    }
  }

  Future<List<FlightModel>> getAdminFlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userid = prefs.getInt('userid') ?? 0;
      final response = await http.get(Uri.parse('${ApiConfig.adminFlights}?userid=$userid'));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return (data['data'] as List)
            .map((e) => FlightModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching admin flights: $e");
      return [];
    }
  }

  Future<List<FlightModel>> getAgentFlights(int creatorId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.adminFlights}?userid=$creatorId&created_by=$creatorId'));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return (data['data'] as List)
            .map((e) => FlightModel.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      print("Error fetching agent flights: $e");
      return [];
    }
  }

  Future<bool> updateFlightStatus(int flightId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userid = prefs.getInt('userid') ?? 0;
      final response = await http.post(
        Uri.parse(ApiConfig.updateFlightStatus),
        body: {
          'userid': userid.toString(),
          'flightid': flightId.toString(),
          'status': status,
        },
      );
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print("Error updating flight status: $e");
      return false;
    }
  }

  Future<bool> createFlight(Map<String, dynamic> flightData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createFlight),
        body: flightData,
      );
      print("Create Flight Response: ${response.body}");
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print("Error creating flight: $e");
      return false;
    }
  }

  Future<bool> updateFlight(Map<String, dynamic> flightData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.updateFlight),
        body: flightData,
      );
      print("Update Flight Response: ${response.body}");
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print("Error updating flight: $e");
      return false;
    }
  }

  Future<bool> deleteFlight(String flightId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deleteFlight),
        body: {
          'flightid': flightId,
          'userid': userId,
        },
      );
      print("Delete Flight Response: ${response.body}");
      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print("Error deleting flight: $e");
      return false;
    }
  }
}

final flightService = FlightService();
