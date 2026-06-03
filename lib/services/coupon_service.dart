import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/coupon_model.dart';
import '../models/coupon_usage_model.dart';
import '../core/api_config.dart';

class CouponService {
  Future<List<CouponModel>> getCoupons({
    required int userId,
    String? serviceType,
    int? serviceId,
    String? status,
    String roleView = 'customer',
  }) async {
    String url = '${ApiConfig.getCoupons}?userid=$userId&role_view=$roleView';
    if (serviceType != null) url += '&service_type=$serviceType';
    if (serviceId != null) url += '&service_id=$serviceId';
    if (status != null) url += '&status=$status';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((e) => CouponModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      // print("Error fetching coupons: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> applyCoupon({
    required String couponCode,
    required int userId,
    required double amount,
    required String serviceType,
    int? serviceId,
  }) async {
    String url = '${ApiConfig.applyCoupon}?couponcode=$couponCode&userid=$userId&amount=$amount&service_type=$serviceType';
    if (serviceId != null) url += '&service_id=$serviceId';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } catch (e) {
      // print("Error applying coupon: $e");
      return {'status': 'error', 'message': 'Connection error'};
    }
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.createCoupon), body: data);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded;
    } catch (e) {
      // print("Error creating coupon: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCoupon(Map<String, String> data) async {
    try {
      final response = await http.post(Uri.parse(ApiConfig.updateCoupon), body: data);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded;
    } catch (e) {
      // print("Error updating coupon: $e");
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<bool> deleteCoupon(int couponId, int userId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.deleteCoupon),
        body: {'couponid': couponId.toString(), 'userid': userId.toString()},
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['status'] == 'success';
    } catch (e) {
      // print("Error deleting coupon: $e");
      return false;
    }
  }

  Future<bool> approveCoupon(int couponId, int adminId, String status) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.approveCoupon),
        body: {'couponid': couponId.toString(), 'userid': adminId.toString(), 'status': status},
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['status'] == 'success';
    } catch (e) {
      // print("Error approving coupon: $e");
      return false;
    }
  }

  Future<List<CouponUsageModel>> getCouponUsage(int userId, {int? couponId}) async {
    String url = '${ApiConfig.getCouponUsage}?userid=$userId';
    if (couponId != null) url += '&couponid=$couponId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          return (data['data'] as List).map((e) => CouponUsageModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      // print("Error fetching coupon usage: $e");
      return [];
    }
  }

  Future<bool> recordCouponUsage({
    required int couponId,
    required int userId,
    required int bookingId,
    required String serviceType,
    required int serviceId,
    required double discountAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.recordCouponUsage),
        body: {
          'couponid': couponId.toString(),
          'userid': userId.toString(),
          'bookingid': bookingId.toString(),
          'service_type': serviceType,
          'service_id': serviceId.toString(),
          'discount_amount': discountAmount.toString(),
        },
      );
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['status'] == 'success';
    } catch (e) {
      // print("Error recording coupon usage: $e");
      return false;
    }
  }

  Future<CouponModel?> getBestCoupon({
    required int userId,
    required double amount,
    required String serviceType,
    int? serviceId,
  }) async {
    final coupons = await getCoupons(
      userId: userId,
      serviceType: serviceType,
      serviceId: serviceId,
    );

    if (coupons.isEmpty) return null;

    CouponModel? best;
    double maxSavings = 0;

    for (var coupon in coupons) {
      if (coupon.isValidFor(amount, serviceType, serviceId)) {
        double currentSavings = coupon.calculateSavings(amount);
        if (currentSavings > maxSavings) {
          maxSavings = currentSavings;
          best = coupon;
        }
      }
    }

    return best;
  }
}

final couponService = CouponService();
