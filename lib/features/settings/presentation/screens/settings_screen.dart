// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gplx/features/settings/providers/selected_category_provider.dart';
// import 'package:gplx/features/test/models/category.dart';
// import 'package:gplx/features/test/providers/firestore_providers.dart';

// class SettingsScreen extends ConsumerStatefulWidget {
//   const SettingsScreen({super.key});

//   @override
//   ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends ConsumerState<SettingsScreen> {
//   String selectedQuestionSet = '600 câu hỏi (Thử nghiệm)';

//   @override
//   Widget build(BuildContext context) {
//     // Get the currently selected category ID
//     final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

//     // Fetch all categories from Firebase
//     final categoriesAsync = ref.watch(categoriesNotifierProvider);

//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text('Thiết lập'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               // Save settings
//               Navigator.pop(context);
//             },
//             child: const Text(
//               'Done',
//               style: TextStyle(color: Colors.white, fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//       body: ListView(
//         children: [
//           const _SectionHeader(title: 'BỘ ĐỀ THI'),
//           RadioListTile(
//             title: const Text('450 câu hỏi'),
//             value: '450 câu hỏi',
//             groupValue: selectedQuestionSet,
//             onChanged: (value) {
//               setState(() {
//                 selectedQuestionSet = value.toString();
//               });
//             },
//           ),
//           RadioListTile(
//             title: const Text('600 câu hỏi (Thử nghiệm)'),
//             value: '600 câu hỏi (Thử nghiệm)',
//             groupValue: selectedQuestionSet,
//             onChanged: (value) {
//               setState(() {
//                 selectedQuestionSet = value.toString();
//               });
//             },
//           ),
//           const _SectionHeader(title: 'LOẠI BẰNG LÁI XE Ô TÔ'),

//           // Display categories from Firebase or loading indicator
//           categoriesAsync.when(
//             loading: () => const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(16.0),
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//             error: (error, stack) => Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Text('Lỗi tải danh mục: $error'),
//               ),
//             ),
//             data: (categories) {
//               if (categories.isEmpty) {
//                 return const Padding(
//                   padding: EdgeInsets.all(16.0),
//                   child: Text('Không có danh mục nào'),
//                 );
//               }

//               return Column(
//                 children: categories.map((category) {
//                   return _CategoryOption(
//                     category: category,
//                     isSelected: selectedCategoryId == category.id,
//                     onTap: () {
//                       // Save selected category to provider
//                       ref
//                           .read(selectedCategoryIdProvider.notifier)
//                           .setSelectedCategory(category.id);
//                     },
//                   );
//                 }).toList(),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SectionHeader extends StatelessWidget {
//   final String title;

//   const _SectionHeader({required this.title});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//       color: Colors.grey[100],
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 14,
//           fontWeight: FontWeight.w500,
//           color: Colors.grey,
//         ),
//       ),
//     );
//   }
// }

// class _CategoryOption extends StatelessWidget {
//   final Category category;
//   final bool isSelected;
//   final VoidCallback onTap;

//   const _CategoryOption({
//     required this.category,
//     required this.isSelected,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(category.name),
//       subtitle: Text(
//         category.description,
//         style: const TextStyle(fontSize: 12),
//       ),
//       trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
//       onTap: onTap,
//     );
//   }
// }
