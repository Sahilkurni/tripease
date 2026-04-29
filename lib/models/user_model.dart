class UserModel {
  final String userid;
  final String name;
  final String email;
  final String? roleid;
  final String? rolename;
  final String? photo;
  final String? token; // Can be a JWT or session identifier

  UserModel({
    required this.userid,
    required this.name,
    required this.email,
    this.roleid,
    this.rolename,
    this.photo,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userid: json['userid']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      roleid: json['roleid']?.toString(),
      rolename: json['rolename'],
      photo: json['photo'],
      token: json['token'],
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
    };
  }
}
