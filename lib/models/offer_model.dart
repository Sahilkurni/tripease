class OfferModel {
  final int offerid;
  final String title;
  final String? description;
  final String serviceType;
  final int? serviceId;
  final int createdBy;
  final String creatorRole;
  final String? validFrom;
  final String? validTo;
  final String status;
  final int isactive;
  final String? edatetime;
  final String? primaryImage;
  final List<String>? allImages;
  final String? badgeText;

  OfferModel({
    required this.offerid,
    required this.title,
    this.description,
    required this.serviceType,
    this.serviceId,
    required this.createdBy,
    required this.creatorRole,
    this.validFrom,
    this.validTo,
    required this.status,
    required this.isactive,
    this.edatetime,
    this.primaryImage,
    this.allImages,
    this.badgeText,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    List<String> images = [];
    if (json['images'] != null) {
      images = (json['images'] as List).map((i) => i['image'].toString()).toList();
    }

    return OfferModel(
      offerid: int.parse(json['offerid']?.toString() ?? '0'),
      title: json['title'] ?? '',
      description: json['description'],
      serviceType: json['service_type'] ?? 'global',
      serviceId: json['service_id'] != null ? int.parse(json['service_id'].toString()) : null,
      createdBy: int.parse(json['created_by']?.toString() ?? '0'),
      creatorRole: json['creator_role'] ?? 'admin',
      validFrom: json['valid_from'],
      validTo: json['valid_to'],
      status: json['status'] ?? 'pending',
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
      edatetime: json['edatetime'],
      primaryImage: json['primary_image'],
      allImages: images.isNotEmpty ? images : null,
      badgeText: json['badge_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerid': offerid,
      'title': title,
      'description': description,
      'service_type': serviceType,
      'service_id': serviceId,
      'created_by': createdBy,
      'creator_role': creatorRole,
      'valid_from': validFrom,
      'valid_to': validTo,
      'status': status,
      'isactive': isactive,
      'edatetime': edatetime,
      'primary_image': primaryImage,
      'badge_text': badgeText,
    };
  }
}
