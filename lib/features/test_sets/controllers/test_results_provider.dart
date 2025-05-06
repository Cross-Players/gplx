import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test_sets/controllers/test_results_repository.dart';

// Repository provider
final testResultsRepositoryProvider = Provider<TestResultsRepository>((ref) {
  return TestResultsRepository();
});

// Provider for all test results
final testResultsProvider = FutureProvider<List<QuizResult>>((ref) async {
  final repository = ref.watch(testResultsRepositoryProvider);
  return repository.getTestResults();
});

// Provider for specific test result by number
final testResultProvider =
    FutureProvider.family<QuizResult?, int>((ref, testNumber) async {
  final repository = ref.watch(testResultsRepositoryProvider);
  return repository.getTestResultByNumber(testNumber);
});
