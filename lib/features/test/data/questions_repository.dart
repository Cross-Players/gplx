import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:gplx/features/test/models/answer.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionRepository {
  final _database = FirebaseDatabase.instance.ref();
  static const String _questionsKey = 'cached_questions';

  // Lưu cache các câu hỏi đã tải để tối ưu hiệu suất trong bộ nhớ
  List<Question>? _cachedQuestions;

  // Tải tất cả câu hỏi
  Future<List<Question>> fetchQuestions() async {
    // 1. Kiểm tra cache trong bộ nhớ trước
    if (_cachedQuestions != null) {
      return _cachedQuestions!;
    }

    // 2. Thử tải từ SharedPreferences
    final savedQuestions = await _loadQuestionsFromCache();
    if (savedQuestions.isNotEmpty) {
      _cachedQuestions = savedQuestions;
      return savedQuestions;
    }

    // 3. Nếu không có, tải từ Firebase
    try {
      final snapshot = await _database.get();

      if (!snapshot.exists) return [];

      final List<dynamic> dataList = snapshot.value as List<dynamic>;
      List<Question> questions = [];

      for (var i = 0; i < dataList.length; i++) {
        if (dataList[i] == null) continue;

        final questionData = Map<String, dynamic>.from(dataList[i] as Map);

        // Check if answers exists and is a List
        if (!questionData.containsKey('answers') ||
            questionData['answers'] is! List) {
          print('Question $i has invalid answers format');
          continue;
        }

        final List<dynamic> answersData =
            questionData['answers'] as List<dynamic>;
        final answers = answersData
            .map((answerOption) {
              if (answerOption is! Map) return null;

              final answerMap = Map<String, dynamic>.from(answerOption);
              return Answer(
                answerContent: answerMap['answer_content'] ?? '',
                isCorrect: answerMap['is_correct'] ?? false,
              );
            })
            .where((a) => a != null)
            .cast<Answer>()
            .toList();

        questions.add(
          Question(
            content: questionData['question_content'] ?? '',
            explanation: questionData['question_explain'] ?? '',
            number: questionData['question_number'] ?? 0,
            answers: answers,
            imageUrl: questionData['question_image'] ?? '',
            isDeadPoint: questionData['question_dead_point'] ?? false,
          ),
        );
      }

      // Lưu kết quả vào cache bộ nhớ
      _cachedQuestions = questions;

      // Lưu vào SharedPreferences để sử dụng khi khởi động lại ứng dụng
      await _saveQuestionsToCache(questions);

      return questions;
    } catch (e, stackTrace) {
      print('Error fetching questions from Firebase: $e\n$stackTrace');
      return <Question>[];
    }
  }

  List<Question> fetchQuestionsByName(String questionName) {
    if (questionName.isEmpty) {
      return [];
    }
    try {
      final allQuestions = _cachedQuestions;
      if (allQuestions == null) {
        return [];
      }
      final filteredQuestions = allQuestions
          .where((question) => question.content
              .toLowerCase()
              .contains(questionName.toLowerCase()))
          .toList();

      return filteredQuestions;
    } catch (e, stackTrace) {
      print('Error fetching questions by name: $e\n$stackTrace');
      return [];
    }
  }

  // Phương thức để tải các câu hỏi theo số
  Future<List<Question>> fetchQuestionsByNumbers(
    List<int> questionNumbers,
  ) async {
    try {
      // Tải tất cả câu hỏi nếu chưa có trong cache
      final allQuestions = await fetchQuestions();

      if (allQuestions.isEmpty) return [];

      // Lọc các câu hỏi theo số
      final filteredQuestions = allQuestions
          .where((question) => questionNumbers.contains(question.number))
          .toList();

      // Sắp xếp câu hỏi theo thứ tự trong danh sách số câu hỏi
      filteredQuestions.sort((a, b) {
        final indexA = questionNumbers.indexOf(a.number);
        final indexB = questionNumbers.indexOf(b.number);
        return indexA.compareTo(indexB);
      });

      return filteredQuestions;
    } catch (e, stackTrace) {
      print('Error fetching questions by numbers: $e\n$stackTrace');
      return [];
    }
  }

  // Lưu danh sách câu hỏi vào SharedPreferences
  Future<void> _saveQuestionsToCache(List<Question> questions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = questions.map((question) => question.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(_questionsKey, jsonString);
      print('Questions saved to SharedPreferences cache');
    } catch (e, stackTrace) {
      print('Error saving questions to cache: $e\n$stackTrace');
    }
  }

  // Tải danh sách câu hỏi từ SharedPreferences
  Future<List<Question>> _loadQuestionsFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_questionsKey);

      if (jsonString == null || jsonString.isEmpty) {
        print('No cached questions found in SharedPreferences');
        return [];
      }

      print('Loading questions from SharedPreferences cache');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Question.fromJson(json)).toList();
    } catch (e, stackTrace) {
      print('Error loading questions from cache: $e\n$stackTrace');
      return [];
    }
  }

  // Xóa cache khi cần làm mới dữ liệu
  Future<void> clearCache() async {
    _cachedQuestions = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_questionsKey);
      print('Questions cache cleared');
    } catch (e) {
      print('Error clearing cached questions: $e');
    }
  }
}
