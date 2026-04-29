import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'google_auth_service.dart';

class AuthService {
  // API endpoint - handles both web and mobile platforms
  static String get baseUrl {
    // For web apps, use localhost (XAMPP)
    // For Android emulator, use 10.0.2.2
    // For physical devices, use actual IP
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return 'http://10.0.2.2/tripease_api'; // Android emulator
      }
    } catch (e) {
      // If Platform check fails, we're on web
    }
    // Default for web and other platforms - XAMPP on port 80
    return 'http://localhost/tripease_api';
  }

  final Dio _dio = Dio();
  UserModel? currentUser;

  Future<void> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_session');
    if (userJson != null) {
      currentUser = UserModel.fromJson(jsonDecode(userJson));
    }
  }

  Future<void> saveSession(UserModel user) async {
    currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    try {
      await GoogleAuthService.signOut();
    } catch (e) {
      // Log and ignore sign-out errors (plugin may be missing on some platforms)
      debugPrint('Google sign-out ignored: $e');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/login.php',
        data: FormData.fromMap({'email': email, 'password': password}),
      );

      final data = response.data;
      if (data != null && data['status'] == 'success') {
        final user = UserModel.fromJson(data);
        await saveSession(user);
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data?['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register(
    String fullname,
    String email,
    String password,
    String roleId,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/register.php',
        data: FormData.fromMap({
          'fullname': fullname,
          'email': email,
          'password': password,
          'roleid': roleId,
        }),
      );

      final data = response.data;
      if (data != null && data['status'] == 'success') {
        final user = UserModel.fromJson(data);
        await saveSession(user);
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data?['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> googleSync(
    String email,
    String name,
    String photo,
    String firebaseUid,
  ) async {
    try {
      final response = await _dio.post(
        '$baseUrl/google_auth_sync.php',
        data: FormData.fromMap({
          'email': email,
          'name': name,
          'photo': photo,
          'firebase_uid': firebaseUid,
        }),
      );

      final data = response.data;
      if (data != null && data['status'] == 'success') {
        final isNew = data['is_new_user'] == true;
        final user = UserModel.fromJson(data);
        if (!isNew) {
          await saveSession(user);
        }
        return {'success': true, 'is_new_user': isNew, 'user': user};
      } else {
        return {'success': false, 'message': data?['message'] ?? 'Sync failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateRole(String userId, String roleId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/update_role.php',
        data: FormData.fromMap({'userid': userId, 'roleid': roleId}),
      );

      final data = response.data;
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
      return {'success': false, 'message': e.toString()};
    }
  }
}

// Global instance for simple access
final AuthService authService = AuthService();
