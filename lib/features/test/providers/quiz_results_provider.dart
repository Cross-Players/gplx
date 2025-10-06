import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for the list of quiz results
final quizResultsProvider = FutureProvider<List<QuizResult>>((ref) async {
  final notifier = ref.read(quizResultsNotifierProvider.notifier);
  return notifier.getResults();
});

// Provider for the quiz results notifier
final quizResultsNotifierProvider =
    StateNotifierProvider<QuizResultsNotifier, QuizResultsState>((ref) {
  return QuizResultsNotifier(ref);
});

// State class for quiz results
class QuizResultsState {
  final List<QuizResult> results;
  final bool isLoading;
  final String? error;

  const QuizResultsState({
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

// Notifier for managing quiz results
class QuizResultsNotifier extends StateNotifier<QuizResultsState> {
  final Ref _ref;
  static const String _storageKey = 'quiz_results';

  QuizResultsNotifier(this._ref) : super(const QuizResultsState()) {
    _loadResults();
  }

  // Load results from SharedPreferences
  Future<void> _loadResults() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = prefs.getString(_storageKey);

      if (resultsJson != null) {
        final List<dynamic> resultsData = jsonDecode(resultsJson);
        final results =
            resultsData.map((data) => QuizResult.fromJson(data)).toList();
        state = state.copyWith(results: results, isLoading: false);
      } else {
        state = state.copyWith(results: [], isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load quiz results: $e',
        isLoading: false,
      );
    }
  }

  // Add or update a quiz result
  Future<void> addResult(QuizResult result) async {
    try {
      final updatedResults = List<QuizResult>.from(state.results);

      // Find existing result with same quizId
      final existingIndex =
          updatedResults.indexWhere((r) => r.quizId == result.quizId);

      if (existingIndex >= 0) {
        updatedResults[existingIndex] = result;
      } else {
        updatedResults.add(result);
      }

      state = state.copyWith(results: updatedResults, error: null);
      await _saveResults();

      // Invalidate the provider to refresh UI
      _ref.invalidate(quizResultsProvider);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add result: $e');
    }
  }

  // Get all results (optimized async handling)
  List<QuizResult> getResults() {
    return state.results;
  }

  // Save results to SharedPreferences
  Future<void> _saveResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsJson = jsonEncode(
        state.results.map((result) => result.toJson()).toList(),
      );
      await prefs.setString(_storageKey, resultsJson);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save results: $e');
      rethrow;
    }
  }

  // Clear all results
  Future<void> clearAllResults() async {
    try {
      state = state.copyWith(results: [], error: null);
      await _saveResults();
      _ref.invalidate(quizResultsProvider);
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear results: $e');
    }
  }

  // Clear results for a specific vehicle type
  Future<void> clearResultsForVehicleType(String vehicleType) async {
    try {
      final filteredResults = state.results
          .where((result) => !_isResultForVehicleType(result, vehicleType))
          .toList();

      state = state.copyWith(results: filteredResults, error: null);
      await _saveResults();
      _ref.invalidate(quizResultsProvider);
    } catch (e) {
      state =
          state.copyWith(error: 'Failed to clear results for vehicle type: $e');
    }
  }

  // Get results for a specific vehicle type
  List<QuizResult> getResultsForVehicleType(String vehicleType) {
    return state.results
        .where((result) => _isResultForVehicleType(result, vehicleType))
        .toList();
  }

  // Helper method to check if result belongs to a vehicle type
  bool _isResultForVehicleType(QuizResult result, String vehicleType) {
    return result.quizId.contains(vehicleType) ||
        result.quizId.endsWith('-$vehicleType');
  }

  // Refresh results from storage
  Future<void> refresh() async {
    await _loadResults();
  }
}
