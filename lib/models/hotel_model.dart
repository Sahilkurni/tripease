class HotelModel {
  final String id;
  final String name;
  final String city;
  final double rating;
  final double price;
  final double discount;
  final String imageUrl;
  final List<String> amenities;

  HotelModel({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.price,
    required this.discount,
    required this.imageUrl,
    required this.amenities,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id'],
      name: json['name'],
      city: json['city'],
      rating: json['rating'].toDouble(),
      price: json['price'].toDouble(),
      discount: json['discount'].toDouble(),
      imageUrl: json['imageUrl'],
      amenities: List<String>.from(json['amenities']),
    );
  }
}
