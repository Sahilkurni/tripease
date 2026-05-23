import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'google_auth_service.dart';
import '../core/api_config.dart';

class AuthService extends ChangeNotifier {

  // Use centralized baseUrl from ApiConfig
  static String get baseUrl => ApiConfig.baseUrl;

  final Dio _dio = Dio();
  UserModel? currentUser;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_session');
    if (userJson != null) {
      currentUser = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
    }

  }

  Future<void> saveSession(UserModel user) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user.toJson()));
    final userid = int.tryParse(user.userid);
    if (userid != null) {
      await prefs.setInt('userid', userid);
    }
    if (user.partnerid != null) {
      await prefs.setInt('partnerid', user.partnerid!);
    } else {
      await prefs.remove('partnerid');
    }
    notifyListeners();

  }

  Future<void> clearSession() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    await prefs.remove('userid');
    await prefs.remove('partnerid');
    try {
      await GoogleAuthService.signOut();
    } catch (e) {
      // Log and ignore sign-out errors (plugin may be missing on some platforms)
      // debugPrint('Google sign-out ignored: $e');
    }
    notifyListeners();

  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = ApiConfig.login;
    // debugPrint("API POST -> $url | Body: {email: $email}");
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'email': email, 'password': password},
      );
      // debugPrint("API RESPONSE [${response.statusCode}] -> ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final user = UserModel.fromJson(data['data'] ?? data);
          await saveSession(user);
          return {'success': true, 'user': user};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Login failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      // debugPrint("API ERROR -> $e");
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
    String fullname,
    String email,
    String password,
    String roleId,
  ) async {
    final url = ApiConfig.register;
    // debugPrint("API POST -> $url | Body: {email: $email, roleid: $roleId}");
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'fullname': fullname,
          'email': email,
          'password': password,
          'roleid': roleId,
        },
      );
      // debugPrint("API RESPONSE [${response.statusCode}] -> ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final user = UserModel.fromJson(data['data'] ?? data);
          await saveSession(user);
          return {'success': true, 'user': user};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Registration failed',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      // debugPrint("API ERROR -> $e");
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
  Future<Map<String, dynamic>> sendOtp(String email) async {
    final url = ApiConfig.sendOtp;
    try {
      final response = await http.post(Uri.parse(url), body: {'email': email});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == 'success',
          'message': data['message'] ?? (data['status'] == 'success' ? 'OTP sent successfully' : 'Failed to send OTP'),
        };
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    final url = ApiConfig.verifyOtp;
    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'email': email, 'otp_code': otp},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['status'] == 'success',
          'message': data['message'] ?? (data['status'] == 'success' ? 'OTP verified successfully' : 'Invalid OTP'),
        };
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> googleSync(
    String email,
    String name,
    String photo,
    String firebaseUid,
  ) async {
    final url = '${ApiConfig.baseUrl}google_auth_sync.php';
    // debugPrint("API POST -> $url | Body: {email: $email}");
    try {
      final response = await _dio.post(
        url,
        data: FormData.fromMap({
          'email': email,
          'name': name,
          'photo': photo,
          'firebase_uid': firebaseUid,
        }),
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      // debugPrint("API RESPONSE -> $data");

      if (data != null && data['status'] == 'success') {
        final user = UserModel.fromJson(data['data'] ?? data);
        // Important: Always save session for Google Login
        await saveSession(user);
        return {'success': true, 'is_new_user': data['is_new_user'] == true, 'user': user};
      } else {
        return {'success': false, 'message': data?['message'] ?? 'Sync failed'};
      }
    } catch (e) {
      // debugPrint("API ERROR -> $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateRole(String userId, String roleId) async {
    final url = '${ApiConfig.baseUrl}update_role.php';
    // debugPrint("API POST -> $url | Body: {userid: $userId, roleid: $roleId}");
    try {
      final response = await _dio.post(
        url,
        data: FormData.fromMap({'userid': userId, 'roleid': roleId}),
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      // debugPrint("API RESPONSE -> $data");

      if (data != null && data['status'] == 'success') {
        if (currentUser != null) {
          final updatedData = currentUser!.toJson();
          updatedData['roleid'] = roleId;
          updatedData['rolename'] = data['rolename'];
          currentUser = UserModel.fromJson(updatedData);
          await saveSession(currentUser!);
        }
        return {'success': true, 'rolename': data['rolename']};
      } else {
        return {
          'success': false,
          'message': data?['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      // debugPrint("API ERROR -> $e");
      return {'success': false, 'message': e.toString()};
    }
  }
}

// Global instance for simple access
final AuthService authService = AuthService();
