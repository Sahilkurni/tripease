import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/models/package_model.dart';
import 'lib/models/bus_model.dart';
import 'lib/models/flight_model.dart';

void main() async {
  final email = 'btest@gmail.com';
  final password = 'btest123';
  
  print('1. Attempting login for \$email...');
  
  final loginUrl = Uri.parse('http://localhost/tripease_api/login.php');
  final loginResponse = await http.post(
    loginUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
    }),
  );

  if (loginResponse.statusCode != 200) {
    print('Login failed with status: \${loginResponse.statusCode}');
    print(loginResponse.body);
    return;
  }

  final loginData = jsonDecode(loginResponse.body);
  if (loginData['status'] != 'success') {
    print('Login error: \${loginData["message"]}');
    return;
  }

  final user = loginData['data'];
  print('Login success! User: \${user["fullname"]}');
  
  // Replicate fallback logic from agent_dashboard.dart
  int userid = int.tryParse(user['userid']?.toString() ?? '') ?? 0;
  int partnerid = int.tryParse(user['partnerid']?.toString() ?? '') ?? userid;
  if (partnerid == 0) {
    partnerid = userid;
  }

  print('Resolved IDs => UserID: \$userid, PartnerID: \$partnerid');

  print('\\n2. Fetching Packages...');
  try {
    final pkgUrl = Uri.parse('http://localhost/tripease_api/agent/packages.php?partnerid=\$partnerid');
    final pkgResponse = await http.get(pkgUrl);
    final pkgDecoded = jsonDecode(utf8.decode(pkgResponse.bodyBytes));
    if (pkgDecoded['data'] is List) {
      final packages = (pkgDecoded['data'] as List).map((e) => PackageModel.fromJson(e)).toList();
      print('SUCCESS: Parsed \${packages.length} packages.');
      for (var p in packages) {
        print('  - Package: \${p.packagename} (ID: \${p.packageid})');
      }
    } else {
      print('Packages data is not a list.');
    }
  } catch (e, st) {
    print('Error fetching/parsing packages: \$e');
    print(st);
  }

  print('\\n3. Fetching Buses...');
  try {
    final busUrl = Uri.parse('http://localhost/tripease_api/agent/buses.php?partnerid=\$partnerid');
    final busResponse = await http.get(busUrl);
    final busDecoded = jsonDecode(utf8.decode(busResponse.bodyBytes));
    if (busDecoded['data'] is List) {
      final buses = (busDecoded['data'] as List).map((e) => BusModel.fromJson(e)).toList();
      print('SUCCESS: Parsed \${buses.length} buses.');
      for (var b in buses) {
        print('  - Bus: \${b.busname} (ID: \${b.busid})');
      }
    } else {
      print('Buses data is not a list.');
    }
  } catch (e, st) {
    print('Error fetching/parsing buses: \$e');
    print(st);
  }

  print('\\n4. Fetching Flights...');
  try {
    final flightUrl = Uri.parse('http://localhost/tripease_api/admin/get_all_flights.php');
    // NOTE: getAgentFlights actually calls admin/get_all_flights.php and filters them later... wait! Let me check flightUrl.
  } catch(e){}
}
