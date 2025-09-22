import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer.dart';

part 'question.freezed.dart';
part 'question.g.dart';

@freezed
sealed class Question with _$Question {
  factory Question({
    @JsonKey(name: 'question_content') String? content,
    @JsonKey(name: 'question_number') int? number,
    @JsonKey(name: 'question_chapter') String? chapter,
    @JsonKey(name: 'driving_license_level') String? licenseLevel,
    @JsonKey(name: 'question_image') String? imageUrl,
    @JsonKey(name: 'question_dead_point') bool? isDeadPoint,
    List<Answer>? answers,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}
