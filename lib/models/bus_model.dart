class BusModel {
  final int busid;
  final int partnerid;
  final String busname;
  final String bustype;
  final String busnumber;
  final int totalseats;
  final String amenities;
  final int? uid;
  final String? edatetime;
  final int isactive;

  // UI convenience fields
  final String? imageUrl;
  final List<String> images; // all images (primary first)
  final List<BusSeatModel> seats;
  final double baseFare;
  final String departureTime;
  final String arrivalTime;
  final String sourceCityName;
  final String destinationCityName;
  final String layoutType;
  final int sourceCityId;
  final int destinationCityId;
  final double? latitude;
  final double? longitude;

  // Aliases for compatibility
  String get busName => busname;
  String get busType => bustype;
  int get totalSeats => totalseats;

  BusModel({
    required this.busid,
    required this.partnerid,
    required this.busname,
    required this.bustype,
    required this.busnumber,
    required this.totalseats,
    required this.amenities,
    this.uid,
    this.edatetime,
    this.isactive = 1,
    this.imageUrl,
    this.images = const [],
    this.seats = const [],
    this.baseFare = 0.0,
    this.departureTime = '',
    this.arrivalTime = '',
    this.sourceCityName = '',
    this.destinationCityName = '',
    this.layoutType = '2x2',
    this.sourceCityId = 0,
    this.destinationCityId = 0,
    this.latitude,
    this.longitude,
  });

  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel(
      busid: int.parse((json['busid'] ?? json['tripid'] ?? '0').toString()),
      partnerid: int.parse((json['partnerid'] ?? '0').toString()),
      busname: json['busname'] ?? json['bus_name'] ?? '',
      bustype: json['bustype'] ?? json['bus_type'] ?? '',
      busnumber: json['busnumber'] ?? json['bus_number'] ?? '',
      totalseats: int.parse(
        (json['totalseats'] ?? json['total_seats'] ?? json['seats'] ?? '0')
            .toString(),
      ),
      amenities: json['amenities'] ?? '',
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse((json['isactive'] ?? '1').toString()),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      seats:
          (json['seats'] as List<dynamic>?)
              ?.map((e) => BusSeatModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      baseFare:
          double.tryParse(
            (json['base_fare'] ??
                    json['basefare'] ??
                    json['price'] ??
                    json['fare'] ??
                    '0.0')
                .toString(),
          ) ??
          0.0,
      departureTime: json['departure_time'] ?? json['departure'] ?? '',
      arrivalTime: json['arrival_time'] ?? json['arrival'] ?? '',
      sourceCityName: json['source_city_name'] ?? json['source'] ?? '',
      destinationCityName:
          json['destination_city_name'] ?? json['destination'] ?? '',
      layoutType: json['layout_type'] ?? '2x2',
      sourceCityId:
          int.tryParse((json['source_city_id'] ?? '0').toString()) ?? 0,
      destinationCityId:
          int.tryParse((json['destination_city_id'] ?? '0').toString()) ?? 0,
      latitude:
          json['latitude'] != null
              ? double.tryParse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.tryParse(json['longitude'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'busid': busid,
      'partnerid': partnerid,
      'busname': busname,
      'bustype': bustype,
      'busnumber': busnumber,
      'totalseats': totalseats,
      'amenities': amenities,
      'uid': uid,
      'edatetime': edatetime,
      'isactive': isactive,
      'base_fare': baseFare,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'source_city_name': sourceCityName,
      'destination_city_name': destinationCityName,
      'layout_type': layoutType,
      'source_city_id': sourceCityId,
      'destination_city_id': destinationCityId,
      'latitude': latitude,
      'longitude': longitude,
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
      rowNo:
          int.parse(json['row_no']?.toString() ?? '0') != 0
              ? int.parse(json['row_no'].toString())
              : (int.parse(json['seatid']?.toString() ?? '1') - 1) ~/ 4 + 1,
      colNo:
          int.parse(json['col_no']?.toString() ?? '0') != 0
              ? int.parse(json['col_no'].toString())
              : (int.parse(json['seatid']?.toString() ?? '1') - 1) % 4 + 1,
      isSleeper:
          (json['is_sleeper']?.toString() == '1' || json['is_sleeper'] == true),
      isBooked:
          (json['is_booked']?.toString() == '1' || json['is_booked'] == true),
      extraFare: double.parse(json['extra_fare']?.toString() ?? '0.0'),
    );
  }
}
