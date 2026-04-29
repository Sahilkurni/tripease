import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bus_model.dart';
import '../services/bus_service.dart';

final busServiceProvider = Provider<BusService>((ref) {
  return BusService();
});

class BusSearchNotifier extends Notifier<AsyncValue<List<BusModel>>> {
  @override
  AsyncValue<List<BusModel>> build() => const AsyncValue.data([]);

  Future<void> searchBuses(String source, String destination, String date) async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(busServiceProvider);
      final results = await service.searchBuses(source, destination, date);
      state = AsyncValue.data(results);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final busSearchProvider = NotifierProvider<BusSearchNotifier, AsyncValue<List<BusModel>>>(() {
  return BusSearchNotifier();
});
