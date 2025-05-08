import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';
part 'question.g.dart';

@freezed
class Question with _$Question {
  const factory Question({
    String? id,
    required String questionTitle,
    required List<String> options,
    required int correctOptionIndex,
    String? imageUrl,
    String? quizId,
    bool? isCritical,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}
