class UserModel {
  final String userid;
  final String name;
  final String email;
  final String? roleid;
  final String? rolename;
  final String? photo;
  final String? token; // Can be a JWT or session identifier
  final int? partnerid;

  UserModel({
    required this.userid,
    required this.name,
    required this.email,
    this.roleid,
    this.rolename,
    this.photo,
    this.token,
    this.partnerid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userid: json['userid']?.toString() ?? '',
      name: json['name'] ?? json['fullname'] ?? '',
      email: json['email'] ?? '',
      roleid: json['roleid']?.toString(),
      rolename: json['rolename'],
      photo: json['photo'],
      token: json['token'],
      partnerid:
          json['partnerid'] == null
              ? null
              : int.tryParse(json['partnerid'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userid,
      'name': name,
      'email': email,
      'roleid': roleid,
      'rolename': rolename,
      'photo': photo,
      'token': token,
      'partnerid': partnerid,
    };
  }
}
