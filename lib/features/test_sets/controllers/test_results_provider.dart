import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the list of test results
final testResultsProvider = FutureProvider<List<QuizResult>>((ref) async {
  final notifier = ref.read(testResultsNotifierProvider.notifier);
  return notifier.getResults();
});

// Provider for the test results notifier
final testResultsNotifierProvider =
    StateNotifierProvider<TestResultsNotifier, TestResultsState>((ref) {
  return TestResultsNotifier();
});

// State class for test results
class TestResultsState {
  final List<QuizResult> results;
  final bool isLoading;
  final String? error;

  TestResultsState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  TestResultsState copyWith({
    List<QuizResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return TestResultsState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier for managing test results
class TestResultsNotifier extends StateNotifier<TestResultsState> {
  TestResultsNotifier() : super(TestResultsState()) {
    _loadResults();
  }

  // Load results from SharedPreferences
  Future<void> _loadResults() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = prefs.getString('test_results');
      if (resultsJson != null) {
        final List<dynamic> resultsData = jsonDecode(resultsJson);
        final results =
            resultsData.map((data) => QuizResult.fromJson(data)).toList();
        state = state.copyWith(results: results, isLoading: false);
      } else {
        state = state.copyWith(results: [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Add a new result
  Future<void> addResult(QuizResult result) async {
    final updatedResults = [...state.results, result];
    state = state.copyWith(results: updatedResults);
    await _saveResults();
  }

  // Get all results
  Future<List<QuizResult>> getResults() async {
    if (state.isLoading) {
      // Wait for loading to complete
      await Future.delayed(const Duration(milliseconds: 100));
      return getResults();
    }
    return state.results;
  }

  // Save results to SharedPreferences
  Future<void> _saveResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = jsonEncode(
        state.results.map((result) => result.toJson()).toList(),
      );
      await prefs.setString('test_results', resultsJson);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear all results
  Future<void> clearResults() async {
    state = state.copyWith(results: []);
    await _saveResults();
  }

  // Clear results for a specific class type (A1, A2, etc.)
  Future<void> clearResultsForClassType(String classType) async {
    final filteredResults = state.results
        .where((result) => !result.quizId.endsWith('-$classType'))
        .toList();

    state = state.copyWith(results: filteredResults);
    await _saveResults();
  }

  // Get results for a specific class type
  List<QuizResult> getResultsForClassType(String classType) {
    return state.results
        .where((result) => result.quizId.endsWith('-$classType'))
        .toList();
  }
}
