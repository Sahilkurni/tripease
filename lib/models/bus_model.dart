class BusModel {
  final int busid;
  final int partnerid;
  final String busName;
  final String busType; // e.g., A/C Sleeper, Non-A/C Seater
  final String layoutType; // e.g., 2x2, 2x1, 1x1
  final int totalSeats;
  final int sourceCityId;
  final int destinationCityId;
  final String departureTime;
  final String arrivalTime;
  final double baseFare;
  final int? uid;
  final String? edatetime;
  final int isactive;

  // UI convenience fields
  final String? sourceCityName;
  final String? destinationCityName;
  final List<BusSeatModel> seats;

  BusModel({
    required this.busid,
    required this.partnerid,
    required this.busName,
    required this.busType,
    required this.layoutType,
    required this.totalSeats,
    required this.sourceCityId,
    required this.destinationCityId,
    required this.departureTime,
    required this.arrivalTime,
    required this.baseFare,
    this.uid,
    this.edatetime,
    this.isactive = 1,
    this.sourceCityName,
    this.destinationCityName,
    this.seats = const [],
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busid: int.parse((json['busid'] ?? json['tripid'] ?? '0').toString()),
      partnerid: int.parse((json['partnerid'] ?? '0').toString()),
      busName: json['bus_name'] ?? json['busname'] ?? '',
      busType: json['bus_type'] ?? json['bustype'] ?? '',
      layoutType: json['layout_type'] ?? '2x2',
      totalSeats: int.parse((json['total_seats'] ?? '0').toString()),
      sourceCityId: int.parse((json['source_city_id'] ?? '0').toString()),
      destinationCityId: int.parse((json['destination_city_id'] ?? '0').toString()),
      departureTime: json['departure_time'] ?? json['departure'] ?? '',
      arrivalTime: json['arrival_time'] ?? json['arrival'] ?? '',
      baseFare: double.parse((json['base_fare'] ?? json['price'] ?? '0.0').toString()),
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse((json['isactive'] ?? '1').toString()),
      sourceCityName: json['source_city_name'] ?? json['source'],
      destinationCityName: json['destination_city_name'] ?? json['destination'],
      seats: (json['seats'] as List<dynamic>?)
              ?.map((e) => BusSeatModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busid': busid,
      'partnerid': partnerid,
      'bus_name': busName,
      'bus_type': busType,
      'layout_type': layoutType,
      'total_seats': totalSeats,
      'source_city_id': sourceCityId,
      'destination_city_id': destinationCityId,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'base_fare': baseFare,
      'uid': uid,
      'edatetime': edatetime,
      'isactive': isactive,
    };
  }
}

class BusSeatModel {
  final int seatid;
  final int busid;
  final String seatNo; // e.g., A1, A2
  final int rowNo;
  final int colNo;
  final bool isSleeper;
  final bool isBooked; // Dynamic status based on date
  final double extraFare; // Additional fare for premium seats

  BusSeatModel({
    required this.seatid,
    required this.busid,
    required this.seatNo,
    required this.rowNo,
    required this.colNo,
    this.isSleeper = false,
    this.isBooked = false,
    this.extraFare = 0.0,
  });

  factory BusSeatModel.fromJson(Map<String, dynamic> json) {
    return BusSeatModel(
      seatid: int.parse(json['seatid']?.toString() ?? '0'),
      busid: int.parse(json['busid']?.toString() ?? '0'),
      seatNo: json['seat_no'] ?? '',
      rowNo: int.parse(json['row_no']?.toString() ?? '0') != 0 
             ? int.parse(json['row_no'].toString()) 
             : (int.parse(json['seatid']?.toString() ?? '1') - 1) ~/ 4 + 1,
      colNo: int.parse(json['col_no']?.toString() ?? '0') != 0 
             ? int.parse(json['col_no'].toString()) 
             : (int.parse(json['seatid']?.toString() ?? '1') - 1) % 4 + 1,
      isSleeper: (json['is_sleeper']?.toString() == '1' || json['is_sleeper'] == true),
      isBooked: (json['is_booked']?.toString() == '1' || json['is_booked'] == true),
      extraFare: double.parse(json['extra_fare']?.toString() ?? '0.0'),
    );
  }
}
