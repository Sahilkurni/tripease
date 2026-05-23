import 'dart:convert';
import 'package:flutter/foundation.dart';
// Dummy test to simulate the issue
void main() {
  String? roleId = '2';
  String? roleName = 'CUSTOMER';
  
  final parsedRoleId = int.tryParse((roleId ?? '').trim());
  print("parsedRoleId: $parsedRoleId");
  
  String route = '/home';
  if (parsedRoleId == 3) {
     route = '/hotel_dashboard';
  }
  print("route: $route");
}
