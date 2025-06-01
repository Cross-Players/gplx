import 'package:firebase_database/firebase_database.dart';
import 'package:gplx/features/test/models/answer.dart';
import 'package:gplx/features/test/models/question.dart';

class QuestionRepository {
  final _database = FirebaseDatabase.instance.ref();

  // Lưu cache các câu hỏi đã tải để tối ưu hiệu suất
  List<Question>? _cachedQuestions;

  // Tải tất cả câu hỏi
  Future<List<Question>> fetchQuestions() async {
    if (_cachedQuestions != null) {
      return _cachedQuestions!;
    }

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
      } // Lưu kết quả vào cache
      _cachedQuestions = questions;
      return questions;
    } catch (e, stackTrace) {
      print('Error fetching questions: $e\n$stackTrace');
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

  // Xóa cache khi cần làm mới dữ liệu
  void clearCache() {
    _cachedQuestions = null;
  }
}
