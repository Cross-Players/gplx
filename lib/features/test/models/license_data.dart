import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore_for_file: constant_identifier_names

enum LicenseType {
  A,
  A1,
  B,
  B1,
  C,
  C1,
  D,
  D1,
  D2,
  BE,
  C1E,
  CE,
  D1E,
  D2E,
  DE,
  all_questions,
}

int numberOfTestSetsBasedOnLicense(LicenseType licenseType) {
  switch (licenseType) {
    case LicenseType.A:
      return 18;
    case LicenseType.A1:
      return 8; // Số lượng bộ đề cho hạng A và A1
    case LicenseType.B:
      return 20;
    case LicenseType.B1:
      return 20; // Số lượng bộ đề cho hạng B và B1
    case LicenseType.C:
      return 15;
    case LicenseType.C1:
      return 18;
    case LicenseType.D:
    case LicenseType.D1:
    case LicenseType.D2:
    case LicenseType.BE:
    case LicenseType.C1E:
    case LicenseType.CE:
    case LicenseType.D1E:
    case LicenseType.D2E:
    case LicenseType.DE:
      return 13;
    default:
      return 0; // Không có bộ đề cho các loại khác
  }
}

List<int> generateTestSetNumbers(LicenseType licenseType) {
  int numberOfSets = numberOfTestSetsBasedOnLicense(licenseType);
  return List.generate(numberOfSets, (index) => index + 1);
}

// StateNotifier for persistent license type
class LicenseTypeNotifier extends StateNotifier<LicenseType> {
  static const String _prefsKey = 'selected_license_type';

  LicenseTypeNotifier() : super(LicenseType.A1) {
    _loadLicenseType();
  }

  Future<void> _loadLicenseType() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString(_prefsKey);
      if (savedType != null) {
        final licenseType = LicenseType.values.firstWhere(
          (type) => type.name == savedType,
          orElse: () => LicenseType.A1,
        );
        state = licenseType;
      }
    } catch (e) {
      // If loading fails, keep default A1
      state = LicenseType.A1;
    }
  }

  Future<void> setLicenseType(LicenseType licenseType) async {
    state = licenseType;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, licenseType.name);
    } catch (e) {
      // Handle error if needed, but state is already updated
    }
  }
}

// Riverpod provider to store the currently selected license type.
// Default is A1 and persists selection across app restarts.
final licenseTypeProvider =
    StateNotifierProvider<LicenseTypeNotifier, LicenseType>((ref) {
      return LicenseTypeNotifier();
    });
