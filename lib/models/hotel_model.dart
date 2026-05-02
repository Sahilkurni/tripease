class HotelModel {
  final int hotelid;
  final int partnerid;
  final String hotelname;
  final String? description;
  final String? address;
  final int cityid;
  final double starRating;
  final double? latitude;
  final double? longitude;
  final String? checkintime;
  final String? checkouttime;
  final int? uid;
  final String? edatetime;
  final int isactive;

  // Additional fields for UI convenience
  final String? imageUrl;
  final double? startingPrice;

  HotelModel({
    required this.hotelid,
    required this.partnerid,
    required this.hotelname,
    this.description,
    this.address,
    required this.cityid,
    required this.starRating,
    this.latitude,
    this.longitude,
    this.checkintime,
    this.checkouttime,
    this.uid,
    this.edatetime,
    this.isactive = 1,
    this.imageUrl,
    this.startingPrice,
  });

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      hotelid: int.parse(json['hotelid']?.toString() ?? '0'),
      partnerid: int.parse(json['partnerid']?.toString() ?? '0'),
      hotelname: json['hotelname'] ?? '',
      description: json['description'],
      address: json['address'],
      cityid: int.parse(json['cityid']?.toString() ?? '0'),
      starRating: double.parse(json['star_rating']?.toString() ?? '0.0'),
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      checkintime: json['checkintime'],
      checkouttime: json['checkouttime'],
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      startingPrice: json['starting_price'] != null ? double.parse(json['starting_price'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotelid': hotelid,
      'partnerid': partnerid,
      'hotelname': hotelname,
      'description': description,
      'address': address,
      'cityid': cityid,
      'star_rating': starRating,
      'latitude': latitude,
      'longitude': longitude,
      'checkintime': checkintime,
      'checkouttime': checkouttime,
      'uid': uid,
      'edatetime': edatetime,
      'isactive': isactive,
    };
  }
}
