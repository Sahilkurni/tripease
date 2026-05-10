import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;

  UserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'city': city,
    'state': state,
  };

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
    latitude: json['latitude'],
    longitude: json['longitude'],
    address: json['address'],
    city: json['city'],
    state: json['state'],
  );
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  UserLocation? _currentLocation;
  UserLocation? get currentLocation => _currentLocation;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_location');
    if (saved != null) {
      _currentLocation = UserLocation.fromJson(jsonDecode(saved));
    }
  }

  Future<UserLocation?> refreshLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = await reverseGeocode(position.latitude, position.longitude);
      if (location != null) {
        _currentLocation = location;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_location', jsonEncode(location.toJson()));
      }
      return location;
    } catch (e) {
      debugPrint("Location refresh error: $e");
      return null;
    }
  }

  Future<UserLocation?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'TripEase_App',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addressMap = data['address'] as Map<String, dynamic>?;
        
        return UserLocation(
          latitude: lat,
          longitude: lng,
          address: data['display_name'] ?? "Coordinates: $lat, $lng",
          city: addressMap?['city'] ?? addressMap?['town'] ?? addressMap?['village'] ?? addressMap?['suburb'] ?? "Unknown City",
          state: addressMap?['state'] ?? "Unknown State",
        );
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
    }
    return null;
  }

  void setManualLocation(UserLocation location) async {
    _currentLocation = location;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_location', jsonEncode(location.toJson()));
  }

  double calculateDistance(double endLat, double endLng) {
    if (_currentLocation == null) return 0.0;
    return Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      endLat,
      endLng,
    ) / 1000; // in km
  }
}

final locationService = LocationService();
