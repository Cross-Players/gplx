// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gplx/features/test/models/category.dart';
// import 'package:gplx/features/test/providers/firestore_providers.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // Default fallback category to use when the selected category can't be loaded
// const _defaultCategory = Category(
//   id: "A1",
//   name: "A1",
//   description: "Xe máy dung tích xi-lanh dưới 50cm³",
// );

// // Provider for the currently selected category ID
// final selectedCategoryIdProvider =
//     StateNotifierProvider<SelectedCategoryNotifier, String?>((ref) {
//   return SelectedCategoryNotifier();
// });

// // Provider that combines the selected category ID with all categories
// // to return the actual Category object
// final selectedCategoryProvider = Provider<Category>((ref) {
//   final selectedId = ref.watch(selectedCategoryIdProvider);
//   if (selectedId == null) return _defaultCategory;

//   final categoriesAsync = ref.watch(categoriesNotifierProvider);
//   return categoriesAsync.when(
//     data: (categories) {
//       try {
//         return categories.firstWhere((category) => category.id == selectedId);
//       } catch (e) {
//         // If the selected category ID is not found, return the default category
//         return _defaultCategory;
//       }
//     },
//     loading: () => _defaultCategory,
//     error: (_, __) => _defaultCategory,
//   );
// });

// // Notifier class to manage the selected category state
// class SelectedCategoryNotifier extends StateNotifier<String?> {
//   // Set default value to "A1" instead of null
//   SelectedCategoryNotifier() : super("A1") {
//     _loadFromPrefs();
//   }

//   // Load the selected category from SharedPreferences
//   Future<void> _loadFromPrefs() async {
//     final prefs = await SharedPreferences.getInstance();
//     // Use "A1" as default if no saved category ID exists
//     final savedId = prefs.getString('selected_category_id') ?? "A1";
//     state = savedId;
//   }

//   // Update the selected category and save to SharedPreferences
//   Future<void> setSelectedCategory(String categoryId) async {
//     state = categoryId;
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('selected_category_id', categoryId);
//   }
// }
