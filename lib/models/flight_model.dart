class FlightModel {
  final int flightId;
  final String airline;
  final String flightNumber;
  final int fromCity;
  final int toCity;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double price;
  final int totalSeats;
  final int availableSeats;
  final String status;
  final int isActive;
  final int? createdBy;
  final String? fromCityName;
  final String? toCityName;

  FlightModel({
    required this.flightId,
    required this.airline,
    required this.flightNumber,
    required this.fromCity,
    required this.toCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.totalSeats,
    required this.availableSeats,
    required this.status,
    required this.isActive,
    this.createdBy,
    this.fromCityName,
    this.toCityName,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      flightId: int.parse(json['flightid'].toString()),
      airline: json['airline'] ?? '',
      flightNumber: json['flight_number'] ?? '',
      fromCity: int.parse(json['from_city'].toString()),
      toCity: int.parse(json['to_city'].toString()),
      departureTime: json['departure_time'] ?? '',
      arrivalTime: json['arrival_time'] ?? '',
      duration: json['duration'] ?? '',
      price: double.parse(json['price'].toString()),
      totalSeats: int.parse(json['total_seats'].toString()),
      availableSeats: int.parse(json['available_seats'].toString()),
      status: json['status'] ?? 'pending',
      isActive: int.parse(json['isactive'].toString()),
      createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
      fromCityName: json['from_city_name'],
      toCityName: json['to_city_name'],
    );
  }
}
