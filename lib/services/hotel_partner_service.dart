import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class CityItem {
  final int cityid;
  final String cityname;
  final String pincode;

  CityItem({
    required this.cityid,
    required this.cityname,
    required this.pincode,
  });

  factory CityItem.fromJson(Map<String, dynamic> j) => CityItem(
    cityid: int.parse(j['cityid'].toString()),
    cityname: j['cityname'],
    pincode: j['pincode'] ?? '',
  );
}

class StateItem {
  final int stateid;
  final String statename;

  StateItem({required this.stateid, required this.statename});

  factory StateItem.fromJson(Map<String, dynamic> j) => StateItem(
    stateid: int.parse(j['stateid'].toString()),
    statename: j['statename'],
  );
}

class RoomTypeItem {
  final int roomtypeid;
  final String typename;

  RoomTypeItem({required this.roomtypeid, required this.typename});

  factory RoomTypeItem.fromJson(Map<String, dynamic> j) => RoomTypeItem(
    roomtypeid: int.parse(
      (j['roomtypeid'] ?? j['room_type_id'] ?? j['id']).toString(),
    ),
    typename:
        (j['typename'] ?? j['type_name'] ?? j['roomtype'] ?? j['name'] ?? '')
            .toString(),
  );
}

class RoomItem {
  final int roomid;
  final String roomname;
  final String roomtype;
  final int roomtypeid;
  final int capacity;
  final int totalrooms;
  final double price;
  final double extraBedPrice;

  RoomItem({
    required this.roomid,
    required this.roomname,
    required this.roomtype,
    required this.roomtypeid,
    required this.capacity,
    required this.totalrooms,
    required this.price,
    required this.extraBedPrice,
  });

  factory RoomItem.fromJson(Map<String, dynamic> j) => RoomItem(
    roomid: int.parse(j['roomid'].toString()),
    roomname: j['roomname'],
    roomtype: j['roomtype'],
    roomtypeid: int.parse(j['roomtypeid'].toString()),
    capacity: int.parse(j['capacity'].toString()),
    totalrooms: int.parse(j['totalrooms'].toString()),
    price: double.parse(j['price'].toString()),
    extraBedPrice: double.parse(j['extra_bed_price']?.toString() ?? '0'),
  );
}

class HotelPartnerService {
  // Use centralized baseUrl from ApiConfig
  static String get _base => ApiConfig.baseUrl;

  static final List<RoomTypeItem> _defaultRoomTypes = [
    RoomTypeItem(roomtypeid: 1, typename: 'Standard'),
    RoomTypeItem(roomtypeid: 2, typename: 'Deluxe'),
    RoomTypeItem(roomtypeid: 3, typename: 'Suite'),
    RoomTypeItem(roomtypeid: 4, typename: 'Family Room'),
  ];

  /// Fetches live dashboard statistics for the logged-in hotel partner.
  static Future<Map<String, dynamic>> getDashboardStats(int partnerid) async {
    try {
      final uri = Uri.parse(
        '$_base/owner/getDashboardStats.php?partnerid=$partnerid',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          return json['data'] as Map<String, dynamic>;
        }
        throw Exception(json['message']);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('getDashboardStats failed: $e');
    }
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<Map<String, dynamic>> _hotelListFromJson(dynamic json) {
    if (json is List) {
      return json
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (json is Map && json['status'] == 'success') {
      final data = json['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (data is Map && data['hotels'] is List) {
        return (data['hotels'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getHotels(int partnerid) async {
    if (partnerid == 0) {
      return [];
    }

    final listEndpoints = [
      '$_base/owner/getHotels.php?partnerid=$partnerid',
      '$_base/owner/hotels.php?partnerid=$partnerid',
    ];

    for (final endpoint in listEndpoints) {
      try {
        final res = await http
            .get(Uri.parse(endpoint))
            .timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) {
          continue;
        }
        final hotels =
            _hotelListFromJson(jsonDecode(res.body))
                .where((h) => _asInt(h['partnerid'], partnerid) == partnerid)
                .toList();
        if (hotels.isNotEmpty) {
          return hotels;
        }
      } catch (_) {
        // Older local APIs may not have a list endpoint yet.
      }
    }

    final stats = await getDashboardStats(partnerid);
    final expectedHotels = _asInt(stats['total_hotels']);
    if (expectedHotels == 0) {
      return [];
    }

    final hotels = <Map<String, dynamic>>[];
    final seenHotelIds = <int>{};
    final maxScan =
        expectedHotels <= 2 ? 100 : (expectedHotels * 50).clamp(100, 500);

    for (var hotelid = 1; hotelid <= maxScan; hotelid++) {
      try {
        final hotel = await getHotel(hotelid);
        final foundPartnerId = _asInt(hotel['partnerid']);
        final foundHotelId = _asInt(hotel['hotelid']);
        if (foundPartnerId == partnerid && seenHotelIds.add(foundHotelId)) {
          hotels.add(hotel);
          if (hotels.length >= expectedHotels) {
            break;
          }
        }
      } catch (_) {
        // Keep scanning; getHotel returns an error for IDs that do not exist.
      }
    }

    return hotels;
  }

  static Future<List<StateItem>> getStates() async {
    try {
      final uri = Uri.parse('$_base/owner/getStates.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return (json['data'] as List)
            .map((e) => StateItem.fromJson(e))
            .toList();
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('getStates failed: $e');
    }
  }

  static Future<List<CityItem>> getCities([int stateid = 0]) async {
    try {
      final uri = Uri.parse('$_base/owner/getCities.php?stateid=$stateid');
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

  static Future<int> addHotel(Map<String, dynamic> payload) async {
    try {
      final safePayload = Map<String, dynamic>.from(payload);
      safePayload.putIfAbsent('status', () => 'pending');
      final uri = Uri.parse('$_base/owner/addHotel.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(safePayload),
          )
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') return json['data']['hotelid'];
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('addHotel failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getHotel(int hotelid) async {
    try {
      final uri = Uri.parse('$_base/owner/getHotel.php?hotelid=$hotelid');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('getHotel failed: $e');
    }
  }

  /// Returns all active images for a hotel as a list of base64 strings (primary first).
  static Future<List<String>> getHotelImages(int hotelid) async {
    try {
      final maps = await getHotelImageMaps(hotelid);
      return maps.map((m) => m['image'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Returns [{imageid, image, is_primary}] for a hotel.
  static Future<List<Map<String, dynamic>>> getHotelImageMaps(int hotelid) async {
    try {
      final uri = Uri.parse('$_base/get_images.php?entity_type=hotel&entity_id=$hotelid');
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
    } catch (e) {
      return [];
    }
  }

  /// Returns all active images for a room as a list of base64 strings (primary first).
  static Future<List<String>> getRoomImages(int roomid) async {
    try {
      final maps = await getRoomImageMaps(roomid);
      return maps.map((m) => m['image'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns [{imageid, image, is_primary}] for a room.
  static Future<List<Map<String, dynamic>>> getRoomImageMaps(int roomid) async {
    try {
      final uri = Uri.parse('$_base/get_images.php?entity_type=room&entity_id=$roomid');
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

  /// Soft-deletes an image by imageid (sets isactive=0 in image_master).
  static Future<void> deleteImage(int imageid) async {
    try {
      final uri = Uri.parse('$_base/delete_image.php');
      final res = await http
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'imageid': imageid}))
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] != 'success') {
        throw Exception(json['message'] ?? 'Delete failed');
      }
    } catch (e) {
      throw Exception('deleteImage failed: $e');
    }
  }


  static Future<void> editHotel(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$_base/owner/editHotel.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] != 'success') throw Exception(json['message']);
    } catch (e) {
      throw Exception('editHotel failed: $e');
    }
  }

  static Future<List<RoomTypeItem>> getRoomTypes() async {
    try {
      final uri = Uri.parse('$_base/owner/getRoomTypes.php');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        final types =
            (json['data'] as List)
                .map((e) => RoomTypeItem.fromJson(e))
                .where((type) => type.typename.trim().isNotEmpty)
                .toList();
        return types.isEmpty ? _defaultRoomTypes : types;
      }
      throw Exception(json['message']);
    } catch (e) {
      return _defaultRoomTypes;
    }
  }

  static Future<List<RoomItem>> getRooms(int hotelid, int partnerid) async {
    try {
      final uri = Uri.parse(
        '$_base/owner/getRooms.php?hotelid=$hotelid&partnerid=$partnerid',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return (json['data'] as List).map((e) => RoomItem.fromJson(e)).toList();
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('getRooms failed: $e');
    }
  }

  static Future<void> saveRoom(Map<String, dynamic> payload) async {
    try {
      final uri = Uri.parse('$_base/owner/saveRoom.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] != 'success') throw Exception(json['message']);
    } catch (e) {
      throw Exception('saveRoom failed: $e');
    }
  }

  static Future<void> deleteRoom(int roomid, int partnerid, int uid) async {
    try {
      final uri = Uri.parse('$_base/owner/deleteRoom.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'roomid': roomid,
              'partnerid': partnerid,
              'uid': uid,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] != 'success') throw Exception(json['message']);
    } catch (e) {
      throw Exception('deleteRoom failed: $e');
    }
  }

  static Future<List<dynamic>> getRoomInventory(
    int partnerid, {
    int hotelid = 0,
  }) async {
    try {
      final uri = Uri.parse(
        '$_base/owner/getRoomInventory.php?partnerid=$partnerid&hotelid=$hotelid',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return json['data'] as List<dynamic>;
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('getRoomInventory failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getEarnings(
    int partnerid,
    String period,
  ) async {
    try {
      final uri = Uri.parse(
        '$_base/owner/getEarnings.php?partnerid=$partnerid&period=$period',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return json['data'] as Map<String, dynamic>;
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('getEarnings failed: $e');
    }
  }

  static Future<CityItem> addCity(String cityName, int stateId, int uid) async {
    try {
      final uri = Uri.parse('$_base/agent/addCity.php');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'cityname': cityName,
              'stateid': stateId,
              'uid': uid,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        return CityItem.fromJson(json['data']);
      }
      throw Exception(json['message']);
    } catch (e) {
      throw Exception('addCity failed: $e');
    }
  }
}
