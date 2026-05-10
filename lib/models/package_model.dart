class PackageModel {
  final int packageid;
  final int partnerid;
  final int categoryid;
  final String packagename;
  final String? description;
  final int cityid;
  final int days;
  final int nights;
  final double price;
  final int maxpersons;
  final String? thumbnail;
  final int? uid;
  final String? edatetime;
  final int isactive;
  final double? latitude;
  final double? longitude;

  // Joined fields for UI convenience
  final String? categoryName;
  final String? cityName;
  final List<PackageItineraryModel> itineraries;
  final List<String> images;

  PackageModel({
    required this.packageid,
    required this.partnerid,
    required this.categoryid,
    required this.packagename,
    this.description,
    required this.cityid,
    required this.days,
    required this.nights,
    required this.price,
    required this.maxpersons,
    this.thumbnail,
    this.uid,
    this.edatetime,
    this.isactive = 1,
    this.categoryName,
    this.cityName,
    this.itineraries = const [],
    this.images = const [],
    this.latitude,
    this.longitude,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      packageid: int.parse(json['packageid']?.toString() ?? '0'),
      partnerid: int.parse(json['partnerid']?.toString() ?? '0'),
      categoryid: int.parse(json['categoryid']?.toString() ?? '0'),
      packagename: json['packagename'] ?? '',
      description: json['description'],
      cityid: int.parse(json['cityid']?.toString() ?? '0'),
      days: int.parse(json['days']?.toString() ?? '0'),
      nights: int.parse(json['nights']?.toString() ?? '0'),
      price: double.parse(json['price']?.toString() ?? '0.0'),
      maxpersons: int.parse(json['maxpersons']?.toString() ?? '0'),
      thumbnail: json['thumbnail'],
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      categoryName: json['categoryName'],
      cityName: json['cityName'],
      itineraries: (json['itineraries'] as List<dynamic>?)
              ?.map((e) => PackageItineraryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageid': packageid,
      'partnerid': partnerid,
      'categoryid': categoryid,
      'packagename': packagename,
      'description': description,
      'cityid': cityid,
      'days': days,
      'nights': nights,
      'price': price,
      'maxpersons': maxpersons,
      'thumbnail': thumbnail,
      'uid': uid,
      'edatetime': edatetime,
      'isactive': isactive,
    };
  }
}

class PackageItineraryModel {
  final int itineraryid;
  final int packageid;
  final int dayno;
  final String title;
  final String? description;
  final int? uid;
  final String? edatetime;
  final int isactive;

  PackageItineraryModel({
    required this.itineraryid,
    required this.packageid,
    required this.dayno,
    required this.title,
    this.description,
    this.uid,
    this.edatetime,
    this.isactive = 1,
  });

  factory PackageItineraryModel.fromJson(Map<String, dynamic> json) {
    return PackageItineraryModel(
      itineraryid: int.parse(json['itineraryid']?.toString() ?? '0'),
      packageid: int.parse(json['packageid']?.toString() ?? '0'),
      dayno: int.parse(json['dayno']?.toString() ?? '0'),
      title: json['title'] ?? '',
      description: json['description'],
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
    );
  }
}

class PackageCategoryModel {
  final int categoryid;
  final String categoryname;
  final int? uid;
  final String? edatetime;
  final int isactive;

  PackageCategoryModel({
    required this.categoryid,
    required this.categoryname,
    this.uid,
    this.edatetime,
    this.isactive = 1,
  });

  factory PackageCategoryModel.fromJson(Map<String, dynamic> json) {
    return PackageCategoryModel(
      categoryid: int.parse(json['categoryid']?.toString() ?? '0'),
      categoryname: json['categoryname'] ?? '',
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
    );
  }
}
