import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import '../../services/home_service.dart';
import 'widgets/home_header.dart';
import 'widgets/custom_bottom_nav.dart';
import '../../widgets/custom_footer.dart';
import '../hotels/hotel_details_screen.dart';
import 'package_details_screen.dart';
import '../../models/flight_model.dart';
import '../../services/flight_service.dart';
import '../flights/flight_list_screen.dart';
import '../flights/flight_details_screen.dart';
import '../../widgets/base64_image.dart';
import '../profile/edit_profile_screen.dart';
import 'discovery_map_screen.dart';
import '../../services/location_service.dart';

class ServiceItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  const ServiceItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id']?.toString() ?? '',
      label: json['label'] ?? json['name'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: Icons.travel_explore, // fallback
      gradient: [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
    );
  }
}

class OfferItem {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  const OfferItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  factory OfferItem.fromJson(Map<String, dynamic> json) {
    return OfferItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
    );
  }
}

class DestinationItem {
  final String id;
  final String name;
  final String country;
  final String imageUrl;
  const DestinationItem({
    required this.id,
    required this.name,
    required this.country,
    required this.imageUrl,
  });

  factory DestinationItem.fromJson(Map<String, dynamic> json) {
    return DestinationItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      country: json['country'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
    );
  }
}

class QuickSearchChip {
  final String id;
  final String label;
  const QuickSearchChip({required this.id, required this.label});
}

class RecommendedItem {
  final String id;
  final String name;
  final String location;
  final double rating;
  final double price;
  final String type; // 'hotel' | 'bus' | 'package'
  final String imageUrl;
  final List<String> images;
  final int days;
  final int nights;
  final String? subType; // For Bus Type (AC, Sleeper) or Room Type (Deluxe, etc.)
  final double? latitude;
  final double? longitude;
  final double? distance;

  const RecommendedItem({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.price,
    required this.type,
    required this.imageUrl,
    this.images = const [],
    this.days = 0,
    this.nights = 0,
    this.subType,
    this.latitude,
    this.longitude,
    this.distance,
  });

  factory RecommendedItem.fromJson(Map<String, dynamic> json) {
    return RecommendedItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      rating:
          (json['rating'] is num)
              ? (json['rating'] as num).toDouble()
              : double.tryParse('${json['rating']}') ?? 0.0,
      price:
          (json['price'] is num)
              ? (json['price'] as num).toDouble()
              : double.tryParse('${json['price']}') ?? 0.0,
      type: json['type'] ?? 'hotel',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      days: int.tryParse('${json['days'] ?? 0}') ?? 0,
      nights: int.tryParse('${json['nights'] ?? 0}') ?? 0,
      subType: json['subType'] ?? json['bus_type'] ?? json['room_type'] ?? json['bustype'] ?? 'Standard',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      distance: double.tryParse(json['distance']?.toString() ?? ''),
    );
  }

  factory RecommendedItem.fromHotelJson(Map<String, dynamic> json) {
    return RecommendedItem(
      id: json['hotelid']?.toString() ?? '',
      name: json['hotelname']?.toString() ?? 'Hotel',
      location:
          (json['cityname'] ??
                  json['city'] ??
                  'City ID: ${json['cityid'] ?? '-'}')
              .toString(),
      rating: double.tryParse(json['star_rating']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      type: 'hotel',
      imageUrl:
          (json['image'] ?? json['imageUrl'] ?? json['thumbnail'] ?? '')
              .toString(),
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      subType: json['room_type'] ?? json['roomtype'] ?? json['category'] ?? 'Standard',
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      distance: double.tryParse(json['distance']?.toString() ?? ''),
    );
  }

  factory RecommendedItem.fromPackageJson(Map<String, dynamic> json) {
    return RecommendedItem(
      id: json['packageid']?.toString() ?? '',
      name: json['packagename']?.toString() ?? 'Package',
      location: 'Travel package',
      rating: 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      type: 'package',
      imageUrl:
          (json['thumbnail'] ?? json['image'] ?? json['imageUrl'] ?? '')
              .toString(),
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      days: int.tryParse(json['days']?.toString() ?? '0') ?? 0,
      nights: int.tryParse(json['nights']?.toString() ?? '0') ?? 0,
      subType: json['package_type'] ?? json['category'],
      latitude: double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['longitude']?.toString() ?? ''),
      distance: double.tryParse(json['distance']?.toString() ?? ''),
    );
  }
  @override
  String toString() => 'RecommendedItem($id, $name)';
}

class BookingItem {
  final String id;
  final String type;
  final double amount;
  final String status;
  final String date;

  const BookingItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    return BookingItem(
      id: json['bookingid']?.toString() ?? '',
      type:
          json['bookingtype']?.toString() ?? json['service']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'PENDING',
      date: json['bookdate']?.toString() ?? '',
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;
  List<RecommendedItem> _featuredHotels = [];
  List<RecommendedItem> _featuredPackages = [];
  List<RecommendedItem> _featuredBuses = [];
  List<FlightModel> _featuredFlights = [];
  CustomerProfile? _profile;
  List<WishlistItem> _wishlist = [];
  List<CustomerBooking> _recentBookings = [];
  List<QuickSearchChip> _searchChips = [];
  List<FlightModel> _filteredFlights = [];

  bool _homeLoading = true;
  bool _profileLoading = true;
  bool _wishlistLoading = true;
  bool _bookingsLoading = true;
  String? _homeError;
  static const _userLocation = 'Hubballi, Karnataka';

  late String _selectedLocation;
  Position? _currentPosition;

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  List<RecommendedItem> _filteredHotels = [];
  List<RecommendedItem> _filteredPackages = [];
  List<RecommendedItem> _filteredBuses = [];
  
  double _minPrice = 0;
  double _maxPrice = 100000;
  double _minRating = 0;
  String _sortBy = 'Recommended';
  Set<String> _selectedCategories = {'Hotels', 'Packages', 'Buses', 'Flights'};
  int _maxDuration = 30; // for packages
  Set<String> _selectedBusTypes = {};
  Set<String> _selectedRoomTypes = {};
  String _searchQuery = '';

  late bool isMobile;
  late bool isTablet;
  late bool isDesktop;
  late double hPad;

  static const List<RecommendedItem> _hotelPreviews = [
    RecommendedItem(
      id: 'preview-hotel-1',
      name: 'Skyline Grand Stay',
      location: 'Bengaluru',
      rating: 4.8,
      price: 4299,
      type: 'hotel',
      imageUrl: '',
    ),
    RecommendedItem(
      id: 'preview-hotel-2',
      name: 'Coastal Palm Resort',
      location: 'Goa',
      rating: 4.6,
      price: 5899,
      type: 'hotel',
      imageUrl: '',
    ),
    RecommendedItem(
      id: 'preview-hotel-3',
      name: 'Hillview Comfort Inn',
      location: 'Manali',
      rating: 4.7,
      price: 3199,
      type: 'hotel',
      imageUrl: '',
    ),
  ];

  static const List<RecommendedItem> _packagePreviews = [
    RecommendedItem(
      id: 'preview-package-1',
      name: 'Golden Triangle Escape',
      location: 'Delhi, Agra, Jaipur',
      rating: 4.9,
      price: 14999,
      type: 'package',
      imageUrl: '',
      days: 5,
      nights: 4,
    ),
    RecommendedItem(
      id: 'preview-package-2',
      name: 'Goa Weekend Drift',
      location: 'North Goa',
      rating: 4.7,
      price: 8999,
      type: 'package',
      imageUrl: '',
      days: 3,
      nights: 2,
    ),
    RecommendedItem(
      id: 'preview-package-3',
      name: 'Kerala Backwater Trail',
      location: 'Alleppey',
      rating: 4.8,
      price: 12999,
      type: 'package',
      imageUrl: '',
      days: 4,
      nights: 3,
    ),
  ];

  static const List<RecommendedItem> _busPreviews = [
    RecommendedItem(
      id: 'preview-bus-1',
      name: 'VRL Travels',
      location: 'Hubballi to Bengaluru',
      rating: 4.5,
      price: 1200,
      type: 'bus',
      imageUrl: '',
    ),
    RecommendedItem(
      id: 'preview-bus-2',
      name: 'SRS Travels',
      location: 'Belagavi to Pune',
      rating: 4.3,
      price: 950,
      type: 'bus',
      imageUrl: '',
    ),
    RecommendedItem(
      id: 'preview-bus-3',
      name: 'KSRTC Ambaari',
      location: 'Dharwad to Hyderabad',
      rating: 4.6,
      price: 1850,
      type: 'bus',
      imageUrl: '',
    ),
  ];

  static final List<FlightModel> _flightPreviews = [
    FlightModel(
      flightId: 0,
      airline: 'IndiGo',
      flightNumber: '6E-201',
      fromCity: 1,
      toCity: 2,
      departureTime: '2026-06-01 10:00:00',
      arrivalTime: '2026-06-01 12:30:00',
      duration: '2h 30m',
      price: 4500.00,
      totalSeats: 180,
      availableSeats: 180,
      status: 'approved',
      isActive: 1,
      fromCityName: 'Mumbai',
      toCityName: 'Pune',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = _userLocation;
    _initLocation();
    _loadHomeData();
  }

  Future<void> _initLocation() async {
    await locationService.init();
    if (locationService.currentLocation != null) {
      setState(() {
        _selectedLocation = locationService.currentLocation!.city;
      });
    } else {
      _refreshLocation();
    }
  }

  Future<void> _refreshLocation() async {
    final loc = await locationService.refreshLocation();
    if (loc != null) {
      setState(() {
        _selectedLocation = loc.city;
      });
      // Optional: reload data based on new location
      _loadHomeData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }



  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Options',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const SizedBox(height: 24),
                Text(
                  'Price Range',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  activeColor: AppColors.primary,
                  labels: RangeLabels(
                    '₹${_minPrice.round()}',
                    '₹${_maxPrice.round()}',
                  ),
                  onChanged: (values) {
                    setModalState(() {
                      _minPrice = values.start;
                      _maxPrice = values.end;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('₹${_minPrice.round()}', style: GoogleFonts.poppins()),
                    Text('₹${_maxPrice.round()}', style: GoogleFonts.poppins()),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Minimum Rating',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (index) {
                    final rating = index + 1.0;
                    final isSelected = _minRating == rating;
                    return GestureDetector(
                      onTap: () => setModalState(() => _minRating = rating),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}',
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.amber,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sort By',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Recommended', 'Price: Low to High', 'Price: High to Low', 'Rating: High to Low'].map((option) {
                      final isSelected = _sortBy == option;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (v) => setModalState(() => _sortBy = option),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Service Type',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: ['Hotels', 'Packages', 'Buses', 'Flights'].map((cat) {
                    final isSelected = _selectedCategories.contains(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (v) {
                          setModalState(() {
                            if (v) {
                              _selectedCategories.add(cat);
                            } else {
                              if (_selectedCategories.length > 1) {
                                _selectedCategories.remove(cat);
                              }
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Package Duration (Max Days)',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Slider(
                  value: _maxDuration.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: AppColors.primary,
                  label: '$_maxDuration days',
                  onChanged: (v) => setModalState(() => _maxDuration = v.round()),
                ),
                if (_selectedCategories.contains('Buses')) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Bus Type',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['A/C', 'Non-A/C', 'Sleeper', 'Seater'].map((type) {
                        final isSelected = _selectedBusTypes.contains(type);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (v) {
                              setModalState(() {
                                if (v) {
                                  _selectedBusTypes.add(type);
                                } else {
                                  _selectedBusTypes.remove(type);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (_selectedCategories.contains('Hotels')) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Room Type',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Standard', 'Deluxe', 'Suite', 'Luxury'].map((type) {
                        final isSelected = _selectedRoomTypes.contains(type);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: isSelected,
                            onSelected: (v) {
                              setModalState(() {
                                if (v) {
                                  _selectedRoomTypes.add(type);
                                } else {
                                  _selectedRoomTypes.remove(type);
                                }
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            setModalState(() {
                              _minPrice = 0;
                              _maxPrice = 100000;
                              _minRating = 0;
                              _sortBy = 'Recommended';
                              _selectedCategories = {'Hotels', 'Packages', 'Buses'};
                              _maxDuration = 30;
                              _selectedBusTypes = {};
                              _selectedRoomTypes = {};
                            });
                          },
                          child: Text('Reset', style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: Text('Apply', style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      
      _filteredHotels = _featuredHotels.where((item) {
        final matchesQuery = query.isEmpty || 
                             item.name.toLowerCase().contains(query) || 
                             item.location.toLowerCase().contains(query);
        final matchesPrice = item.price >= _minPrice && item.price <= _maxPrice;
        final matchesRating = item.rating >= _minRating;
        return matchesQuery && matchesPrice && matchesRating;
      }).toList();

      _filteredPackages = _featuredPackages.where((item) {
        final matchesQuery = query.isEmpty || 
                             item.name.toLowerCase().contains(query) || 
                             item.location.toLowerCase().contains(query);
        final matchesPrice = item.price >= _minPrice && item.price <= _maxPrice;
        final matchesRating = item.rating >= _minRating;
        return matchesQuery && matchesPrice && matchesRating;
      }).toList();

      _filteredBuses = _featuredBuses.where((item) {
        final matchesQuery = query.isEmpty || 
                             item.name.toLowerCase().contains(query) || 
                             item.location.toLowerCase().contains(query);
        final matchesPrice = item.price >= _minPrice && item.price <= _maxPrice;
        final matchesRating = item.rating >= _minRating;
        return matchesQuery && matchesPrice && matchesRating;
      }).toList();

      _filteredFlights = _featuredFlights.where((item) {
        final matchesQuery = query.isEmpty || 
                             item.airline.toLowerCase().contains(query) || 
                             (item.fromCityName?.toLowerCase().contains(query) ?? false) ||
                             (item.toCityName?.toLowerCase().contains(query) ?? false);
        final matchesPrice = item.price >= _minPrice && item.price <= _maxPrice;
        return matchesQuery && matchesPrice;
      }).toList();

      // Apply Category Filter
      if (!_selectedCategories.contains('Hotels')) _filteredHotels = [];
      if (!_selectedCategories.contains('Packages')) _filteredPackages = [];
      if (!_selectedCategories.contains('Buses')) _filteredBuses = [];

      // Apply Duration Filter for Packages
      _filteredPackages = _filteredPackages.where((p) => p.days <= _maxDuration).toList();

      // Apply Sorting
      void sortItems(List<RecommendedItem> list) {
        if (_sortBy == 'Price: Low to High') {
          list.sort((a, b) => a.price.compareTo(b.price));
        } else if (_sortBy == 'Price: High to Low') {
          list.sort((a, b) => b.price.compareTo(a.price));
        } else if (_sortBy == 'Rating: High to Low') {
          list.sort((a, b) => b.rating.compareTo(a.rating));
        }
      }

      // Apply Bus Type Filter
      if (_selectedBusTypes.isNotEmpty) {
        _filteredBuses = _filteredBuses.where((bus) {
          if (bus.subType == null) return false;
          return _selectedBusTypes.any((type) => bus.subType!.toLowerCase().contains(type.toLowerCase()));
        }).toList();
      }

      // Apply Room Type Filter
      if (_selectedRoomTypes.isNotEmpty) {
        _filteredHotels = _filteredHotels.where((hotel) {
          if (hotel.subType == null) return false;
          return _selectedRoomTypes.any((type) => hotel.subType!.toLowerCase().contains(type.toLowerCase()));
        }).toList();
      }

      sortItems(_filteredHotels);
      sortItems(_filteredPackages);
      sortItems(_filteredBuses);
    });
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _homeLoading = true;
      _profileLoading = true;
      _wishlistLoading = true;
      _bookingsLoading = true;
      _homeError = null;
    });

    try {
      final userId = authService.currentUser?.userid ?? '';
      final hotels = await homeService.getHomeHotels();
      final packages = await homeService.getHomePackages();
      final buses = await homeService.getHomeBuses();
      
      // Import flight service if not already imported
      final flights = await flightService.getHomeFlights();

      final results = await Future.wait<dynamic>([
        userId.isEmpty
            ? Future<CustomerProfile?>.value(null)
            : customerService.getUserProfile(userId),
        userId.isEmpty
            ? Future<List<WishlistItem>>.value([])
            : customerService.getWishlist(userId),
        userId.isEmpty
            ? Future<List<CustomerBooking>>.value([])
            : customerService.getUserBookings(userId),
      ]);
      if (!mounted) return;

      final chipLabels =
          <String>{
            ...hotels.map(
              (item) => item.location.replaceFirst('City ID: ', 'City '),
            ),
            ...packages.map((item) => item.name),
          }.where((item) => item.trim().isNotEmpty).take(8).toList();

      setState(() {
        _featuredHotels = hotels;
        _featuredPackages = packages;
        _featuredBuses = buses;
        _filteredHotels = hotels;
        _filteredPackages = packages;
        _filteredBuses = buses;
        _featuredFlights = flights;
        _filteredFlights = flights;
        _profile = results[0] as CustomerProfile?;
        _wishlist = results[1] as List<WishlistItem>;
        _recentBookings = results[2] as List<CustomerBooking>;
        _searchChips =
            chipLabels
                .map((label) => QuickSearchChip(id: label, label: label))
                .toList();
        _homeLoading = false;
        _profileLoading = false;
        _wishlistLoading = false;
        _bookingsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _homeLoading = false;
        _profileLoading = false;
        _wishlistLoading = false;
        _bookingsLoading = false;
        _homeError = 'Failed to load dashboard data';
      });
    }
  }

  Future<void> _removeWishlistItem(WishlistItem item) async {
    final userId = authService.currentUser?.userid ?? '';
    if (userId.isEmpty) return;

    final oldItems = List<WishlistItem>.from(_wishlist);
    setState(() {
      _wishlist = _wishlist.where((saved) => saved.id != item.id).toList();
    });

    final ok = await customerService.removeFromWishlist(
      userid: userId,
      id: item.id,
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _wishlist = oldItems);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove wishlist item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    isMobile = screenW < 600;
    isTablet = screenW >= 600 && screenW < 1024;
    isDesktop = screenW >= 1024;
    hPad =
        isDesktop
            ? 48.0
            : isTablet
            ? 32.0
            : 20.0;

    // We use a safe check for dark mode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final safeBot = MediaQuery.of(context).padding.bottom;

    // selected location initialized in initState

    // Main content switches based on bottom navigation index
    Widget mainContent;
    switch (_navIndex) {
      case 1:
        mainContent = _buildBookingsView(safeBot);
        break;
      case 2:
        mainContent = _buildWishlistView(safeBot);
        break;
      case 3:
        mainContent = _buildProfileView(safeBot);
        break;
      case 0:
      default:
        mainContent = CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header
            SliverToBoxAdapter(
              child: HomeHeaderWidget(
                userName:
                    _profile?.name.trim().isNotEmpty == true
                        ? _profile!.name
                        : authService.currentUser?.name ?? 'Traveler',
                location: _selectedLocation,
                onRefresh: _refreshLocation,
                onMapOpen: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DiscoveryMapScreen()),
                  );
                },
              ),
            ),

            // 2. Search bar + chips (overlaps header by 24px)
            SliverToBoxAdapter(child: _buildSearchSection()),

            if (_homeLoading)
              SliverToBoxAdapter(child: _buildHomeLoading())
            else if (_homeError != null)
              SliverToBoxAdapter(child: _buildHomeError())
            else if (_filteredHotels.isEmpty && _filteredPackages.isEmpty && _filteredBuses.isEmpty && _filteredFlights.isEmpty && _searchQuery.isNotEmpty)
              SliverToBoxAdapter(child: _buildNoResultsFound())
            else ...[
              if (_filteredFlights.isNotEmpty || _searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(context, 'Featured Flights', '/flights'),
                ),
                SliverToBoxAdapter(
                  child: _buildFlightSection(
                    items: _filteredFlights,
                  ),
                ),
              ],
              if (_filteredHotels.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(context, 'Featured Hotels', '/hotels'),
                ),
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(
                    items: _filteredHotels,
                    type: 'hotel',
                  ),
                ),
              ],
              if (_filteredPackages.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(
                    context,
                    'Featured Packages',
                    '/packages',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(
                    items: _filteredPackages,
                    type: 'package',
                  ),
                ),
              ],
              if (_filteredBuses.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(context, 'Featured Buses', '/bus_list'),
                ),
                SliverToBoxAdapter(
                  child: _buildFeaturedSection(
                    items: _filteredBuses,
                    type: 'bus',
                  ),
                ),
              ],
              if (_recentBookings.isNotEmpty && _searchQuery.isEmpty) ...[
                SliverToBoxAdapter(
                  child: _sectionHeader(context, 'Recent Bookings', '/bookings'),
                ),
                SliverToBoxAdapter(child: _buildRecentBookingsSection()),
              ],
            ],

            // Footer
            const SliverToBoxAdapter(child: CustomFooter()),

            // Bottom padding for nav bar
            SliverToBoxAdapter(child: SizedBox(height: safeBot + 90)),
          ],
        );
        break;
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      body: Stack(
        children: [
          // page content
          Positioned.fill(child: mainContent),

          // Floating bottom nav (centered + constrained on large screens)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 900 : MediaQuery.of(context).size.width,
                ),
                child: CustomBottomNav(
                  currentIndex: _navIndex,
                  onTap: (i) => setState(() => _navIndex = i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _openLocationPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.03 * 255).round()),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _selectedLocation,
                        style: GoogleFonts.poppins(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Current location button
                    GestureDetector(
                      onTap: () async {
                        await _getCurrentLocation();
                      },
                      child: const Icon(
                        Icons.my_location,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Open maps button
                    GestureDetector(
                      onTap: () async {
                        await _openMaps();
                      },
                      child: const Icon(
                        Icons.map_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Location picker bottom sheet opener
        Transform.translate(
          offset: Offset(
            0,
            isDesktop
                ? 12
                : isTablet
                ? 8
                : 4,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    isDesktop ? 1100 : MediaQuery.of(context).size.width - 16,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.darkCard
                          : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.06 * 255).round()),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _applyFilters(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText:
                              'Search hotels, buses, packages in ${_selectedLocation.split(',').first}...',
                          hintStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _applyFilters();
                                },
                              )
                            : null,
                        ),
                        style: GoogleFonts.poppins(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkText
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscoveryMapScreen())),
                      child: Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8, left: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterBottomSheet(),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Row(
            children:
                _searchChips
                    .map(
                      (chip) => Padding(
                        padding: EdgeInsets.only(
                          right: chip == _searchChips.last ? 0 : 8,
                        ),
                        child: FilterChip(
                          label: Text(chip.label),
                          labelStyle: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          backgroundColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkCard
                                  : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.grey.withAlpha((0.2 * 255).round()),
                            ),
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedLocation = chip.label;
                              _searchController.text = chip.label;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String manual = '';
        return StatefulBuilder(
          builder: (ctx2, setState2) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Location',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        _searchChips.map((c) {
                          final selected =
                              _selectedLocation
                                  .split(',')
                                  .first
                                  .toLowerCase() ==
                              c.label.toLowerCase();
                          return ChoiceChip(
                            label: Text(c.label),
                            selected: selected,
                            onSelected: (v) {
                              setState(() {
                                _selectedLocation = c.label;
                                _searchController.text = c.label;
                                _applyFilters();
                              });
                              Navigator.of(ctx).pop();
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Or enter custom location',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'City, State or Area',
                    ),
                    onChanged: (v) => manual = v,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        setState(() {
                          _selectedLocation = v.trim();
                          _searchController.text = v.trim();
                          _applyFilters();
                        });
                        Navigator.of(ctx).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (manual.trim().isNotEmpty) {
                              setState(() {
                                _selectedLocation = manual.trim();
                                _searchController.text = manual.trim();
                                _applyFilters();
                              });
                              Navigator.of(ctx).pop();
                            }
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.my_location_outlined),
                          label: const Text('Use current location'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _getCurrentLocation().catchError((e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Location error: $e')),
                                );
                              });
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Open in Maps'),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _openMaps().catchError((e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Maps error: $e')),
                                );
                              });
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled.')),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them from settings.',
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _currentPosition = pos;
        _selectedLocation =
            '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
        _applyFilters();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  Future<void> _openMaps() async {
    try {
      if (_currentPosition != null) {
        final lat = _currentPosition!.latitude;
        final lng = _currentPosition!.longitude;
        final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
        }
        return;
      }

      // If we don't have coordinates, open maps with the selected location string
      final query = Uri.encodeComponent(_selectedLocation);
      final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Maps error: $e')));
    }
  }

  Widget _buildBookingsView(double safeBot) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, safeBot + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bookings',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _bookingsLoading
                      ? _buildBookingSkeletonList()
                      : _recentBookings.isEmpty
                      ? _CustomerEmptyState(
                        icon: Icons.confirmation_number_rounded,
                        title: 'No bookings yet',
                        subtitle: 'Start exploring trips',
                        actionLabel: 'Explore',
                        onAction: () => setState(() => _navIndex = 0),
                      )
                      : _buildBookingsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsList() {
    final isWide = MediaQuery.of(context).size.width >= 900;
    if (isWide) {
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420,
          mainAxisExtent: 150,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _recentBookings.length,
        itemBuilder:
            (_, i) => _CustomerBookingCard(booking: _recentBookings[i]),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: _recentBookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _CustomerBookingCard(booking: _recentBookings[i]),
    );
  }

  Widget _buildBookingSkeletonList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _ListSkeletonTile(),
    );
  }

  Widget _buildWishlistView(double safeBot) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, safeBot + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wishlist',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _wishlistLoading
                      ? _buildWishlistSkeletons()
                      : _wishlist.isEmpty
                      ? _CustomerEmptyState(
                        icon: Icons.favorite_rounded,
                        title: 'Your wishlist is empty',
                        subtitle: 'Start saving your favorite places',
                        actionLabel: 'Explore',
                        onAction: () => setState(() => _navIndex = 0),
                      )
                      : _buildWishlistCards(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistSkeletons() {
    if (MediaQuery.of(context).size.width >= 700) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 300,
                child: _HomeSkeletonCard(isPackage: false),
              ),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _HomeSkeletonCard(isPackage: false),
    );
  }

  Widget _buildWishlistCards() {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) {
      return GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 330,
          mainAxisExtent: 250,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _wishlist.length,
        itemBuilder:
            (_, i) => _WishlistCard(
              item: _wishlist[i],
              onRemove: () => _removeWishlistItem(_wishlist[i]),
            ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children:
            _wishlist
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: SizedBox(
                      width: width < 420 ? width - (hPad * 2) : 300,
                      child: _WishlistCard(
                        item: item,
                        onRemove: () => _removeWishlistItem(item),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildProfileView(double safeBot) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, safeBot + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  _profileLoading
                      ? const _ProfileSkeletonCard()
                      : Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _ProfileSummaryCard(
                            profile: _profile,
                            fallbackUser: authService.currentUser,
                            onRefresh: _loadHomeData,
                            onSignOut: () async {
                              await authService.clearSession();
                              if (!mounted) return;
                              context.go('/login');
                            },
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    String seeAllRoute,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.w700,
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.darkText
                      : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              context.push(seeAllRoute);
            },
            child: Text(
              'See All',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No results found',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find anything matching "$_searchQuery".\nTry adjusting your search or filters.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _minPrice = 0;
                _maxPrice = 100000;
                _minRating = 0;
                _applyFilters();
              });
            },
            child: Text(
              'Clear all filters',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context, 'Featured Hotels', '/hotels'),
          _buildSkeletonRail(isPackage: false),
          _sectionHeader(context, 'Featured Packages', '/packages'),
          _buildSkeletonRail(isPackage: true),
        ],
      ),
    );
  }

  Widget _buildSkeletonRail({required bool isPackage}) {
    if (isMobile) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Column(
          children: List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _HomeSkeletonCard(isPackage: isPackage),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(right: 14),
            child: SizedBox(
              width: isDesktop ? 330 : 300,
              child: _HomeSkeletonCard(isPackage: isPackage),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeError() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 42, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              _homeError ?? 'Failed to load data',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _loadHomeData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection({
    required List<RecommendedItem> items,
    required String type,
  }) {
    final isPackage = type == 'package';
    final hasData = items.isNotEmpty;
    final displayItems = hasData ? items : (isPackage ? _packagePreviews : (type == 'bus' ? _busPreviews : _hotelPreviews));

    // If no data, we still show the section with demo cards (preview items)
    // We remove the Empty State widget as requested and show the cards directly with a "Demo" label
    
    final cards = displayItems.map((item) {
      return GestureDetector(
        onTap: () {
          if (isPackage) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PackageDetailsScreen(
                  packageId: item.id,
                  packageName: item.name,
                  price: item.price,
                  imageUrl: item.imageUrl,
                  images: item.images,
                ),
              ),
            );
          } else if (type == 'bus') {
            // Navigate to seat selection for the selected bus trip
            context.push('/bus/seats', extra: item);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HotelDetailsScreen(
                  hotelId: item.id,
                  hotelName: item.name,
                  imageUrl: item.imageUrl,
                  images: item.images,
                ),
              ),
            );
          }
        },
        child: SizedBox(
          width: isDesktop ? 330 : 300,
          child: isPackage
              ? _PremiumPackageCard(item: item, preview: !hasData)
              : type == 'bus'
              ? _PremiumBusCard(item: item, preview: !hasData)
              : _PremiumHotelCard(item: item, preview: !hasData),
        ),
      );
    }).toList();

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: card,
        )).toList(),
      ),
    );
  }

  Widget _buildFlightSection({
    required List<FlightModel> items,
  }) {
    final hasData = items.isNotEmpty;
    final displayItems = hasData ? items : _flightPreviews;

    final cards = displayItems.map((item) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FlightDetailsScreen(flight: item),
            ),
          );
        },
        child: SizedBox(
          width: isDesktop ? 330 : 300,
          child: _PremiumFlightCard(item: item, preview: !hasData),
        ),
      );
    }).toList();

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(
        children: cards.map((card) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: card,
        )).toList(),
      ),
    );
  }

  Widget _buildRecentBookingsSection() {
    if (_recentBookings.isEmpty) {
      return _emptyBand('No bookings yet');
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Column(
        children:
            _recentBookings
                .map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _CustomerBookingCard(booking: booking),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _emptyBand(String message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha(40)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CustomerEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _CustomerEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(14),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: isDark ? AppColors.darkText : AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: Text(actionLabel),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _ProfileSummaryCard extends StatelessWidget {
  final CustomerProfile? profile;
  final UserModel? fallbackUser;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onRefresh;

  const _ProfileSummaryCard({
    required this.profile,
    required this.fallbackUser,
    required this.onSignOut,
    required this.onRefresh,
  });

  String get _name {
    final value = profile?.name.trim();
    if (value != null && value.isNotEmpty) return value;
    return fallbackUser?.name.trim().isNotEmpty == true
        ? fallbackUser!.name.trim()
        : 'Traveler';
  }

  String get _email {
    final value = profile?.email.trim();
    if (value != null && value.isNotEmpty) return value;
    return fallbackUser?.email.trim() ?? '';
  }

  String get _role {
    final value = profile?.role.trim();
    if (value != null && value.isNotEmpty) return value;
    return fallbackUser?.rolename?.trim().isNotEmpty == true
        ? fallbackUser!.rolename!.trim()
        : 'CUSTOMER';
  }

  String get _photo {
    final value = profile?.profilePhoto.trim();
    if (value != null && value.isNotEmpty) return value;
    return fallbackUser?.photo?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      _photo.isEmpty
                          ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                          )
                          : null,
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    _photo.isEmpty
                        ? Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )
                        : Base64Image(
                            base64String: _photo,
                            fit: BoxFit.cover,
                          ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color:
                            isDark ? AppColors.darkText : AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email.isEmpty ? 'Email not available' : _email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color:
                            isDark
                                ? AppColors.darkSubtext
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _RoleBadge(role: _role),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    userData: {
                      'userid': profile?.userId ?? fallbackUser?.userid ?? '',
                      'fullname': _name,
                      'email': _email,
                      'photo': _photo,
                      'role': _role,
                    },
                  ),
                ),
              );
              if (result == true) {
                onRefresh(); // Refresh dashboard data
              }
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(
              'Edit Profile',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'Sign Out',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF14B8A6).withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.poppins(
          color: const Color(0xFF0F766E),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  final WishlistItem item;
  final VoidCallback onRemove;

  const _WishlistCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                TravelImagePlaceholder(
                  imageUrl: item.imageUrl,
                  icon:
                      item.itemType == 'package'
                          ? Icons.flight_takeoff_rounded
                          : item.itemType.toLowerCase().contains('flight') ? Icons.flight_takeoff_rounded : Icons.hotel_rounded,
                  colors:
                      item.itemType == 'package'
                          ? const [Color(0xFFDB2777), Color(0xFFF59E0B)]
                          : const [Color(0xFF2563EB), Color(0xFF14B8A6)],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton.filled(
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      item.price > 0
                          ? '₹${item.price.toStringAsFixed(0)}'
                          : 'View details',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.rating > 0 ? item.rating.toStringAsFixed(1) : '4.5',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerBookingCard extends StatelessWidget {
  final CustomerBooking booking;

  const _CustomerBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        if (booking.itemType.toLowerCase().contains('flight')) {
          context.push('/flight_bookings');
        }
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              booking.itemType.toLowerCase().contains('package')
                  ? Icons.card_travel_rounded
                  : booking.itemType.toLowerCase().contains('flight')
                      ? Icons.flight_takeoff_rounded
                      : booking.itemType.toLowerCase().contains('bus')
                          ? Icons.directions_bus_rounded
                          : Icons.hotel_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  booking.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  booking.date.isEmpty ? 'Date unavailable' : booking.date,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color:
                        isDark
                            ? AppColors.darkSubtext
                            : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '₹${booking.amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _BookingStatusBadge(status: booking.status),
        ],
      ),
    ),
  );
}
}

class _BookingStatusBadge extends StatelessWidget {
  final String status;

  const _BookingStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toUpperCase();
    final isCancelled = normalized.contains('CANCEL');
    final isConfirmed =
        normalized.contains('CONFIRM') ||
        normalized.contains('COMPLETE') ||
        normalized.contains('PAID');
    final color =
        isCancelled
            ? const Color(0xFFDC2626)
            : isConfirmed
            ? const Color(0xFF059669)
            : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        normalized.isEmpty ? 'PENDING' : normalized,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileSkeletonCard extends StatelessWidget {
  const _ProfileSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: const _ListSkeletonTile(height: 210),
      ),
    );
  }
}

class _ListSkeletonTile extends StatefulWidget {
  final double height;

  const _ListSkeletonTile({this.height = 132});

  @override
  State<_ListSkeletonTile> createState() => _ListSkeletonTileState();
}

class _ListSkeletonTileState extends State<_ListSkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _color = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder:
          (_, __) => Container(
            height: widget.height,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _color.value,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBar(width: 180, color: _color.value),
                      const SizedBox(height: 12),
                      _SkeletonBar(width: 130, color: _color.value),
                      const SizedBox(height: 12),
                      _SkeletonBar(width: 90, color: _color.value),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _PremiumEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color:
                        isDark
                            ? AppColors.darkSubtext
                            : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumHotelCard extends StatelessWidget {
  final RecommendedItem item;
  final bool preview;

  const _PremiumHotelCard({required this.item, required this.preview});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = item.price > 0 ? item.price : 3499;
    return Container(
      height: 252,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                TravelImagePlaceholder(
                  imageUrl: item.imageUrl,
                  images: item.images,
                  icon: Icons.hotel_rounded,
                  colors: const [Color(0xFF2563EB), Color(0xFF14B8A6)],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _PriceBadge(label: '₹${price.toStringAsFixed(0)}'),
                ),
                if (preview)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _SoftBadge(label: 'Preview'),
                  ),
                if (item.distance != null && item.distance! > 0)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _SoftBadge(label: '${item.distance!.toStringAsFixed(1)} km away', color: Colors.blue[700]),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color:
                              isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      item.rating > 0 ? item.rating.toStringAsFixed(1) : '4.5',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPackageCard extends StatelessWidget {
  final RecommendedItem item;
  final bool preview;

  const _PremiumPackageCard({required this.item, required this.preview});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final days = item.days > 0 ? item.days : 3;
    final nights = item.nights > 0 ? item.nights : (days - 1).clamp(1, 10);
    return Container(
      height: 252,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                TravelImagePlaceholder(
                  imageUrl: item.imageUrl,
                  images: item.images,
                  icon: Icons.map_rounded,
                  colors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _GradientBadge(label: '$days Days / $nights Nights'),
                ),
                if (preview)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _SoftBadge(label: 'Preview'),
                  ),
                if (item.distance != null && item.distance! > 0)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _SoftBadge(label: '${item.distance!.toStringAsFixed(1)} km away', color: Colors.blue[700]),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color:
                              isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFDB2777),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TravelImagePlaceholder extends StatefulWidget {
  final String imageUrl;
  final List<String>? images;
  final IconData icon;
  final List<Color> colors;

  const TravelImagePlaceholder({
    required this.imageUrl,
    this.images,
    required this.icon,
    required this.colors,
  });

  @override
  State<TravelImagePlaceholder> createState() => TravelImagePlaceholderState();
}

class TravelImagePlaceholderState extends State<TravelImagePlaceholder> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = (widget.images != null && widget.images!.isNotEmpty)
        ? widget.images!
        : (widget.imageUrl.trim().isNotEmpty ? [widget.imageUrl] : <String>[]);

    if (displayImages.isNotEmpty) {
      if (displayImages.length == 1) {
        return Base64Image(
          base64String: displayImages.first,
          fit: BoxFit.cover,
        );
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: displayImages.length,
            itemBuilder: (context, index) {
              return Base64Image(
                base64String: displayImages[index],
                fit: BoxFit.cover,
              );
            },
          ),
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                displayImages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: _currentIndex == index ? 6 : 4,
                  height: _currentIndex == index ? 6 : 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white.withAlpha(128),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(widget.icon, color: Colors.white.withAlpha(210), size: 54),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final String label;

  const _PriceBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return _SoftBadge(label: label);
  }
}

class _SoftBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const _SoftBadge({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color ?? AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GradientBadge extends StatelessWidget {
  final String label;

  const _GradientBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDB2777), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HomeSkeletonCard extends StatefulWidget {
  final bool isPackage;

  const _HomeSkeletonCard({required this.isPackage});

  @override
  State<_HomeSkeletonCard> createState() => _HomeSkeletonCardState();
}

class _HomeSkeletonCardState extends State<_HomeSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _color = ColorTween(
      begin: Colors.grey.shade200,
      end: Colors.grey.shade100,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _color,
      builder:
          (_, __) => Container(
            height: 252,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _color.value,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _SkeletonBar(width: 180, color: _color.value),
                const SizedBox(height: 10),
                _SkeletonBar(width: 120, color: _color.value),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _SkeletonBar(width: 80, color: _color.value),
                    const Spacer(),
                    _SkeletonBar(
                      width: widget.isPackage ? 90 : 58,
                      color: _color.value,
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double width;
  final Color? color;

  const _SkeletonBar({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _PremiumBusCard extends StatelessWidget {
  final RecommendedItem item;
  final bool preview;

  const _PremiumBusCard({required this.item, required this.preview});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 252,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                TravelImagePlaceholder(
                  imageUrl: item.imageUrl,
                  images: item.images,
                  icon: Icons.directions_bus_rounded,
                  colors: const [Color(0xFF8B5CF6), Color(0xFFD946EF)],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _GradientBadge(label: '₹${item.price.toStringAsFixed(0)}'),
                ),
                if (preview)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _SoftBadge(label: 'Demo'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color:
                              isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '4.5',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumFlightCard extends StatelessWidget {
  final FlightModel item;
  final bool preview;

  const _PremiumFlightCard({required this.item, required this.preview});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 252,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                TravelImagePlaceholder(
                  imageUrl: item.image ?? '',
                  images: item.images,
                  icon: Icons.flight_rounded,
                  colors: const [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _SoftBadge(label: '₹${item.price.toStringAsFixed(0)}'),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.airline,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (preview)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: _SoftBadge(label: 'Preview'),
                  ),
                if (item.distance != null && item.distance! > 0)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: _SoftBadge(label: '${item.distance!.toStringAsFixed(1)} km away', color: Colors.blue[700]),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.fromCityName ?? 'From'} → ${item.toCityName ?? 'To'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: isDark ? AppColors.darkText : AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.departureTime.split(' ').last.substring(0, 5),
                      style: GoogleFonts.poppins(
                        color: isDark ? AppColors.darkSubtext : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      item.duration,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
