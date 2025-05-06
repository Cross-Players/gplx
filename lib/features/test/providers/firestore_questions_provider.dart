import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/data/firestore_questions_repository.dart';
import 'package:gplx/features/test/models/question.dart';

// Provider for the repository
final firestoreQuestionsRepositoryProvider =
    Provider<FirestoreQuestionsRepository>(
  (ref) => FirestoreQuestionsRepository(),
);

// AsyncNotifier to manage question state
class FirestoreQuestionsNotifier extends AsyncNotifier<List<Question>> {
  @override
  Future<List<Question>> build() async {
    // Default state is an empty list while loading
    return [];
  }

  Future<void> fetchAllQuestions() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreQuestionsRepositoryProvider);
      return repository.getAllQuestions();
    });
  }

  Future<void> fetchQuestionsBySet(String setId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreQuestionsRepositoryProvider);
      return repository.getQuestionsBySet(setId);
    });
  }

  Future<void> fetchRandomQuestions(int count) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(firestoreQuestionsRepositoryProvider);
      return repository.getRandomQuestions(count);
    });
  }
}

// Provider for the FirestoreQuestionsNotifier
final firestoreQuestionsProvider =
    AsyncNotifierProvider<FirestoreQuestionsNotifier, List<Question>>(
  () => FirestoreQuestionsNotifier(),
);

// Simple provider to get a specific question set by ID
final questionSetProvider = FutureProvider.family<List<Question>, String>(
  (ref, setId) {
    final repository = ref.read(firestoreQuestionsRepositoryProvider);
    return repository.getQuestionsBySet(setId);
  },
);
