class RoomModel {
  final int roomid;
  final int? hotelid;
  final int? roomtypeid;
  final String roomtype;
  final int? capacity;
  final int? totalrooms;
  final double price;
  final double? extraBedPrice;
  final int? uid;
  final String? edatetime;
  final int isactive;
  final int availableRooms;
  
  // Joined fields for UI convenience
  final String? roomTypeName;

  RoomModel({
    required this.roomid,
    this.hotelid,
    this.roomtypeid,
    required this.roomtype,
    this.capacity,
    this.totalrooms,
    required this.price,
    this.extraBedPrice,
    this.uid,
    this.edatetime,
    this.isactive = 1,
    this.availableRooms = 0,
    this.roomTypeName,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomid: int.parse(json['roomid']?.toString() ?? '0'),
      hotelid: int.tryParse(json['hotelid']?.toString() ?? ''),
      roomtypeid: int.tryParse(json['roomtypeid']?.toString() ?? ''),
      roomtype: json['roomtype']?.toString() ?? json['roomname']?.toString() ?? '',
      capacity: int.tryParse(json['capacity']?.toString() ?? ''),
      totalrooms: int.tryParse(json['totalrooms']?.toString() ?? ''),
      price: double.parse(json['price']?.toString() ?? '0.0'),
      extraBedPrice: json['extra_bed_price'] != null ? double.parse(json['extra_bed_price'].toString()) : null,
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
      availableRooms: int.parse(json['available_rooms']?.toString() ?? '0'),
      roomTypeName: json['room_type_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomid': roomid,
      'hotelid': hotelid,
      'roomtypeid': roomtypeid,
      'roomtype': roomtype,
      'capacity': capacity,
      'totalrooms': totalrooms,
      'price': price,
      'extra_bed_price': extraBedPrice,
      'uid': uid,
      'edatetime': edatetime,
      'isactive': isactive,
      'available_rooms': availableRooms,
    };
  }
}

class RoomTypeModel {
  final int roomtypeid;
  final String typename;
  final int? uid;
  final String? edatetime;
  final int isactive;

  RoomTypeModel({
    required this.roomtypeid,
    required this.typename,
    this.uid,
    this.edatetime,
    this.isactive = 1,
  });

  factory RoomTypeModel.fromJson(Map<String, dynamic> json) {
    return RoomTypeModel(
      roomtypeid: int.parse(json['roomtypeid']?.toString() ?? '0'),
      typename: json['typename'] ?? '',
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
    );
  }
}
