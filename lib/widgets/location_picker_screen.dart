import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedLocation;
  String _address = "Select a location on the map";
  String? _city;
  String? _state;
  bool _isLocating = true;
  bool _isSearching = false;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _isLocating = false;
      _reverseGeocode(_selectedLocation!);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      if (!kIsWeb) {
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _useDefaultLocation();
          return;
        }
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _useDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _useDefaultLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLocating = false;
      });
      _reverseGeocode(_selectedLocation!);
      _mapController.move(_selectedLocation!, 15);
    } catch (e) {
      debugPrint("Location error: $e");
      _useDefaultLocation();
    }
  }

  void _useDefaultLocation() {
    setState(() {
      _isLocating = false;
      _selectedLocation = const LatLng(15.3647, 75.1240); // Hubballi, Karnataka
      _address = "Default location (Hubballi)";
    });
    _reverseGeocode(_selectedLocation!);
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'TripEase_App',
      });

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() => _isSearching = false);
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    try {
      // Using Nominatim API for reverse geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1'
      );
      
      final response = await http.get(url, headers: {
        'User-Agent': 'TripEase_App', // Required by Nominatim policy
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final addressMap = data['address'] as Map<String, dynamic>?;
        
        setState(() {
          _address = data['display_name'] ?? "Address found";
          _city = addressMap?['city'] ?? addressMap?['town'] ?? addressMap?['village'] ?? addressMap?['suburb'];
          _state = addressMap?['state'];
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding error: $e");
      setState(() {
        _address = "Coordinates: ${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Location', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'latitude': null,
                'longitude': null,
                'address': _address,
                'city': _city,
                'state': _state,
              });
            },
            child: Text('SKIP', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          if (_selectedLocation != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'latitude': _selectedLocation!.latitude,
                    'longitude': _selectedLocation!.longitude,
                    'address': _address,
                    'city': _city,
                    'state': _state,
                  });
                },
                child: Text('CONFIRM', style: GoogleFonts.poppins(color: Colors.blue[700], fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
      body: _isLocating
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedLocation ?? const LatLng(15.3647, 75.1240),
                    initialZoom: 15,
                    onTap: (tapPosition, latLng) {
                      setState(() {
                        _selectedLocation = latLng;
                        _searchResults = [];
                        _searchController.clear();
                      });
                      _reverseGeocode(latLng);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tripease.app',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation!,
                            width: 80,
                            height: 80,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
                // Search Bar
                Positioned(
                  top: 10,
                  left: 15,
                  right: 15,
                  child: Column(
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search address...',
                            hintStyle: GoogleFonts.poppins(fontSize: 14),
                            prefixIcon: const Icon(Icons.search, color: Colors.blue),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchResults = []);
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onChanged: (val) {
                            if (val.length > 2) {
                              _searchLocation(val);
                            } else {
                              setState(() => _searchResults = []);
                            }
                          },
                        ),
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (ctx, i) => const Divider(height: 1),
                            itemBuilder: (ctx, i) {
                              final item = _searchResults[i];
                              return ListTile(
                                dense: true,
                                title: Text(
                                  item['display_name'],
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  final lat = double.parse(item['lat']);
                                  final lon = double.parse(item['lon']);
                                  final newLoc = LatLng(lat, lon);
                                  
                                  setState(() {
                                    _selectedLocation = newLoc;
                                    _address = item['display_name'];
                                    _searchResults = [];
                                    _searchController.text = item['display_name'];
                                    // Parse city/state from the item if possible, or just re-reverse geocode
                                  });
                                  
                                  _mapController.move(newLoc, 15);
                                  _reverseGeocode(newLoc); // To get clean city/state breakdown
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _address,
                                            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _selectedLocation != null
                                          ? "Lat: ${_selectedLocation?.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation?.longitude.toStringAsFixed(6)}"
                                          : "Location coordinates not set",
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              if (_selectedLocation != null)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                                  onPressed: () {
                                    setState(() {
                                      _selectedLocation = null;
                                      _address = "No location selected";
                                      _searchController.clear();
                                    });
                                  },
                                  tooltip: "Clear marker",
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }
}
