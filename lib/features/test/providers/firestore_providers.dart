import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/data/firestore_repository.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test/models/quiz.dart';

// Provider for the repository
final firestoreRepositoryProvider = Provider<FirestoreRepository>(
  (ref) => FirestoreRepository(),
);

// Provider for quizzes
final quizzesProvider = FutureProvider<List<Quiz>>((ref) async {
  final repository = ref.read(firestoreRepositoryProvider);
  return repository.getAllQuizzes();
});

// Provider for a specific quiz by ID
final quizProvider = FutureProvider.family<Quiz?, String>((ref, quizId) async {
  final repository = ref.read(firestoreRepositoryProvider);
  return repository.getQuizById(quizId);
});

// AsyncNotifier to manage question state
class QuestionsNotifier extends AsyncNotifier<List<Question>> {
  @override
  Future<List<Question>> build() async {
    // Default state is an empty list while loading
    return [];
  }

  Future<void> fetchAllQuestions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreRepositoryProvider);
      return repository.getAllQuestions();
    });
  }

  Future<void> fetchQuestionsByQuizId(String quizId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreRepositoryProvider);
      return repository.getQuestionsByQuizId(quizId);
    });
  }

  Future<void> fetchRandomQuestions(int count) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreRepositoryProvider);
      return repository.getRandomQuestions(count);
    });
  }

  Future<int> getNextQuestionId() async {
    final repository = ref.read(firestoreRepositoryProvider);
    return repository.getNextQuestionId();
  }

  Future<void> addQuestion(Question question) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreRepositoryProvider);
      await repository.addQuestion(question);
      return [...state.value ?? [], question];
    });
  }
}

// Provider for the QuestionsNotifier
final questionsProvider =
    AsyncNotifierProvider<QuestionsNotifier, List<Question>>(
  () => QuestionsNotifier(),
);

// Provider for quizzes with notifier for adding new quizzes
class QuizzesNotifier extends AsyncNotifier<List<Quiz>> {
  @override
  Future<List<Quiz>> build() async {
    final repository = ref.read(firestoreRepositoryProvider);
    return repository.getAllQuizzes();
  }

  Future<void> addQuiz(Quiz quiz) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreRepositoryProvider);
      await repository.addQuiz(quiz);
      return [...state.value ?? [], quiz];
    });
  }

  Future<void> refreshQuizzes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreRepositoryProvider);
      return repository.getAllQuizzes();
    });
  }
}

// Updated provider for quizzes using the notifier
final quizzesNotifierProvider =
    AsyncNotifierProvider<QuizzesNotifier, List<Quiz>>(
  () => QuizzesNotifier(),
);
