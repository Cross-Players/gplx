import 'package:freezed_annotation/freezed_annotation.dart';

import 'answer.dart';

part 'question.freezed.dart';
part 'question.g.dart';

// Custom converter to handle int or String for question_chapter
class ChapterConverter implements JsonConverter<String?, dynamic> {
  const ChapterConverter();

  @override
  String? fromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  @override
  dynamic toJson(String? value) => value;
}

@freezed
sealed class Question with _$Question {
  factory Question({
    @JsonKey(name: 'question_content') String? content,
    @JsonKey(name: 'question_number') int? number,
    @JsonKey(name: 'question_chapter') @ChapterConverter() String? chapter,
    @JsonKey(name: 'driving_license_level') String? licenseLevel,
    @JsonKey(name: 'question_image') String? imageUrl,
    @JsonKey(name: 'question_dead_point') bool? isDeadPoint,
    List<Answer>? answers,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}
