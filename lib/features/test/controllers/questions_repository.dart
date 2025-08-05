import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:gplx/core/services/cache_expiry_manager.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/models/answer.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionRepository {
  final _database = FirebaseDatabase.instance.ref();
  static const String _questionsKey = 'cached_questions';

  // Cache loaded questions in memory for performance optimization
  List<Question>? _cachedQuestions;

  // Load all questions with optimized caching strategy
  Future<List<Question>> fetchQuestions() async {
    // 1. Check memory cache first
    if (_cachedQuestions != null) {
      return _cachedQuestions!;
    }

    // 2. Try loading from SharedPreferences
    final savedQuestions = await _loadQuestionsFromCache();
    if (savedQuestions.isNotEmpty) {
      _cachedQuestions = savedQuestions;
      return savedQuestions;
    }

    // 3. If not available, load from Firebase
    return await _fetchQuestionsFromFirebase();
  }

  // Optimized Firebase fetching method
  Future<List<Question>> _fetchQuestionsFromFirebase() async {
    try {
      final snapshot = await _database.get();
      if (!snapshot.exists) return [];

      final dataList = snapshot.value as List<dynamic>?;
      if (dataList == null) return [];

      final questions = <Question>[];

      for (var i = 0; i < dataList.length; i++) {
        final questionData = dataList[i];
        if (questionData == null) continue;

        final question = _parseQuestionData(
            Map<String, dynamic>.from(questionData as Map), i);
        if (question != null) {
          questions.add(question);
        }
      }

      // Cache results in memory and SharedPreferences
      _cachedQuestions = questions;
      await _saveQuestionsToCache(questions);

      return questions;
    } catch (e, stackTrace) {
      print('Error fetching questions from Firebase: $e\n$stackTrace');
      return <Question>[];
    }
  }

  // Extract question parsing logic for better maintainability
  Question? _parseQuestionData(Map<String, dynamic> questionData, int index) {
    try {
      // Validate answers format
      if (!questionData.containsKey('answers') ||
          questionData['answers'] is! List) {
        print('Question $index has invalid answers format');
        return null;
      }

      final answersData = questionData['answers'] as List<dynamic>;
      final answers = answersData.whereType<Map>().map((answerOption) {
        final answerMap = Map<String, dynamic>.from(answerOption);
        return Answer(
          answerContent: answerMap['answer_content'] ?? '',
          isCorrect: answerMap['is_correct'] ?? false,
        );
      }).toList();

      return Question(
        content: questionData['question_content'] ?? '',
        explanation: questionData['question_explain'] ?? '',
        number: questionData['question_number'] ?? 0,
        answers: answers,
        imageUrl: questionData['question_image'] ?? '',
        isDeadPoint: questionData['question_dead_point'] ?? false,
      );
    } catch (e) {
      print('Error parsing question data at index $index: $e');
      return null;
    }
  }

  // Optimized search by question content
  Future<List<Question>> fetchQuestionsByName(String questionName) async {
    if (questionName.isEmpty) return [];

    try {
      final allQuestions = await fetchQuestions();
      return allQuestions
          .where((question) => question.content
              .toLowerCase()
              .contains(questionName.toLowerCase()))
          .toList();
    } catch (e, stackTrace) {
      print('Error fetching questions by name: $e\n$stackTrace');
      return [];
    }
  }

  // Get questions filtered by vehicle type excluding correctly answered ones
  Future<List<Question>> fetchQuestionsByIsCorrect(String vehicle) async {
    try {
      final allQuestions = await fetchQuestions();
      final vehicleQuestionNumbers =
          VehicleRepository().getAllQuestions(vehicle);
      final correctQuestionNumbers = await _getCorrectQuestionNumbers(vehicle);

      return allQuestions
          .where((question) =>
              vehicleQuestionNumbers.contains(question.number) &&
              !correctQuestionNumbers.contains(question.number))
          .toList();
    } catch (e, stackTrace) {
      print('Error fetching questions by wrong answers: $e\n$stackTrace');
      return [];
    }
  }

  // Load questions by specific numbers with maintained order
  Future<List<Question>> fetchQuestionsByNumbers(
      List<int> questionNumbers) async {
    if (questionNumbers.isEmpty) return [];

    try {
      final allQuestions = await fetchQuestions();
      if (allQuestions.isEmpty) return [];

      // Create a map for O(1) lookup
      final questionMap = {for (var q in allQuestions) q.number: q};

      // Return questions in the same order as requested numbers
      return questionNumbers
          .where((number) => questionMap.containsKey(number))
          .map((number) => questionMap[number]!)
          .toList();
    } catch (e, stackTrace) {
      print('Error fetching questions by numbers: $e\n$stackTrace');
      return [];
    }
  }

  // Get set of correctly answered question numbers
  Future<Set<int>> _getCorrectQuestionNumbers(String vehicle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final correctQuestionsJson =
          prefs.getString('correct_questions_$vehicle');

      if (correctQuestionsJson != null) {
        final List<dynamic> correctQuestionsList =
            jsonDecode(correctQuestionsJson);
        return correctQuestionsList.map((e) => e as int).toSet();
      }

      return <int>{};
    } catch (e) {
      print('Error getting correct question numbers: $e');
      return <int>{};
    }
  }

  // Save question as correctly answered
  Future<void> saveCorrectQuestion(int questionNumber, String vehicle) async {
    try {
      final correctQuestions = await _getCorrectQuestionNumbers(vehicle);
      correctQuestions.add(questionNumber);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'correct_questions_$vehicle',
        jsonEncode(correctQuestions.toList()),
      );
    } catch (e) {
      print('Error saving correct question: $e');
    }
  }

  // Remove question from correctly answered list
  Future<void> removeCorrectQuestion(int questionNumber, String vehicle) async {
    try {
      final correctQuestions = await _getCorrectQuestionNumbers(vehicle);
      correctQuestions.remove(questionNumber);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'correct_questions_$vehicle',
        jsonEncode(correctQuestions.toList()),
      );
    } catch (e) {
      print('Error removing correct question: $e');
    }
  }

  // Clear all correct questions for a vehicle type
  Future<void> clearCorrectQuestions(String vehicle) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('correct_questions_$vehicle');
    } catch (e) {
      print('Error clearing correct questions: $e');
    }
  }

  // Save questions list to SharedPreferences with expiry
  Future<void> _saveQuestionsToCache(List<Question> questions) async {
    try {
      final jsonList = questions.map((question) => question.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await CacheExpiryManager.setWithExpiry(_questionsKey, jsonString);
      print('Questions saved to cache with 30-day expiry');
    } catch (e, stackTrace) {
      print('Error saving questions to cache: $e\n$stackTrace');
    }
  }

  // Load questions list from SharedPreferences
  Future<List<Question>> _loadQuestionsFromCache() async {
    try {
      final jsonString = await CacheExpiryManager.getWithExpiry(_questionsKey);

      if (jsonString == null || jsonString.isEmpty) {
        print('No cached questions found or cache expired');
        return [];
      }

      print('Loading questions from cache');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Question.fromJson(json)).toList();
    } catch (e, stackTrace) {
      print('Error loading questions from cache: $e\n$stackTrace');
      return [];
    }
  }

  // Clear cache when data refresh is needed
  Future<void> clearCache() async {
    _cachedQuestions = null;
    try {
      await CacheExpiryManager.remove(_questionsKey);
      print('Questions cache cleared');
    } catch (e) {
      print('Error clearing cached questions: $e');
    }
  }
}
