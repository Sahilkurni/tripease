import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../core/api_config.dart';

class HotelService {
  // Fetch hotels for a specific partner (Owner)
  Future<List<HotelModel>> getPartnerHotels(int partnerId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.hotels}?partnerid=$partnerId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List).map((e) => HotelModel.fromJson(e)).toList();
        }
      }
      throw Exception('Failed to load hotels');
    } catch (e) {
      // Fallback to mock data for UI testing if API fails/not ready
      print('API Error (getPartnerHotels): $e. Using mock data.');
      return [
        HotelModel(
          hotelid: 1,
          partnerid: partnerId,
          hotelname: 'Grand Taj',
          cityid: 1,
          starRating: 5.0,
          isactive: 1,
          imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&q=80',
          startingPrice: 4500.0,
        ),
        HotelModel(
          hotelid: 2,
          partnerid: partnerId,
          hotelname: 'Sea View Resort',
          cityid: 2,
          starRating: 4.5,
          isactive: 1,
          imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?auto=format&fit=crop&q=80',
          startingPrice: 3200.0,
        ),
      ];
    }
  }

  // Fetch rooms for a specific hotel
  Future<List<RoomModel>> getHotelRooms(int hotelId) async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.rooms}?hotelid=$hotelId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          return (data['data'] as List).map((e) => RoomModel.fromJson(e)).toList();
        }
      }
      throw Exception('Failed to load rooms');
    } catch (e) {
      print('API Error (getHotelRooms): $e. Using mock data.');
      return [
        RoomModel(
          roomid: 1,
          hotelid: hotelId,
          roomtypeid: 1,
          roomname: 'Deluxe Sea View',
          capacity: 2,
          totalrooms: 10,
          price: 3200.0,
          roomTypeName: 'Deluxe',
        ),
        RoomModel(
          roomid: 2,
          hotelid: hotelId,
          roomtypeid: 2,
          roomname: 'Presidential Suite',
          capacity: 4,
          totalrooms: 2,
          price: 8500.0,
          roomTypeName: 'Suite',
        ),
      ];
    }
  }
}

final hotelService = HotelService();
