import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus_model.dart';
import '../core/api_config.dart';

class BusService {
  // Fetch buses for a specific agent
  Future<List<BusModel>> getAgentBuses(int partnerId) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.buses}?partnerid=$partnerId'))
          .timeout(const Duration(seconds: 12));

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
      throw Exception('getAgentBuses failed: $e');
    }
  }

  Future<int> saveBus(Map<String, dynamic> payload) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.buses),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        return int.parse(data['data']['busid'].toString());
      }
      throw Exception(data['message'] ?? 'Failed to save bus');
    } catch (e) {
      throw Exception('saveBus failed: $e');
    }
  }

  Future<void> deleteBus({
    required int busid,
    required int partnerid,
    required int uid,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.buses),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'action': 'delete',
              'busid': busid,
              'partnerid': partnerid,
              'uid': uid,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode != 200 || data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to delete bus');
      }
    } catch (e) {
      throw Exception('deleteBus failed: $e');
    }
  }

  // Public search buses
  Future<List<BusModel>> searchBuses(
    String source,
    String destination,
    String date,
  ) async {
    try {
      final uri = Uri.parse(ApiConfig.searchBuses).replace(
        queryParameters: {
          'source': source,
          'destination': destination,
          'date': date,
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 12));

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
      throw Exception('searchBuses failed: $e');
    }
  }
}

final busService = BusService();
