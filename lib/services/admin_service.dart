import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import '../core/api_config.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final Dio _dio = Dio();

  String get _apiBase => ApiConfig.baseUrl;

  /// Strict API response parser
  Map<String, dynamic> _parseResponse(Response response) {
    if (response.statusCode != 200) {
      return {
        'status': 'error',
        'message': 'Server error: ${response.statusCode}',
        'data': null,
      };
    }

    try {
      // print(response.data);
      final data =
          response.data is String ? jsonDecode(response.data) : response.data;
      if (data is Map<String, dynamic>) {
        return {
          'status': data['status'] ?? 'error',
          'message': data['message'] ?? 'Unknown error',
          'data': data['data'],
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to parse API response: $e',
        'data': null,
      };
    }

    return {'status': 'error', 'message': 'Invalid API format', 'data': null};
  }

  /// Get Dashboard Stats
  Future<int> _resolveUserId() async {
    final fromSession =
        int.tryParse(authService.currentUser?.userid ?? '') ?? 0;
    if (fromSession > 0) return fromSession;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userid') ?? 0;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final url = '${_apiBase}admin/get_admin_dashboard_stats.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  /// Get Dashboard Charts
  Future<Map<String, dynamic>> getDashboardCharts() async {
    final url = '${_apiBase}admin/get_admin_chart_data.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    final url = '${_apiBase}admin/get_all_users.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> updateUserStatus({
    required int targetUserId,
    required bool isActive,
  }) async {
    final url = '${_apiBase}admin/update_user_status.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();

      final res = await _dio.post(
        url,
        data: FormData.fromMap({
          'userid': userid,
          'target_userid': targetUserId,
          'isactive': isActive ? 1 : 0,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllPartners() async {
    final url = '${_apiBase}admin/get_all_partners.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> updatePartnerStatus({
    required int partnerId,
    required String status,
    double? commission,
  }) async {
    final url = '${_apiBase}admin/update_partner_status.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();

      final payload = <String, dynamic>{
        'userid': userid,
        'partnerid': partnerId,
        'status': status,
      };
      if (commission != null) {
        payload['commission'] = commission;
      }

      final res = await _dio.post(
        url,
        data: FormData.fromMap(payload),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllHotels() async {
    final url = '${_apiBase}admin/get_all_hotels.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.get(url, queryParameters: {'userid': userid});
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> updateHotelStatus({
    required int hotelId,
    required String status,
  }) async {
    final url = '${_apiBase}admin/update_hotel_status.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.post(
        url,
        data: FormData.fromMap({
          'userid': userid,
          'hotelid': hotelId,
          'status': status,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllPackages() async {
    final url = '${_apiBase}admin/get_all_packages.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.get(url, queryParameters: {'userid': userid});
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> updatePackageStatus({
    required int packageId,
    required String status,
  }) async {
    final url = '${_apiBase}admin/update_package_status.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.post(
        url,
        data: FormData.fromMap({
          'userid': userid,
          'packageid': packageId,
          'status': status,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllBuses() async {
    final url = '${_apiBase}admin/get_all_buses.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> updateBusStatus({
    required int busId,
    required String status,
  }) async {
    final url = '${_apiBase}admin/update_bus_status.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.post(
        url,
        data: FormData.fromMap({
          'userid': userid,
          'busid': busId,
          'status': status,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllBookings() async {
    final url = '${_apiBase}admin/get_all_bookings.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllPayments() async {
    final url = '${_apiBase}admin/get_all_payments.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getAllCoupons() async {
    final url = '${_apiBase}admin/get_all_coupons.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    double minBookingAmount = 0,
    double maxDiscount = 0,
    String? validUntil,
    int isActive = 1,
  }) async {
    final url = '${_apiBase}admin/create_coupon.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.post(
        url,
        data: FormData.fromMap({
          'userid': userid,
          'code': code,
          'discount_type': discountType,
          'discount_value': discountValue,
          'min_booking_amount': minBookingAmount,
          'max_discount': maxDiscount,
          'valid_until': validUntil,
          'isactive': isActive,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> updateCouponStatus({
    required int couponId,
    required int isActive,
  }) async {
    final url = '${_apiBase}admin/update_coupon_status.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.post(
        url,
        data: FormData.fromMap({
          'userid': userid,
          'couponid': couponId,
          'isactive': isActive,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> updateCouponApproval({
    required int couponId,
    required String status,
  }) async {
    final url = '${_apiBase}admin/update_coupon_approval.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.post(
        url,
        data: FormData.fromMap({
          'userid': userid,
          'couponid': couponId,
          'status': status,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }

  Future<Map<String, dynamic>> getSupportTickets() async {
    final url = '${_apiBase}admin/get_support_tickets.php';
    // print("API URL: $url");
    try {
      final userid = await _resolveUserId();
      final res = await _dio.get(
        url,
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      // print("Error: $e");
      return {'status': 'error', 'message': 'Network error: $e', 'data': null};
    }
  }
}

final adminService = AdminService();
