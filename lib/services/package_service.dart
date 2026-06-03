import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/package_model.dart';
import '../core/api_config.dart';

class PackageService {
  // Fetch packages for a specific agent
  Future<List<PackageModel>> getAgentPackages(int partnerId) async {
    final url = '${ApiConfig.baseUrl}agent/packages.php?partnerid=$partnerId';
    // print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url));
      // print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data is List) {
          return data.map((e) => PackageModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      // print("Error: $e");
      rethrow;
    }
  }

  // Fetch all approved packages for home
  Future<List<PackageModel>> getHomePackages() async {
    final url = ApiConfig.searchPackages;
    // print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url));
      // print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data is List) {
          return data.map((e) => PackageModel.fromJson(e)).toList();
        }
        return [];
      } else {
        throw Exception("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      // print("Error: $e");
      rethrow;
    }
  }
}

final packageService = PackageService();
