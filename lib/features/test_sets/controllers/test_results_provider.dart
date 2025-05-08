import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:gplx/features/test_sets/controllers/test_results_repository.dart';

// Repository provider
final testResultsRepositoryProvider = Provider<TestResultsRepository>((ref) {
  return TestResultsRepository();
});

// StateNotifier to manage quiz results in memory
class TestResultsNotifier extends StateNotifier<List<QuizResult>> {
  final TestResultsRepository _repository;

  TestResultsNotifier(this._repository) : super([]) {
    // Initialize from SharedPreferences on creation
    _loadFromStorage();
  }

  // Load initial data from SharedPreferences
  Future<void> _loadFromStorage() async {
    final results = await _repository.getTestResults();
    state = results;
  }

  // Add a new quiz result
  Future<void> addResult(QuizResult result) async {
    // Extract test number from quiz ID or title
    int testNumber = _extractTestNumber(result.quizId, result.quizTitle);

    // Remove any existing result for this test number
    final filteredResults = state
        .where((item) =>
            _extractTestNumber(item.quizId, item.quizTitle) != testNumber)
        .toList();

    // Add the new result
    final newResults = [...filteredResults, result];

    // Update state
    state = newResults;

    // Also save to SharedPreferences for persistence
    await _repository.saveTestResult(result);
  }

  // Clear all results
  Future<void> clearAllResults() async {
    state = [];
    await _repository.clearAllResults();
  }

  // Helper method to extract test number from quiz ID or title
  int _extractTestNumber(String quizId, String quizTitle) {
    // Try to extract from quizId first
    if (quizId.contains('_')) {
      final parts = quizId.split('_');
      final parsed = int.tryParse(parts.last);
      if (parsed != null) return parsed;
    }

    // Try to extract from quizTitle
    final regExp = RegExp(r'\d+');
    final match = regExp.firstMatch(quizTitle);
    if (match != null) {
      return int.tryParse(match.group(0) ?? '0') ?? 0;
    }

    return 0;
  }
}

// StateNotifierProvider for quiz results
final testResultsNotifierProvider =
    StateNotifierProvider<TestResultsNotifier, List<QuizResult>>((ref) {
  final repository = ref.watch(testResultsRepositoryProvider);
  return TestResultsNotifier(repository);
});

// Legacy FutureProvider for backward compatibility
final testResultsProvider = FutureProvider<List<QuizResult>>((ref) async {
  // Just return the current state from the StateNotifierProvider
  return ref.watch(testResultsNotifierProvider);
});

// Provider for specific test result by number
final testResultProvider = Provider.family<QuizResult?, int>((ref, testNumber) {
  final results = ref.watch(testResultsNotifierProvider);
  try {
    return results.firstWhere((result) =>
        _extractTestNumber(result.quizId, result.quizTitle) == testNumber);
  } catch (e) {
    // Return null if not found
    return null;
  }
});

// Helper method to extract test number (same as in the notifier)
int _extractTestNumber(String quizId, String quizTitle) {
  // Try to extract from quizId first
  if (quizId.contains('_')) {
    final parts = quizId.split('_');
    final parsed = int.tryParse(parts.last);
    if (parsed != null) return parsed;
  }

  // Try to extract from quizTitle
  final regExp = RegExp(r'\d+');
  final match = regExp.firstMatch(quizTitle);
  if (match != null) {
    return int.tryParse(match.group(0) ?? '0') ?? 0;
  }

  return 0;
}
