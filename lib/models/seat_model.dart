class SeatModel {
  final int seatId;
  final int flightId;
  final String seatNumber;
  final String seatType;
  final int isBooked;
  bool isSelected;

  SeatModel({
    required this.seatId,
    required this.flightId,
    required this.seatNumber,
    required this.seatType,
    required this.isBooked,
    this.isSelected = false,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      seatId: int.parse(json['seatid'].toString()),
      flightId: int.parse(json['flightid'].toString()),
      seatNumber: json['seat_number'] ?? '',
      seatType: json['seat_type'] ?? 'economy',
      isBooked: int.parse(json['is_booked'].toString()),
    );
  }
}
