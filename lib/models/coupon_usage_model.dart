class CouponUsageModel {
  final int usageid;
  final int couponid;
  final int userid;
  final int bookingid;
  final String? serviceType;
  final int? serviceId;
  final double discountAmount;
  final int? uid;
  final String? edatetime;
  final String? couponcode;
  final String? couponTitle;
  final String? customerName;

  CouponUsageModel({
    required this.usageid,
    required this.couponid,
    required this.userid,
    required this.bookingid,
    this.serviceType,
    this.serviceId,
    required this.discountAmount,
    this.uid,
    this.edatetime,
    this.couponcode,
    this.couponTitle,
    this.customerName,
  });

  factory CouponUsageModel.fromJson(Map<String, dynamic> json) {
    return CouponUsageModel(
      usageid: int.parse(json['usageid']?.toString() ?? '0'),
      couponid: int.parse(json['couponid']?.toString() ?? '0'),
      userid: int.parse(json['userid']?.toString() ?? '0'),
      bookingid: int.parse(json['bookingid']?.toString() ?? '0'),
      serviceType: json['service_type'],
      serviceId: json['service_id'] != null ? int.parse(json['service_id'].toString()) : null,
      discountAmount: double.parse(json['discount_amount']?.toString() ?? '0.0'),
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      couponcode: json['couponcode'],
      couponTitle: json['coupon_title'],
      customerName: json['customer_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'usageid': usageid,
      'couponid': couponid,
      'userid': userid,
      'bookingid': bookingid,
      'service_type': serviceType,
      'service_id': serviceId,
      'discount_amount': discountAmount,
      'uid': uid,
      'edatetime': edatetime,
    };
  }
}
