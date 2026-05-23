class CouponModel {
  final int couponid;
  final String couponcode;
  final String? title;
  final String? description;
  final String discounttype;
  final double discountvalue;
  final double minamount;
  final double maximumDiscount;
  final String? expirydate;
  final String serviceType;
  final int? serviceId;
  final String creatorRole;
  final int? uid;
  final String status;
  final int usageLimit;
  final int usedCount;
  final String? edatetime;
  final int isactive;

  CouponModel({
    required this.couponid,
    required this.couponcode,
    this.title,
    this.description,
    required this.discounttype,
    required this.discountvalue,
    required this.minamount,
    required this.maximumDiscount,
    this.expirydate,
    required this.serviceType,
    this.serviceId,
    required this.creatorRole,
    this.uid,
    required this.status,
    required this.usageLimit,
    required this.usedCount,
    this.edatetime,
    this.isactive = 1,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponid: int.parse(json['couponid']?.toString() ?? '0'),
      couponcode: json['couponcode'] ?? '',
      title: json['title'],
      description: json['description'],
      discounttype: json['discounttype'] ?? 'FLAT',
      discountvalue: double.parse(json['discountvalue']?.toString() ?? '0.0'),
      minamount: double.parse(json['minamount']?.toString() ?? '0.0'),
      maximumDiscount: double.parse(json['maximum_discount']?.toString() ?? '0.0'),
      expirydate: json['expirydate'],
      serviceType: json['service_type'] ?? 'global',
      serviceId: json['service_id'] != null ? int.parse(json['service_id'].toString()) : null,
      creatorRole: json['creator_role'] ?? 'admin',
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      status: json['status'] ?? 'pending',
      usageLimit: int.parse(json['usage_limit']?.toString() ?? '0'),
      usedCount: int.parse(json['used_count']?.toString() ?? '0'),
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'couponid': couponid,
      'couponcode': couponcode,
      'title': title,
      'description': description,
      'discounttype': discounttype,
      'discountvalue': discountvalue,
      'minamount': minamount,
      'maximum_discount': maximumDiscount,
      'expirydate': expirydate,
      'service_type': serviceType,
      'service_id': serviceId,
      'creator_role': creatorRole,
      'uid': uid,
      'status': status,
      'usage_limit': usageLimit,
      'used_count': usedCount,
      'edatetime': edatetime,
      'isactive': isactive,
    };
  }
  bool isValidFor(double amount, String sType, int? sId) {
    if (isactive != 1) return false;
    if (status.toLowerCase() != 'approved') return false;
    if (amount < minamount) return false;
    
    // Check service scope
    if (serviceType != 'global') {
      if (serviceType != sType) return false;
      if (serviceId != null && serviceId != 0 && serviceId != sId) return false;
    }

    // Check expiry
    if (expirydate != null && expirydate!.isNotEmpty) {
      final expiry = DateTime.tryParse(expirydate!);
      if (expiry != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        if (expiry.isBefore(today)) return false;
      }
    }

    // Usage limit is now per-user and enforced by the backend API

    return true;
  }

  double calculateSavings(double amount) {
    double savings = 0;
    if (discounttype == 'PERCENT') {
      savings = (amount * discountvalue) / 100;
      if (maximumDiscount > 0 && savings > maximumDiscount) {
        savings = maximumDiscount;
      }
    } else {
      savings = discountvalue;
    }
    return savings > amount ? amount : savings;
  }
}
