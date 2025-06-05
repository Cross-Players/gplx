import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer.dart';

part 'question.freezed.dart';
part 'question.g.dart';

@freezed
sealed class Question with _$Question {
  factory Question({
    required String content,
    required String explanation,
    required int number,
    required List<Answer> answers,
    String? imageUrl,
    bool? isDeadPoint,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}
