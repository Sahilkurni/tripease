import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../screens/home/dashboard_screen.dart';

class HomeService {
  String get baseUrl {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return 'http://10.0.2.2/tripease_api';
      }
    } catch (e) {
      debugPrint('baseUrl detection error: $e');
    }
    return 'http://localhost/tripease_api';
  }

  final Dio _dio = Dio();

  Future<List<ServiceItem>> getServices() async {
    try {
      final res = await _dio.get('$baseUrl/get_services.php');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => ServiceItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e, st) {
      debugPrint('getServices error: $e');
      debugPrint('$st');
    }
    return ServiceItem.mock();
  }

  Future<List<OfferItem>> getOffers() async {
    try {
      final res = await _dio.get('$baseUrl/get_offers.php');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => OfferItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e, st) {
      debugPrint('getOffers error: $e');
      debugPrint('$st');
    }
    return OfferItem.mock();
  }

  Future<List<DestinationItem>> getDestinations() async {
    try {
      final res = await _dio.get('$baseUrl/get_destinations.php');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => DestinationItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e, st) {
      debugPrint('getDestinations error: $e');
      debugPrint('$st');
    }
    return DestinationItem.mock();
  }

  Future<List<RecommendedItem>> getRecommended() async {
    try {
      final res = await _dio.get('$baseUrl/get_recommended.php');
      final data = res.data;
      if (data is List) {
        return data
            .map((e) => RecommendedItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e, st) {
      debugPrint('getRecommended error: $e');
      debugPrint('$st');
    }
    return RecommendedItem.mock();
  }
}

final homeService = HomeService();
