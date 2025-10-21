import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/license_data.dart';

class Vehicle {
  final LicenseType vehicleType;
  final String description;
  final int minutes;
  final int minPoint;
  final int totalQuestionsPerQuiz;

  Vehicle({
    required this.vehicleType,
    required this.description,
    required this.minutes,
    required this.minPoint,
    required this.totalQuestionsPerQuiz,
  });
}

Vehicle a1 = Vehicle(
  vehicleType: LicenseType.A1,
  description:
      'Hạng A1 lái xe mô tô hai bánh có dung tích xi-lanh đến 125cm3 hoặc có công suất động cơ điện đến 11kW',
  minutes: 19,
  minPoint: 21,
  totalQuestionsPerQuiz: 25,
);

Vehicle a = Vehicle(
  vehicleType: LicenseType.A,
  description: 'Xe máy dung tích xi-lanh từ 175cm³ trở lên',
  minutes: 19,
  minPoint: 23,
  totalQuestionsPerQuiz: 25,
);

Vehicle b1 = Vehicle(
  vehicleType: LicenseType.B1,
  description:
      'Hạng B1 lái xe ô tô dưới 4 chỗ ngồi, xe ô tô tải có trọng tải dưới 3.500kg',
  minutes: 22,
  minPoint: 23,
  totalQuestionsPerQuiz: 30,
);

Vehicle b = Vehicle(
  vehicleType: LicenseType.B,
  description:
      'Hạng B lái xe ô tô từ 4 đến 9 chỗ ngồi, xe ô tô tải có trọng tải dưới 3.500kg',
  minutes: 22,
  minPoint: 26,
  totalQuestionsPerQuiz: 30,
);

Vehicle c1 = Vehicle(
  vehicleType: LicenseType.C1,
  description:
      'Hạng C1 lái xe ô tô từ 10 đến 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg đến dưới 7.500kg',
  minutes: 25,
  minPoint: 26,
  totalQuestionsPerQuiz: 35,
);

Vehicle c = Vehicle(
  vehicleType: LicenseType.C,
  description:
      'Hạng C lái xe ô tô trên 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên',
  minutes: 25,
  minPoint: 28,
  totalQuestionsPerQuiz: 35,
);

Vehicle d1 = Vehicle(
  vehicleType: LicenseType.D1,
  description:
      'Hạng D1 lái xe ô tô từ 10 đến 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên',
  minutes: 27,
  minPoint: 26,
  totalQuestionsPerQuiz: 40,
);

Vehicle d2 = Vehicle(
  vehicleType: LicenseType.D2,
  description:
      'Hạng D2 lái xe ô tô trên 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên',
  minutes: 27,
  minPoint: 28,
  totalQuestionsPerQuiz: 40,
);

Vehicle d = Vehicle(
  vehicleType: LicenseType.D,
  description:
      'Hạng D lái xe ô tô trên 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên',
  minutes: 27,
  minPoint: 30,
  totalQuestionsPerQuiz: 40,
);

Vehicle be = Vehicle(
  vehicleType: LicenseType.BE,
  description:
      'Hạng BE lái xe ô tô dưới 4 chỗ ngồi, xe ô tô tải có trọng tải dưới 3.500kg, rơ moóc có trọng tải từ 750kg trở lên',
  minutes: 22,
  minPoint: 26,
  totalQuestionsPerQuiz: 30,
);

Vehicle c1e = Vehicle(
  vehicleType: LicenseType.C1E,
  description:
      'Hạng C1E lái xe ô tô từ 10 đến 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg đến dưới 7.500kg, rơ moóc có trọng tải từ 750kg trở lên',
  minutes: 25,
  minPoint: 28,
  totalQuestionsPerQuiz: 35,
);

Vehicle ce = Vehicle(
  vehicleType: LicenseType.CE,
  description:
      'Hạng CE lái xe ô tô trên 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên, rơ moóc có trọng tải từ 750kg trở lên',
  minutes: 25,
  minPoint: 30,
  totalQuestionsPerQuiz: 35,
);

Vehicle d1e = Vehicle(
  vehicleType: LicenseType.D1E,
  description:
      'Hạng D1E lái xe ô tô từ 10 đến 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên, rơ moóc có trọng tải từ 750kg trở lên',
  minutes: 27,
  minPoint: 28,
  totalQuestionsPerQuiz: 40,
);

Vehicle d2e = Vehicle(
  vehicleType: LicenseType.D2E,
  description:
      'Hạng D2E lái xe ô tô trên 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên, rơ moóc có trọng tải từ 750kg trở lên',
  minutes: 27,
  minPoint: 30,
  totalQuestionsPerQuiz: 40,
);

Vehicle de = Vehicle(
  vehicleType: LicenseType.DE,
  description:
      'Hạng DE lái xe ô tô trên 30 chỗ ngồi, xe ô tô tải có trọng tải từ 3.500kg trở lên, rơ moóc có trọng tải từ 750kg trở lên',
  minutes: 27,
  minPoint: 32,
  totalQuestionsPerQuiz: 40,
);

List<Vehicle> allVehicles = [
  a1,
  a,
  b1,
  b,
  c1,
  c,
  d1,
  d2,
  d,
  be,
  c1e,
  ce,
  d1e,
  d2e,
  de,
];

final selectedVehicleTypeProvider = StateProvider<Vehicle>((ref) => a1);
