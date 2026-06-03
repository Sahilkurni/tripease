import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

// ── Local models ─────────────────────────────────────────────────────────────

class CategoryItem {
  final int categoryid;
  final String categoryname;
  CategoryItem({required this.categoryid, required this.categoryname});
  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
    categoryid: int.tryParse(j['categoryid']?.toString() ?? '0') ?? 0,
    categoryname: j['categoryname']?.toString() ?? '',
  );
}

class CityItem {
  final int cityid;
  final String cityname;
  CityItem({required this.cityid, required this.cityname});
  factory CityItem.fromJson(Map<String, dynamic> j) => CityItem(
    cityid: int.tryParse(j['cityid']?.toString() ?? '0') ?? 0,
    cityname: j['cityname']?.toString() ?? '',
  );
}

class ItineraryDayItem {
  int dayno;
  String title;
  String description;
  ItineraryDayItem({
    required this.dayno,
    required this.title,
    required this.description,
  });
  Map<String, dynamic> toJson() => {
    'dayno': dayno,
    'title': title,
    'description': description,
  };
  factory ItineraryDayItem.fromJson(Map<String, dynamic> j) => ItineraryDayItem(
    dayno: int.tryParse(j['dayno']?.toString() ?? '0') ?? 0,
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
  );
}

// ── Service class ─────────────────────────────────────────────────────────────

class AgentService {
  static String get _base => ApiConfig.baseUrl;

  // Fetch package categories
  static Future<List<CategoryItem>> getCategories() async {
    try {
      final uri = Uri.parse('$_base/agent/getCategories.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      // print('API Response (getCategories): ${res.body}');
      final data = jsonDecode(utf8.decode(res.bodyBytes))['data'];
      if (data is List) {
        return data.map((e) => CategoryItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // print('getCategories failed: $e');
      return [];
    }
  }

  // Fetch cities
  static Future<List<CityItem>> getCities() async {
    try {
      final uri = Uri.parse('$_base/agent/getCities.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      // print('API Response (getCities): ${res.body}');
      final data = jsonDecode(utf8.decode(res.bodyBytes))['data'];
      if (data is List) {
        return data.map((e) => CityItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      // print('getCities failed: $e');
      return [];
    }
  }

  static Future<CityItem> addCity(String cityName, int uid) async {
    try {
      final uri = Uri.parse('$_base/agent/addCity.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'cityname': cityName, 'uid': uid}),
          )
          .timeout(const Duration(seconds: 10));
      // print('API Response (addCity): ${res.body}');
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json['status'] == 'success') {
        return CityItem.fromJson(json['data']);
      }
      throw Exception(json['message']);
    } catch (e) {
      // print('addCity failed: $e');
      throw Exception('addCity failed: $e');
    }
  }

  static Future<int> savePackageRaw(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$_base/agent/savePackage.php');
      // Ensure itinerary is properly formatted before sending if it exists
      if (payload['itinerary'] != null) {
        payload['itinerary'] = payload['itinerary'].map((d) => d.toJson()).toList();
      }
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      // print('API Response (savePackageRaw): ${res.body}');

      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json['status'] == 'success') {
        return int.tryParse(json['data']?['packageid']?.toString() ?? '0') ?? 0;
      }
      throw Exception(json['message']);
    } catch (e) {
      // print('savePackageRaw failed: $e');
      throw Exception('savePackageRaw failed: $e');
    }
  }

  // Save package (add if packageid==0, edit if packageid>0)
  static Future<int> savePackage({
    required int partnerid,
    required int uid,
    int packageid = 0,
    required int categoryid,
    required String packagename,
    required String description,
    required int cityid,
    required int days,
    required int nights,
    required double price,
    required int maxpersons,
    String thumbnail = '',
    required List<ItineraryDayItem> itinerary,
  }) async {
    try {
      final uri = Uri.parse('$_base/agent/savePackage.php');
      final payload = {
        'partnerid': partnerid,
        'uid': uid,
        'packageid': packageid,
        'categoryid': categoryid,
        'packagename': packagename,
        'description': description,
        'cityid': cityid,
        'days': days,
        'nights': nights,
        'price': price,
        'maxpersons': maxpersons,
        'thumbnail': thumbnail,
        'status': 'pending',
        'itinerary': itinerary.map((d) => d.toJson()).toList(),
      };
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      // print('API Response (savePackage): ${res.body}');

      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json['status'] == 'success') {
        return int.tryParse(json['data']?['packageid']?.toString() ?? '0') ?? 0;
      }
      throw Exception(json['message']);
    } catch (e) {
      // print('savePackage failed: $e');
      throw Exception('savePackage failed: $e');
    }
  }

  // Get single package for editing
  static Future<Map<String, dynamic>> getPackageDetail(
    int packageid,
    int partnerid,
  ) async {
    try {
      final uri = Uri.parse(
        '$_base/agent/getPackageDetail.php'
        '?packageid=$packageid&partnerid=$partnerid',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      // print('API Response (getPackageDetail): ${res.body}');
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json['status'] == 'success') {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(json['message']);
    } catch (e) {
      // print('getPackageDetail failed: $e');
      throw Exception('getPackageDetail failed: $e');
    }
  }

  // Fetch earnings
  static Future<Map<String, dynamic>> getEarnings(
    int partnerid,
    String period,
  ) async {
    try {
      final uri = Uri.parse(
        '$_base/agent/getEarnings.php?partnerid=$partnerid&period=$period',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(utf8.decode(res.bodyBytes));
      if (json['status'] == 'success') {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('getEarnings failed: $e');
    }
  }
}
