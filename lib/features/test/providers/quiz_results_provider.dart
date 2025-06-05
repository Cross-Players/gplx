import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the list of Quiz results
final quizResultsProvider = FutureProvider<List<QuizResult>>((ref) async {
  final notifier = ref.read(quizResultsNotifierProvider.notifier);
  return notifier.getResults();
});

// Provider for the Quiz results notifier
final quizResultsNotifierProvider =
    StateNotifierProvider<QuizResultsNotifier, QuizResultsState>((ref) {
  return QuizResultsNotifier();
});

// State Vehicle for Quiz results
class QuizResultsState {
  final List<QuizResult> results;
  final bool isLoading;
  final String? error;

  QuizResultsState({
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  QuizResultsState copyWith({
    List<QuizResult>? results,
    bool? isLoading,
    String? error,
  }) {
    return QuizResultsState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier for managing Quiz results
class QuizResultsNotifier extends StateNotifier<QuizResultsState> {
  QuizResultsNotifier() : super(QuizResultsState()) {
    _loadResults();
  }

  // Load results from SharedPreferences
  Future<void> _loadResults() async {
    state = state.copyWith(isLoading: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = prefs.getString('quiz_results');
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
    // Check if a result with the same quizId already exists
    final existingResultIndex =
        state.results.indexWhere((r) => r.quizId == result.quizId);

    List<QuizResult> updatedResults;
    if (existingResultIndex >= 0) {
      // Replace the existing result
      updatedResults = [...state.results];
      updatedResults[existingResultIndex] = result;
    } else {
      // Add as a new result
      updatedResults = [...state.results, result];
    }

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
      await prefs.setString('quiz_results', resultsJson);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear all results
  Future<void> clearResults() async {
    state = state.copyWith(results: []);
    await _saveResults();
  }

  // Clear results for a specific Vehicle type (A1, A2, etc.)
  Future<void> clearResultsForVehicleType(String vehicleType) async {
    final filteredResults = state.results
        .where((result) => !result.quizId.endsWith('-$vehicleType'))
        .toList();

    state = state.copyWith(results: filteredResults);
    await _saveResults();
  }

  // Get results for a specific Vehicle type
  List<QuizResult> getResultsForVehicleType(String vehicleType) {
    return state.results
        .where((result) => result.quizId.endsWith('-$vehicleType'))
        .toList();
  }
}
