import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/answer.dart';
import 'package:gplx/features/test/models/question.dart';

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

class QuestionRepository {
  final _database = FirebaseDatabase.instance.ref();

  Future<List<Question>> fetchQuestions() async {
    try {
      final snapshot = await _database.limitToFirst(20).get();

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

      return questions;
    } catch (e, stackTrace) {
      print('Error fetching questions: $e\n$stackTrace');
      return [];
    }
  }
}
