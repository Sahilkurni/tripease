import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class CustomerProfile {
  final String name;
  final String email;
  final String role;
  final String profilePhoto;
  final String userId;

  const CustomerProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.profilePhoto,
    required this.userId,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      name: (json['name'] ?? json['fullname'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? json['rolename'] ?? 'CUSTOMER').toString(),
      profilePhoto:
          (json['profile_photo'] ?? json['profilephoto'] ?? json['photo'] ?? '')
              .toString(),
      userId: (json['userid'] ?? json['id'] ?? '').toString(),
    );
  }
}

class WishlistItem {
  final int id;
  final String itemType;
  final int itemId;
  final String name;
  final double price;
  final double rating;
  final String imageUrl;

  const WishlistItem({
    required this.id,
    required this.itemType,
    required this.itemId,
    required this.name,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: int.tryParse((json['id'] ?? '0').toString()) ?? 0,
      itemType: (json['item_type'] ?? 'hotel').toString(),
      itemId: int.tryParse((json['item_id'] ?? '0').toString()) ?? 0,
      name: (json['name'] ?? 'Saved item').toString(),
      price: double.tryParse((json['price'] ?? '0').toString()) ?? 0,
      rating: double.tryParse((json['rating'] ?? '0').toString()) ?? 0,
      imageUrl: (json['image'] ?? json['imageUrl'] ?? '').toString(),
    );
  }
}

class CustomerBooking {
  final String bookingId;
  final String itemType;
  final String itemName;
  final String date;
  final double amount;
  final String status;

  const CustomerBooking({
    required this.bookingId,
    required this.itemType,
    required this.itemName,
    required this.date,
    required this.amount,
    required this.status,
  });

  factory CustomerBooking.fromJson(Map<String, dynamic> json) {
    return CustomerBooking(
      bookingId:
          (json['booking_id'] ?? json['bookingid'] ?? json['id'] ?? '')
              .toString(),
      itemType:
          (json['item_type'] ?? json['bookingtype'] ?? json['service'] ?? '')
              .toString(),
      itemName:
          (json['item_name'] ??
                  json['name'] ??
                  json['bookingtype'] ??
                  'Booking')
              .toString(),
      date: (json['date'] ?? json['bookdate'] ?? '').toString(),
      amount: double.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      status: (json['status'] ?? 'PENDING').toString(),
    );
  }
}

class CustomerService {
  String get baseUrl => ApiConfig.baseUrl;

  List<Map<String, dynamic>> _listFromResponse(http.Response response) {
    if (response.body.isEmpty) {
      debugPrint("Warning: Empty response body");
      return [];
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['status'] == 'success') {
      final data = decoded['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => item.map((key, value) => MapEntry('$key', value)))
            .toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _mapFromResponse(http.Response response) {
    if (response.body.isEmpty) {
      debugPrint("Warning: Empty response body");
      return {};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded['status'] == 'success') {
      final data = decoded['data'];
      if (data is Map) {
        return data.map((key, value) => MapEntry('$key', value));
      }
    }
    return {};
  }

  Future<CustomerProfile?> getUserProfile(String userid) async {
    final url = '${baseUrl}get_user_profile.php?userid=$userid';
    print("API URL: $url");
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");
      final data = _mapFromResponse(response);
      return data.isEmpty ? null : CustomerProfile.fromJson(data);
    } catch (e, st) {
      print("Error: $e");
      debugPrint('$st');
      return null;
    }
  }

  Future<List<WishlistItem>> getWishlist(String userid) async {
    final url = '${baseUrl}get_wishlist.php?userid=$userid';
    print("API URL: $url");
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");
      return _listFromResponse(response).map(WishlistItem.fromJson).toList();
    } catch (e, st) {
      print("Error: $e");
      debugPrint('$st');
      return [];
    }
  }

  Future<bool> addToWishlist({
    required String userid,
    required String itemType,
    required int itemId,
  }) async {
    final url = '${baseUrl}add_to_wishlist.php';
    print("API URL: $url");
    try {
      final response = await http
          .post(
            Uri.parse(url),
            body: {
              'userid': userid,
              'item_type': itemType,
              'item_id': itemId.toString(),
            },
          )
          .timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['status'] == 'success';
    } catch (e, st) {
      print("Error: $e");
      debugPrint('$st');
      return false;
    }
  }

  Future<bool> removeFromWishlist({
    required String userid,
    required int id,
  }) async {
    final url = '${baseUrl}remove_from_wishlist.php';
    print("API URL: $url");
    try {
      final response = await http
          .post(
            Uri.parse(url),
            body: {'userid': userid, 'id': id.toString()},
          )
          .timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");
      final decoded = jsonDecode(response.body);
      return decoded is Map && decoded['status'] == 'success';
    } catch (e, st) {
      print("Error: $e");
      debugPrint('$st');
      return false;
    }
  }

  Future<List<CustomerBooking>> getUserBookings(String userid) async {
    final url = '${baseUrl}get_user_bookings.php?userid=$userid';
    print("API URL: $url");
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 12));
      print("Response: ${response.body}");
      return _listFromResponse(response).map(CustomerBooking.fromJson).toList();
    } catch (e, st) {
      print("Error: $e");
      debugPrint('$st');
      return [];
    }
  }
}

final customerService = CustomerService();
