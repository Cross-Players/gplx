import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_result.freezed.dart';
part 'quiz_result.g.dart';

@freezed
class QuizResult with _$QuizResult {
  const factory QuizResult({
    required String quizId,
    required String quizTitle,
    required int totalQuestions,
    required int minPoint,
    required int correctAnswers,
    required int wrongAnswers,
    required DateTime attemptDate,
    bool? isPassed,
    Duration? timeTaken,
    bool? failedCriticalQuestion,
  }) = _QuizResult;

  factory QuizResult.fromJson(Map<String, dynamic> json) =>
      _$QuizResultFromJson(json);
}
