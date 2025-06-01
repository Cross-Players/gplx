import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/data/vehicle_data.dart';
import 'package:gplx/features/test/models/vehicle.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (ref) => VehicleRepository(),
);

final selectedVehicleTypeProvider = StateProvider<Vehicle>((ref) => a1);