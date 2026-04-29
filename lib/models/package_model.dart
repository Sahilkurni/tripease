class PackageModel {
  final String id;
  final String destination;
  final String title;
  final int days;
  final int nights;
  final double price;
  final double rating;
  final String imageUrl;

  PackageModel({
    required this.id,
    required this.destination,
    required this.title,
    required this.days,
    required this.nights,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'],
      destination: json['destination'],
      title: json['title'],
      days: json['days'],
      nights: json['nights'],
      price: json['price'].toDouble(),
      rating: json['rating'].toDouble(),
      imageUrl: json['imageUrl'],
    );
  }
}
