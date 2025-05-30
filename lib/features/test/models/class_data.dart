import 'package:freezed_annotation/freezed_annotation.dart';

part 'class_data.freezed.dart';
part 'class_data.g.dart';

@freezed
class ClassData with _$ClassData {
  const ClassData._();

  const factory ClassData({
    required String classType, // 'A1' or 'A2'
    required String description,
    required Map<String, ChapterData> chapters,
    required List<int> deadPointQuestions,
  }) = _ClassData;

  factory ClassData.fromJson(Map<String, dynamic> json) =>
      _$ClassDataFromJson(json);

  // Get all question numbers for this class
  List<int> getAllQuestionNumbers() {
    final List<int> allQuestions = [];

    for (final chapter in chapters.values) {
      allQuestions.addAll(chapter.getAllQuestionNumbers());
    }

    allQuestions.addAll(deadPointQuestions);
    return allQuestions;
  }

  // Check if a question is a dead point question
  bool isDeadPointQuestion(int questionNumber) {
    return deadPointQuestions.contains(questionNumber);
  }
}

@freezed
class ChapterData with _$ChapterData {
  const ChapterData._();

  const factory ChapterData({
    required String chapterName,
    Map<String, List<int>>? subChapters,
    List<int>? questions,
  }) = _ChapterData;

  factory ChapterData.fromJson(Map<String, dynamic> json) =>
      _$ChapterDataFromJson(json);

  // Get all question numbers in this chapter
  List<int> getAllQuestionNumbers() {
    if (subChapters != null) {
      final List<int> allQuestions = [];
      for (final questionList in subChapters!.values) {
        allQuestions.addAll(questionList);
      }
      return allQuestions;
    }
    return questions ?? [];
  }
}
