import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer.freezed.dart';
part 'answer.g.dart';

@freezed
sealed class Answer with _$Answer {
  factory Answer({
    @JsonKey(name: 'answer_content') required String content,
    @JsonKey(name: 'is_correct') required bool isCorrect,
  }) = _Answer;

  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
}

/// Data class for answer feedback
class AnswerFeedback {
  final bool isCorrect;
  final String feedbackText;
  final String correctAnswerText;
  final String? explanation;

  const AnswerFeedback({
    required this.isCorrect,
    required this.feedbackText,
    required this.correctAnswerText,
    this.explanation,
  });
}
