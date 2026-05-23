import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../core/api_config.dart';

class HotelService {
  // Fetch hotels for a specific partner (Owner)
  Future<List<HotelModel>> getPartnerHotels(int partnerId) async {
    final url = '${ApiConfig.hotels}?partnerid=$partnerId';
    // print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url));
      // print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (data is List) {
          return data.map((e) => HotelModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      // print("Error: $e");
      return [];
    }
  }

  // Fetch all approved hotels for home
  Future<List<HotelModel>> getHomeHotels() async {
    final url = ApiConfig.searchHotels;
    // print("API URL: $url");
    try {
      final response = await http.get(Uri.parse(url));
      // print("Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        if (data is List) {
          return data.map((e) => HotelModel.fromJson(e)).toList();
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

  // Fetch rooms for a specific hotel
  Future<List<RoomModel>> getHotelRooms(int hotelId) async {
    final url = '${ApiConfig.rooms}?hotelid=$hotelId';
    // print("API URL (Rooms): $url");
    try {
      final response = await http.get(Uri.parse(url));
      // print("Hotel Rooms Response: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          final data = decoded['data'];
          if (data is List) {
            return data.map((e) => RoomModel.fromJson(e)).toList();
          }
        }
        return [];
      } else {
        throw Exception("API failed with status: ${response.statusCode}");
      }
    } catch (e) {
      // print("Error fetching rooms: $e");
      rethrow;
    }
  }

  // Fetch multiple images for a hotel
  Future<List<String>> getHotelImages(int hotelId) async {
    final url = '${ApiConfig.baseUrl}get_images.php?entity_type=hotel&entity_id=$hotelId';
    // print("API URL (Images): $url");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['status'] == 'success') {
          final data = decoded['data'];
          if (data is List) {
            return data.map((e) => e['image'].toString()).toList();
          }
        }
      }
      return [];
    } catch (e) {
      // print("Error fetching images: $e");
      return [];
    }
  }
  Future<bool> createBooking({
    required int userId,
    required int hotelId,
    required int roomId,
    required double amount,
    String? guestName,
    String? age,
    String? gender,
    String? paymentId,
  }) async {
    final url = '${ApiConfig.baseUrl}create_booking.php';
    // print("API URL (Create Hotel Booking): $url");
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'userid': userId.toString(),
          'hotelid': hotelId.toString(),
          'roomid': roomId.toString(),
          'amount': amount.toString(),
          'booking_date': DateTime.now().toIso8601String().split('T').first,
          'guest_name': guestName ?? '',
          'guest_age': age ?? '',
          'guest_gender': gender ?? '',
          'payment_id': paymentId ?? '',
        },
      );
      // print("Hotel Booking Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      // print("Error creating hotel booking: $e");
      return false;
    }
  }
}

final hotelService = HotelService();
