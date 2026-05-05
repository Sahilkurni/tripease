import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AdminService {
  final Dio _dio = Dio();

  String get _apiBase {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return 'http://10.0.2.2/tripease_api';
      }
    } catch (_) {}
    return 'http://localhost/tripease_api';
  }

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
      final data = response.data is String ? jsonDecode(response.data) : response.data;
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

    return {
      'status': 'error',
      'message': 'Invalid API format',
      'data': null,
    };
  }

  /// Get Dashboard Stats
  Future<int> _resolveUserId() async {
    final fromSession = int.tryParse(authService.currentUser?.userid ?? '') ?? 0;
    if (fromSession > 0) return fromSession;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userid') ?? 0;
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        '$_apiBase/admin/get_admin_dashboard_stats.php',
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  /// Get Dashboard Charts
  Future<Map<String, dynamic>> getDashboardCharts() async {
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        '$_apiBase/admin/get_admin_chart_data.php',
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        '$_apiBase/admin/get_all_users.php',
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> updateUserStatus({
    required int targetUserId,
    required bool isActive,
  }) async {
    try {
      final userid = await _resolveUserId();

      final res = await _dio.post(
        '$_apiBase/admin/update_user_status.php',
        data: FormData.fromMap({
          'userid': userid,
          'target_userid': targetUserId,
          'isactive': isActive ? 1 : 0,
        }),
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> getAllPartners() async {
    try {
      final userid = await _resolveUserId();

      final res = await _dio.get(
        '$_apiBase/admin/get_all_partners.php',
        queryParameters: {'userid': userid},
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> updatePartnerStatus({
    required int partnerId,
    required String status,
    double? commission,
  }) async {
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
        '$_apiBase/admin/update_partner_status.php',
        data: FormData.fromMap(payload),
      );
      return _parseResponse(res);
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'data': null,
      };
    }
  }
}

final adminService = AdminService();
