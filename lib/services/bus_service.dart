import '../models/bus_model.dart';

class BusService {
  Future<List<BusModel>> searchBuses(String source, String destination, String date) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      BusModel(
        id: 'b1',
        operatorName: 'VRL Travels',
        source: source,
        destination: destination,
        departureTime: '21:00',
        arrivalTime: '06:00',
        duration: '9h 00m',
        fare: 25.0,
      ),
      BusModel(
        id: 'b2',
        operatorName: 'Zingbus AC Volvo',
        source: source,
        destination: destination,
        departureTime: '22:30',
        arrivalTime: '07:15',
        duration: '8h 45m',
        fare: 30.0,
      ),
      BusModel(
        id: 'b3',
        operatorName: 'Orange Tours',
        source: source,
        destination: destination,
        departureTime: '23:15',
        arrivalTime: '08:30',
        duration: '9h 15m',
        fare: 22.5,
      ),
    ];
  }
}
