import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../../services/location_service.dart';
import '../../widgets/base64_image.dart';
import '../hotels/hotel_details_screen.dart';
import '../home/package_details_screen.dart';
import '../flights/flight_details_screen.dart';
import '../../models/flight_model.dart';
import 'dashboard_screen.dart';

class DiscoveryMapScreen extends StatefulWidget {
  const DiscoveryMapScreen({super.key});

  @override
  State<DiscoveryMapScreen> createState() => _DiscoveryMapScreenState();
}

class _DiscoveryMapScreenState extends State<DiscoveryMapScreen> {
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Hotels', 'Buses', 'Packages', 'Flights'];
  
  List<RecommendedItem> _hotels = [];
  List<RecommendedItem> _buses = [];
  List<RecommendedItem> _packages = [];
  List<FlightModel> _flights = [];
  
  @override
  void initState() {
    super.initState();
    _fetchNearbyItems();
  }

  Future<void> _fetchNearbyItems() async {
    final loc = locationService.currentLocation;
    if (loc == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse(
        '${ApiConfig.nearbyItems}?lat=${loc.latitude}&lng=${loc.longitude}&radius=100'
      ));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final items = data['data'];
          setState(() {
            _hotels = (items['hotels'] as List? ?? []).map<RecommendedItem>((h) => RecommendedItem.fromHotelJson(Map<String, dynamic>.from(h))).toList();
            _buses = (items['buses'] as List? ?? []).map((row) => RecommendedItem(
              id: row['busid']?.toString() ?? row['id']?.toString() ?? '',
              name: row['bus_name'] ?? row['name'] ?? 'Bus',
              location: '${row['source_city_id'] ?? ''} to ${row['destination_city_id'] ?? ''}',
              rating: 4.2,
              price: double.tryParse(row['base_fare']?.toString() ?? row['price']?.toString() ?? '0') ?? 0,
              type: 'bus',
              imageUrl: '',
              latitude: double.tryParse(row['latitude']?.toString() ?? ''),
              longitude: double.tryParse(row['longitude']?.toString() ?? ''),
            )).toList();
            _packages = (items['packages'] as List? ?? []).map<RecommendedItem>((p) => RecommendedItem.fromPackageJson(Map<String, dynamic>.from(p))).toList();
            _flights = (items['flights'] as List? ?? []).map<FlightModel>((f) => FlightModel.fromJson(Map<String, dynamic>.from(f))).toList();
            _isLoading = false;
          });

          // Debug logs to help the user
          // debugPrint("Map Stats:");
          // debugPrint("Hotels: ${_hotels.length} total, ${_hotels.where((h) => h.latitude != null && h.longitude != null).length} with coords");
          // debugPrint("Buses: ${_buses.length} total, ${_buses.where((b) => b.latitude != null && b.longitude != null).length} with coords");
          // debugPrint("Packages: ${_packages.length} total, ${_packages.where((p) => p.latitude != null && p.longitude != null).length} with coords");
          // debugPrint("Flights: ${_flights.length} total, ${_flights.where((f) => f.latitude != null && f.longitude != null).length} with coords");
        }
      }
    } catch (e) {
      // debugPrint("Fetch nearby error: $e");
      setState(() => _isLoading = false);
    }
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];
    final loc = locationService.currentLocation;
    
    // User location marker
    if (loc != null) {
      markers.add(Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: 60,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 30),
        ),
      ));
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Hotels') {
      markers.addAll(_hotels.where((h) => h.latitude != null && h.longitude != null).map((h) => Marker(
        point: LatLng(h.latitude!, h.longitude!),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => _showItemDetails(h),
          child: _MarkerWidget(icon: Icons.apartment_rounded, color: Colors.indigo),
        ),
      )));
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Buses') {
      markers.addAll(_buses.where((b) => b.latitude != null && b.longitude != null).map((b) => Marker(
        point: LatLng(b.latitude!, b.longitude!),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => _showItemDetails(b),
          child: _MarkerWidget(icon: Icons.directions_bus_rounded, color: Colors.orange),
        ),
      )));
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Packages') {
      markers.addAll(_packages.where((p) => p.latitude != null && p.longitude != null).map((p) => Marker(
        point: LatLng(p.latitude!, p.longitude!),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => _showItemDetails(p),
          child: _MarkerWidget(icon: Icons.card_giftcard_rounded, color: Colors.teal),
        ),
      )));
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Flights') {
      markers.addAll(_flights.where((f) => f.latitude != null && f.longitude != null).map((f) => Marker(
        point: LatLng(f.latitude!, f.longitude!),
        width: 45,
        height: 45,
        child: GestureDetector(
          onTap: () => _showFlightDetails(f),
          child: _MarkerWidget(icon: Icons.flight_takeoff_rounded, color: Colors.pink),
        ),
      )));
    }

    return markers;
  }

  void _showItemDetails(RecommendedItem item) {
    final distance = locationService.calculateDistance(item.latitude!, item.longitude!);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemDetailsSheet(item: item, distance: distance),
    );
  }

  void _showFlightDetails(FlightModel flight) {
    final distance = locationService.calculateDistance(flight.latitude!, flight.longitude!);
    // Create a dummy RecommendedItem for the sheet logic
    final item = RecommendedItem(
      id: flight.flightId.toString(),
      name: '${flight.airline} (${flight.flightNumber})',
      location: '${flight.fromCityName} to ${flight.toCityName}',
      rating: 4.8,
      price: flight.price,
      type: 'flight',
      imageUrl: '',
      latitude: flight.latitude,
      longitude: flight.longitude,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ItemDetailsSheet(item: item, distance: distance, flight: flight),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = locationService.currentLocation;
    
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: loc != null ? LatLng(loc.latitude, loc.longitude) : const LatLng(20.5937, 78.9629),
              initialZoom: 11,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tripease.app',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          
          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Theme.of(context).cardColor,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Filter Chips
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 70,
            right: 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((f) {
                  final selected = _selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f, style: GoogleFonts.poppins(
                        color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      )),
                      selected: selected,
                      onSelected: (v) => setState(() => _selectedFilter = f),
                      backgroundColor: Theme.of(context).cardColor,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      checkmarkColor: Colors.white,
                      elevation: 2,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
            
          // My Location Button
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Theme.of(context).cardColor,
              onPressed: () {
                if (loc != null) {
                  _mapController.move(LatLng(loc.latitude, loc.longitude), 14);
                }
              },
              child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerWidget extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _MarkerWidget({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _ItemDetailsSheet extends StatelessWidget {
  final RecommendedItem item;
  final double distance;
  final FlightModel? flight;

  const _ItemDetailsSheet({required this.item, required this.distance, this.flight});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: Base64Image(
                      base64String: item.imageUrl,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.location,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber[700], size: 16),
                          Text(' ${item.rating} ', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                          Spacer(),
                          Text('${distance.toStringAsFixed(1)} km away', style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.price.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontSize: 18, color: Colors.green[700], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (item.type == 'hotel') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailsScreen(
                      hotelId: item.id,
                      hotelName: item.name,
                      imageUrl: item.imageUrl,
                    )));
                  } else if (item.type == 'package') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PackageDetailsScreen(
                      packageId: item.id,
                      packageName: item.name,
                      price: item.price,
                      imageUrl: item.imageUrl,
                      images: item.images,
                    )));
                  } else if (item.type == 'flight' && flight != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => FlightDetailsScreen(flight: flight!)));
                  }
                },
                child: Text('VIEW DETAILS', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
