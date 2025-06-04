import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final answeredQuestionsProvider =
    StateNotifierProvider<AnsweredQuestionsNotifier, Map<String, int>>(
  (ref) => AnsweredQuestionsNotifier(),
);

class AnsweredQuestionsNotifier extends StateNotifier<Map<String, int>> {
  AnsweredQuestionsNotifier() : super({}) {
    _loadAnsweredQuestions();
  }

  Future<void> _loadAnsweredQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final answeredQuestionsJson = prefs.getString('answered_questions');

      if (answeredQuestionsJson != null) {
        final Map<String, dynamic> jsonData =
            jsonDecode(answeredQuestionsJson) as Map<String, dynamic>;

        final Map<String, int> data = {};
        jsonData.forEach((key, value) {
          data[key] = value as int;
        });

        state = data;
      }
    } catch (e) {
      print('Error loading answered questions: $e');
    }
  }

  Future<void> _saveAnsweredQuestions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('answered_questions', jsonEncode(state));
    } catch (e) {
      print('Error saving answered questions: $e');
    }
  }

  void updateAnsweredCount(String testSetId, int count) {
    final updatedState = Map<String, int>.from(state);
    updatedState[testSetId] = count;
    state = updatedState;
    _saveAnsweredQuestions();
  }

  int getAnsweredCount(String testSetId) {
    return state[testSetId] ?? 0;
  }

  void clearAnswersForTestSet(String testSetId) {
    final updatedState = Map<String, int>.from(state);
    if (updatedState.containsKey(testSetId)) {
      updatedState.remove(testSetId);
      state = updatedState;
      _saveAnsweredQuestions();
    }
  }
}
