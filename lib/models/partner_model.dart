class PartnerModel {
  final int partnerid;
  final int userid;
  final String companyname;
  final String ownername;
  final String? gstno;
  final String? address;
  final int cityid;
  final String approvalstatus;
  final double commissionpercent;
  final int? uid;
  final String? edatetime;
  final int isactive;

  PartnerModel({
    required this.partnerid,
    required this.userid,
    required this.companyname,
    required this.ownername,
    this.gstno,
    this.address,
    required this.cityid,
    required this.approvalstatus,
    required this.commissionpercent,
    this.uid,
    this.edatetime,
    this.isactive = 1,
  });

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      partnerid: int.parse(json['partnerid']?.toString() ?? '0'),
      userid: int.parse(json['userid']?.toString() ?? '0'),
      companyname: json['companyname'] ?? '',
      ownername: json['ownername'] ?? '',
      gstno: json['gstno'],
      address: json['address'],
      cityid: int.parse(json['cityid']?.toString() ?? '0'),
      approvalstatus: json['approvalstatus'] ?? 'PENDING',
      commissionpercent: double.parse(json['commissionpercent']?.toString() ?? '0.0'),
      uid: json['uid'] != null ? int.parse(json['uid'].toString()) : null,
      edatetime: json['edatetime'],
      isactive: int.parse(json['isactive']?.toString() ?? '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partnerid': partnerid,
      'userid': userid,
      'companyname': companyname,
      'ownername': ownername,
      'gstno': gstno,
      'address': address,
      'cityid': cityid,
      'approvalstatus': approvalstatus,
      'commissionpercent': commissionpercent,
      'uid': uid,
      'edatetime': edatetime,
      'isactive': isactive,
    };
  }
}
