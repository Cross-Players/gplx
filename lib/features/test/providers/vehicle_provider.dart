import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/data/local_storage.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/data/vehicle_data.dart';
import 'package:gplx/features/test/models/vehicle.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(),
);

// Provider that initializes with the stored vehicle type or defaults to A1
final selectedVehicleTypeProvider = StateProvider<Vehicle>((ref) {
  // Default to A1
  return a1;
});

// Provider to load the saved vehicle type from SharedPreferences
final loadSavedVehicleTypeProvider = FutureProvider<Vehicle>((ref) async {
  final localStorage = ref.read(localStorageProvider);
  final repository = ref.read(vehicleRepositoryProvider);
  final savedType = await localStorage.getSelectedVehicleType();

  if (savedType != null) {
    final vehicle = repository.getVehicleByType(savedType);
    if (vehicle != null) {
      // Update the selectedVehicleTypeProvider with the saved value
      ref.read(selectedVehicleTypeProvider.notifier).state = vehicle;
      return vehicle;
    }
  }

  // Default to A1
  return a1;
});
