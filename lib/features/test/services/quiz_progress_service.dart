import 'dart:async';
import 'dart:convert';

import 'package:gplx/features/test/constants/quiz_constants.dart';
import 'package:gplx/features/test/models/quiz_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing quiz progress saving and loading
class QuizProgressService {
  static QuizProgressService? _instance;
  static QuizProgressService get instance =>
      _instance ??= QuizProgressService._();

  QuizProgressService._();

  /// Save quiz progress to SharedPreferences
  Future<void> saveProgress({
    required String testSetId,
    required Map<int, int> selectedAnswers,
    required Map<int, bool> checkedQuestions,
    required QuizResult quizResult,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedData = _createSaveData(
        selectedAnswers: selectedAnswers,
        checkedQuestions: checkedQuestions,
        quizResult: quizResult,
      );

      await prefs.setString(
        '${QuizConstants.quizProgressPrefix}$testSetId',
        jsonEncode(savedData),
      );
    } catch (e) {
      print('${QuizConstants.saveProgressErrorMessage}$e');
      rethrow;
    }
  }

  /// Load saved quiz progress from SharedPreferences
  Future<QuizProgressData?> loadProgress(String testSetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedQuizJson =
          prefs.getString('${QuizConstants.quizProgressPrefix}$testSetId');

      if (savedQuizJson != null) {
        final savedData = jsonDecode(savedQuizJson) as Map<String, dynamic>;
        return _parseProgressData(savedData);
      }

      return null;
    } catch (e) {
      print('${QuizConstants.loadProgressErrorMessage}$e');
      return null;
    }
  }

  /// Clear saved quiz progress
  Future<void> clearProgress(String testSetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${QuizConstants.quizProgressPrefix}$testSetId');
    } catch (e) {
      print('${QuizConstants.clearProgressErrorMessage}$e');
    }
  }

  /// Create save data map
  Map<String, dynamic> _createSaveData({
    required Map<int, int> selectedAnswers,
    required Map<int, bool> checkedQuestions,
    required QuizResult quizResult,
  }) {
    final selectedAnswersMap = <String, int>{};
    selectedAnswers.forEach((key, value) {
      selectedAnswersMap[key.toString()] = value;
    });

    final checkedQuestionsMap = <String, bool>{};
    checkedQuestions.forEach((key, value) {
      checkedQuestionsMap[key.toString()] = value;
    });

    return {
      QuizConstants.selectedAnswersKey: selectedAnswersMap,
      QuizConstants.checkedQuestionsKey: checkedQuestionsMap,
      QuizConstants.quizResultKey: quizResult.toJson(),
      QuizConstants.lastSavedKey: DateTime.now().toIso8601String(),
    };
  }

  /// Parse progress data from saved JSON
  QuizProgressData _parseProgressData(Map<String, dynamic> savedData) {
    // Parse selected answers
    final selectedAnswers = <int, int>{};
    if (savedData.containsKey(QuizConstants.selectedAnswersKey)) {
      final selectedAnswersMap =
          savedData[QuizConstants.selectedAnswersKey] as Map<String, dynamic>;
      selectedAnswersMap.forEach((key, value) {
        selectedAnswers[int.parse(key)] = value as int;
      });
    }

    // Parse checked questions
    final checkedQuestions = <int, bool>{};
    if (savedData.containsKey(QuizConstants.checkedQuestionsKey)) {
      final checkedQuestionsMap =
          savedData[QuizConstants.checkedQuestionsKey] as Map<String, dynamic>;
      checkedQuestionsMap.forEach((key, value) {
        checkedQuestions[int.parse(key)] = value as bool;
      });
    }

    // Parse quiz result
    QuizResult? quizResult;
    if (savedData.containsKey(QuizConstants.quizResultKey)) {
      quizResult = _parseQuizResultFromSaved(
          savedData[QuizConstants.quizResultKey] as Map<String, dynamic>);
    }

    return QuizProgressData(
      selectedAnswers: selectedAnswers,
      checkedQuestions: checkedQuestions,
      quizResult: quizResult,
    );
  }

  /// Parse QuizResult from saved data
  QuizResult _parseQuizResultFromSaved(Map<String, dynamic> quizResultMap) {
    return QuizResult(
      quizId: quizResultMap[QuizConstants.quizIdKey] as String,
      quizTitle: quizResultMap[QuizConstants.quizTitleKey] as String,
      totalQuestions: quizResultMap[QuizConstants.totalQuestionsKey] as int,
      correctAnswers: quizResultMap[QuizConstants.correctAnswersKey] as int,
      wrongAnswers: quizResultMap[QuizConstants.wrongAnswersKey] as int,
      attemptDate:
          DateTime.parse(quizResultMap[QuizConstants.attemptDateKey] as String),
      failedCriticalQuestion:
          quizResultMap[QuizConstants.failedCriticalQuestionKey] as bool?,
      timeTaken: quizResultMap[QuizConstants.timeTakenKey] != null
          ? Duration(seconds: quizResultMap[QuizConstants.timeTakenKey] as int)
          : null,
      minPoint: quizResultMap[QuizConstants.minPointKey] as int? ?? 0,
      isPassed: quizResultMap[QuizConstants.isPassedKey] as bool?,
      selectedAnswers: quizResultMap[QuizConstants.selectedAnswersKey] != null
          ? Map<String, int>.from(
              quizResultMap[QuizConstants.selectedAnswersKey] as Map)
          : null,
    );
  }
}

/// Data class for quiz progress
class QuizProgressData {
  final Map<int, int> selectedAnswers;
  final Map<int, bool> checkedQuestions;
  final QuizResult? quizResult;

  const QuizProgressData({
    required this.selectedAnswers,
    required this.checkedQuestions,
    this.quizResult,
  });
}
