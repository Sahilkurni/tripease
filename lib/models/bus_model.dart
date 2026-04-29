class BusModel {
  final String id;
  final String operatorName;
  final String source;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double fare;

  BusModel({
    required this.id,
    required this.operatorName,
    required this.source,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.fare,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      id: json['id'],
      operatorName: json['operatorName'],
      source: json['source'],
      destination: json['destination'],
      departureTime: json['departureTime'],
      arrivalTime: json['arrivalTime'],
      duration: json['duration'],
      fare: json['fare'].toDouble(),
    );
  }
}
