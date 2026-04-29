class BookingModel {
  final String bookingId;
  final String type; // hotel, bus, package
  final String title;
  final String date;
  final String status; // upcoming, completed, cancelled
  final double totalAmount;

  BookingModel({
    required this.bookingId,
    required this.type,
    required this.title,
    required this.date,
    required this.status,
    required this.totalAmount,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'],
      type: json['type'],
      title: json['title'],
      date: json['date'],
      status: json['status'],
      totalAmount: json['totalAmount'].toDouble(),
    );
  }
}
