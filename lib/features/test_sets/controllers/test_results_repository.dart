import 'dart:convert';

import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestResultsRepository {
  static const String _storageKey = 'test_results';

  // Save a new test result
  Future<void> saveTestResult(QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final currentResults = await getTestResults();

    // Extract test number from quiz ID or title
    int testNumber = _extractTestNumber(result.quizId, result.quizTitle);

    // Remove any existing result for this test number
    final filteredResults = currentResults
        .where((item) =>
            _extractTestNumber(item.quizId, item.quizTitle) != testNumber)
        .toList();

    // Add the new result
    filteredResults.add(result);

    // Convert to JSON and save
    final jsonList = filteredResults.map((item) => item.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Get all saved test results
  Future<List<QuizResult>> getTestResults() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => QuizResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If there's an error parsing the data, return an empty list
      print('Error parsing test results: $e');
      return [];
    }
  }

  // Get a specific test result by test number
  Future<QuizResult?> getTestResultByNumber(int testNumber) async {
    final results = await getTestResults();
    try {
      return results.firstWhere((result) =>
          _extractTestNumber(result.quizId, result.quizTitle) == testNumber);
    } catch (e) {
      // Return null if not found
      return null;
    }
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

  // Delete all saved test results
  Future<void> clearAllResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
