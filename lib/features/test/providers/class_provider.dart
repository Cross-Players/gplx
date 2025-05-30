// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // Default fallback ClassData to use when the selected ClassData can't be loaded

// // Provider for the currently selected ClassData ID
// final selectedClassDataIdProvider =
//     StateNotifierProvider<SelectedClassDataNotifier, String?>((ref) {
//   return SelectedClassDataNotifier();
// });

// // Provider that combines the selected ClassData ID with all ClassData
// // to return the actual ClassData object

// // Notifier class to manage the selected ClassData state
// class SelectedClassDataNotifier extends StateNotifier<String?> {
//   // Set default value to "A1" instead of null
//   SelectedClassDataNotifier() : super("A1") {
//     _loadFromPrefs();
//   }

//   // Load the selected ClassData from SharedPreferences
//   Future<void> _loadFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     // Use "A1" as default if no saved ClassData ID exists
//     final savedId = prefs.getString('selected_class_data_id') ?? "A1";
//     state = savedId;
//   }

//   // Update the selected ClassData and save to SharedPreferences
//   Future<void> setSelectedClassData(String classDataId) async {
//     state = classDataId;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('selected_class_data_id', classDataId);
//   }
// }

// // Legacy provider for backward compatibility with existing code that uses categories
// final selectedCategoryIdProvider = selectedClassDataIdProvider;
