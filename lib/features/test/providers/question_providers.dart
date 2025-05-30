// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gplx/features/test/controllers/class_data_repository.dart';
// import 'package:gplx/features/test/data/realtime_questions_repository.dart';
// import 'package:gplx/features/test/models/class_data.dart';
// import 'package:gplx/features/test/models/question.dart';

// final questionsProvider = FutureProvider<List<Question>>((ref) {
//   return ref.read(questionRepositoryProvider).fetchQuestions();
// });

// // Provider for fetching questions by class type
// final questionsByClassTypeProvider =
//     FutureProvider.family<List<Question>, String>((ref, classType) {
//   return ref
//       .read(questionRepositoryProvider)
//       .fetchQuestionsByClassType(classType);
// });

// // Provider for fetching dead point questions by class type
// final deadPointQuestionsProvider =
//     FutureProvider.family<List<Question>, String>((ref, classType) {
//   return ref
//       .read(questionRepositoryProvider)
//       .fetchDeadPointQuestions(classType: classType);
// });

// // Provider for fetching questions by chapter
// final questionsByChapterProvider =
//     FutureProvider.family<List<Question>, Map<String, String>>((ref, params) {
//   final classType = params['classType']!;
//   final chapterName = params['chapterName']!;
//   return ref
//       .read(questionRepositoryProvider)
//       .fetchQuestionsByChapter(classType, chapterName);
// });

// // Provider for ClassDataRepository
// final classDataRepositoryProvider = Provider<ClassDataRepository>((ref) {
//   return ClassDataRepository();
// });

// // AsyncNotifier to manage ClassData state using ClassDataRepository
// class ClassDataNotifier extends AsyncNotifier<List<ClassData>> {
//   @override
//   Future<List<ClassData>> build() async {
//     return _getClassDataList();
//   }

//   Future<void> refreshClassData() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       return _getClassDataList();
//     });
//   }

//   List<ClassData> _getClassDataList() {
//     // Get available class data from ClassDataRepository
//     return [
//       ClassDataRepository.a1,
//       ClassDataRepository.a2,
//     ];
//   }
// }

// // Provider for ClassData using the new ClassDataRepository-based notifier
// final classDataNotifierProvider =
//     AsyncNotifierProvider<ClassDataNotifier, List<ClassData>>(
//   () => ClassDataNotifier(),
// );

// // For backward compatibility, keep categoriesNotifierProvider but map ClassData to Category
// final categoriesNotifierProvider = classDataNotifierProvider;
