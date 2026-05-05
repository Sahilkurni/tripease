import 'dart:convert';
import 'package:http/http.dart' as http;

// ── Local models ─────────────────────────────────────────────────────────────

class CategoryItem {
  final int categoryid;
  final String categoryname;
  CategoryItem({required this.categoryid, required this.categoryname});
  factory CategoryItem.fromJson(Map<String, dynamic> j) => CategoryItem(
    categoryid:   int.parse(j['categoryid'].toString()),
    categoryname: j['categoryname'].toString(),
  );
}

class CityItem {
  final int cityid;
  final String cityname;
  CityItem({required this.cityid, required this.cityname});
  factory CityItem.fromJson(Map<String, dynamic> j) => CityItem(
    cityid:   int.parse(j['cityid'].toString()),
    cityname: j['cityname'].toString(),
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
    'dayno':       dayno,
    'title':       title,
    'description': description,
  };
  factory ItineraryDayItem.fromJson(Map<String, dynamic> j) =>
    ItineraryDayItem(
      dayno:       int.parse(j['dayno'].toString()),
      title:       j['title'].toString(),
      description: j['description']?.toString() ?? '',
    );
}

// ── Service class ─────────────────────────────────────────────────────────────

class AgentService {
  static const String _base = 'http://localhost/tripease_api';

  // Fetch package categories
  static Future<List<CategoryItem>> getCategories() async {
    final uri = Uri.parse('$_base/agent/getCategories.php');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    final json = jsonDecode(res.body);
    if (json['status'] == 'success') {
      return (json['data'] as List)
          .map((e) => CategoryItem.fromJson(e))
          .toList();
    }
    throw Exception(json['message']);
  }

  // Fetch cities
  static Future<List<CityItem>> getCities() async {
    try {
      final uri = Uri.parse('$_base/agent/getCities.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return (json['data'] as List).map((e) => CityItem.fromJson(e)).toList();
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('getCities failed: $e');
    }
  }

  static Future<CityItem> addCity(String cityName, int uid) async {
    try {
      final uri = Uri.parse('$_base/agent/addCity.php');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'cityname': cityName,
          'uid': uid,
        }),
      ).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return CityItem.fromJson(json['data']);
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('addCity failed: $e');
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
    final uri     = Uri.parse('$_base/agent/savePackage.php');
    final payload = {
      'partnerid':   partnerid,
      'uid':         uid,
      'packageid':   packageid,
      'categoryid':  categoryid,
      'packagename': packagename,
      'description': description,
      'cityid':      cityid,
      'days':        days,
      'nights':      nights,
      'price':       price,
      'maxpersons':  maxpersons,
      'thumbnail':   thumbnail,
      'itinerary':   itinerary.map((d) => d.toJson()).toList(),
    };
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body:    jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    final json = jsonDecode(res.body);
    if (json['status'] == 'success') {
      return int.parse(json['data']['packageid'].toString());
    }
    throw Exception(json['message']);
  }

  // Get single package for editing
  static Future<Map<String, dynamic>> getPackageDetail(
      int packageid, int partnerid) async {
    final uri = Uri.parse(
        '$_base/agent/getPackageDetail.php'
        '?packageid=$packageid&partnerid=$partnerid');
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    final json = jsonDecode(res.body);
    if (json['status'] == 'success') {
      return json['data'] as Map<String, dynamic>;
    }
    throw Exception(json['message']);
  }
}
