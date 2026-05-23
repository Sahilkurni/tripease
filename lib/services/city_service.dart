import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class CityModel {
  final int cityId;
  final String cityName;

  CityModel({required this.cityId, required this.cityName});

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: int.parse(json['cityid'].toString()),
      cityName: json['cityname'],
    );
  }
}

class CityService {
  Future<List<CityModel>> getCities() async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}owner/getCities.php'));
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return (data['data'] as List).map((e) => CityModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // print("Error fetching cities: $e");
      return [];
    }
  }

  Future<CityModel> addCity(String cityName, int uid) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}agent/addCity.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'cityname': cityName, 'uid': uid}),
      );
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return CityModel.fromJson(data['data']);
      }
      throw Exception(data['message']);
    } catch (e) {
      throw Exception('addCity failed: $e');
    }
  }
}

final cityService = CityService();
