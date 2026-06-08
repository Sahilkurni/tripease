import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/services/package_service.dart';
import 'lib/services/bus_service.dart';
import 'lib/services/flight_service.dart';
import 'lib/services/agent_service.dart';

void main() async {
  final partnerid = 22;
  final userid = 22;

  print('--- Testing packageService.getAgentPackages ---');
  try {
    final list = await packageService.getAgentPackages(partnerid);
    print('SUCCESS: fetched ${list.length} packages.');
    for (var p in list) {
      print('  Package ID: ${p.packageid}, Name: ${p.packagename}');
    }
  } catch (e, st) {
    print('FAILED packageService.getAgentPackages: $e');
    print(st);
  }

  print('\n--- Testing busService.getAgentBuses ---');
  try {
    final list = await busService.getAgentBuses(partnerid);
    print('SUCCESS: fetched ${list.length} buses.');
    for (var b in list) {
      print('  Bus ID: ${b.busid}, Name: ${b.busname}');
    }
  } catch (e, st) {
    print('FAILED busService.getAgentBuses: $e');
    print(st);
  }

  print('\n--- Testing flightService.getAgentFlights ---');
  try {
    final list = await flightService.getAgentFlights(userid);
    print('SUCCESS: fetched ${list.length} flights.');
    for (var f in list) {
      print('  Flight ID: ${f.flightId}, Airline: ${f.airline}, Number: ${f.flightNumber}');
    }
  } catch (e, st) {
    print('FAILED flightService.getAgentFlights: $e');
    print(st);
  }

  print('\n--- Testing AgentService.getEarnings ---');
  try {
    final earnings = await AgentService.getEarnings(partnerid, 'month');
    print('SUCCESS: fetched earnings: $earnings');
  } catch (e, st) {
    print('FAILED AgentService.getEarnings: $e');
    print(st);
  }
}

