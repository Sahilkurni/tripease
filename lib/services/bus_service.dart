import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus_model.dart';
import '../core/api_config.dart';

class BusService {
  // Fetch buses for a specific agent
  Future<List<BusModel>> getAgentBuses(int partnerId) async {
    final url = '${ApiConfig.buses}?partnerid=$partnerId';
    print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List)
              .map((e) => BusModel.fromJson(e))
              .toList();
        }
        throw Exception(data['message'] ?? 'Failed to load buses');
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      print("Error: $e");
      throw Exception('getAgentBuses failed: $e');
    }
  }

  Future<int> saveBus(Map<String, dynamic> payload) async {
    final url = ApiConfig.buses;
    print("API URL: $url");
    try {
      final safePayload = Map<String, dynamic>.from(payload);
      safePayload.putIfAbsent('status', () => 'pending');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(safePayload),
          )
          .timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");

      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return int.parse(data['data']['busid'].toString());
      }
      throw Exception(data['message'] ?? 'Failed to save bus');
    } catch (e) {
      print("Error: $e");
      throw Exception('saveBus failed: $e');
    }
  }

  /// Returns all active images for a bus as a list of base64 strings (primary first).
  Future<List<String>> getBusImages(int busid) async {
    try {
      final maps = await getBusImageMaps(busid);
      return maps.map((m) => m['image'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns [{imageid, image, is_primary}] for a bus — primary first.
  Future<List<Map<String, dynamic>>> getBusImageMaps(int busid) async {
    try {
      final uri = Uri.parse(
          '${ApiConfig.baseUrl}get_images.php?entity_type=bus&entity_id=$busid');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        final data = json['data'] as List<dynamic>;
        return data
            .where((e) => (e['image'] ?? '').toString().isNotEmpty)
            .map((e) => {
                  'imageid': e['imageid'] as int? ?? 0,
                  'image': (e['image'] ?? '').toString(),
                  'is_primary': e['is_primary'] as int? ?? 0,
                })
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Soft-deletes an image by imageid.
  Future<void> deleteImage(int imageid) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}delete_image.php');
      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'imageid': imageid}))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(res.body);
      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Delete failed');
      }
    } catch (e) {
      throw Exception('deleteImage failed: $e');
    }
  }

  Future<void> deleteBus({
    required int busid,
    required int partnerid,
    required int uid,
  }) async {
    final url = ApiConfig.buses;
    print("API URL: $url");
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'delete',
              'busid': busid,
              'partnerid': partnerid,
              'uid': uid,
            }),
          )
          .timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");

      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to delete bus');
      }
    } catch (e) {
      print("Error: $e");
      throw Exception('deleteBus failed: $e');
    }
  }

  // Public search buses
  Future<List<BusModel>> searchBuses(
    String source,
    String destination,
    String date,
  ) async {
    final url = Uri.parse(ApiConfig.searchBuses).replace(
      queryParameters: {
        'source': source,
        'destination': destination,
        'date': date,
      },
    ).toString();
    print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is List) {
          return data.map((e) => BusModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }

  // Fetch home bus trips
  Future<List<BusModel>> getHomeBusTrips() async {
    final url = '${ApiConfig.baseUrl}get_bus_trips.php';
    print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url));
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is List) {
          return data.map((e) => BusModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBusSeats(int tripId) async {
    final url = '${ApiConfig.baseUrl}get_bus_seats.php?tripid=$tripId';
    print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url));
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return [];
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw Exception("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }

  Future<bool> bookBus({
    required int userId,
    required int tripId,
    required int seatId,
    required double amount,
    String? passengerName,
    String? age,
    String? gender,
    String? paymentId,
  }) async {
    final url = '${ApiConfig.baseUrl}create_bus_booking.php';
    print("API URL: $url");
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'userid': userId.toString(),
          'tripid': tripId.toString(),
          'seatid': seatId.toString(),
          'amount': amount.toString(),
          'passenger_name': passengerName ?? '',
          'passenger_age': age ?? '',
          'passenger_gender': gender ?? '',
          'payment_id': paymentId ?? '',
        },
      );
      print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      } else {
        throw Exception("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      rethrow;
    }
  }
}

final busService = BusService();
