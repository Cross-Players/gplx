// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gplx/features/test/data/firestore_categories_repository.dart';
// import 'package:gplx/features/test/data/firestore_questions_repository.dart';
// import 'package:gplx/features/test/data/firestore_quizzes_repository.dart';
// import 'package:gplx/features/test/models/category.dart';
// import 'package:gplx/features/test/models/question.dart';
// import 'package:gplx/features/test/models/quiz.dart';

// // Providers for repositories
// final firestoreCategoriesRepositoryProvider =
//     Provider<FirestoreCategoriesRepository>(
//   (ref) => FirestoreCategoriesRepository(),
// );

// final firestoreQuestionsRepositoryProvider =
//     Provider<FirestoreQuestionsRepository>(
//   (ref) => FirestoreQuestionsRepository(),
// );

// final firestoreQuizzesRepositoryProvider = Provider<FirestoreQuizzesRepository>(
//   (ref) => FirestoreQuizzesRepository(),
// );

// // Provider for quizzes
// final quizzesProvider = FutureProvider<List<Quiz>>((ref) async {
//   final repository = ref.read(firestoreQuizzesRepositoryProvider);
//   return repository.getAllQuizzes();
// });

// // Provider for a specific quiz by ID
// final quizProvider = FutureProvider.family<Quiz?, String>((ref, quizId) async {
//   final repository = ref.read(firestoreQuizzesRepositoryProvider);
//   return repository.getQuizById(quizId);
// });

// // Provider for categories
// final categoriesProvider = FutureProvider<List<Category>>((ref) async {
//   final repository = ref.read(firestoreCategoriesRepositoryProvider);
//   return repository.getAllCategories();
// });

// // Provider for quizzes by category
// final quizzesByCategoryProvider =
//     FutureProvider.family<List<Quiz>, String>((ref, categoryId) async {
//   final repository = ref.read(firestoreCategoriesRepositoryProvider);
//   return repository.getQuizzesByCategory(categoryId);
// });

// // AsyncNotifier to manage question state
// class QuestionsNotifier extends AsyncNotifier<List<Question>> {
//   @override
//   Future<List<Question>> build() async {
//     // Default state is an empty list while loading
//     return [];
//   }

//   Future<void> fetchAllQuestions() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreQuestionsRepositoryProvider);
//       return repository.getAllQuestions();
//     });
//   }

//   Future<void> fetchQuestionsByQuizId(String quizId) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreQuestionsRepositoryProvider);
//       return repository.getQuestionsBySet(quizId);
//     });
//   }

//   Future<void> fetchRandomQuestions(int count) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreQuestionsRepositoryProvider);
//       return repository.getRandomQuestions(count);
//     });
//   }

//   Future<int> getNextQuestionId() async {
//     final repository = ref.read(firestoreQuestionsRepositoryProvider);
//     return repository.getNextQuestionId();
//   }

//   Future<void> addQuestion(Question question) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreQuestionsRepositoryProvider);
//       await repository.addQuestion(question);
//       return [...state.value ?? [], question];
//     });
//   }
// }

// // Provider for the QuestionsNotifier
// final questionsProvider =
//     AsyncNotifierProvider<QuestionsNotifier, List<Question>>(
//   () => QuestionsNotifier(),
// );

// // Provider for quizzes with notifier for adding new quizzes
// class QuizzesNotifier extends AsyncNotifier<List<Quiz>> {
//   @override
//   Future<List<Quiz>> build() async {
//     final repository = ref.read(firestoreQuizzesRepositoryProvider);
//     return repository.getAllQuizzes();
//   }

//   Future<void> addQuiz(Quiz quiz) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreQuizzesRepositoryProvider);
//       await repository.addQuiz(quiz);
//       return [...state.value ?? [], quiz];
//     });
//   }

//   Future<void> refreshQuizzes() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreQuizzesRepositoryProvider);
//       return repository.getAllQuizzes();
//     });
//   }
// }

// // Updated provider for quizzes using the notifier
// final quizzesNotifierProvider =
//     AsyncNotifierProvider<QuizzesNotifier, List<Quiz>>(
//   () => QuizzesNotifier(),
// );

// // AsyncNotifier to manage category state
// class CategoriesNotifier extends AsyncNotifier<List<Category>> {
//   @override
//   Future<List<Category>> build() async {
//     final repository = ref.read(firestoreCategoriesRepositoryProvider);
//     return repository.getAllCategories();
//   }

//   Future<void> refreshCategories() async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreCategoriesRepositoryProvider);
//       return repository.getAllCategories();
//     });
//   }

//   Future<void> addCategory(Category category) async {
//     state = const AsyncValue.loading();
//     state = await AsyncValue.guard(() async {
//       final repository = ref.read(firestoreCategoriesRepositoryProvider);
//       await repository.addCategory(category);
//       return [...state.value ?? [], category];
//     });
//   }
// }

// // Provider for categories using the notifier
// final categoriesNotifierProvider =
//     AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
//   () => CategoriesNotifier(),
// );
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/data/realtime_questions_repository.dart';
import 'package:gplx/features/test/models/question.dart';

final questionsProvider = FutureProvider<List<Question>>((ref) {
  return ref.read(questionRepositoryProvider).fetchQuestions();
});