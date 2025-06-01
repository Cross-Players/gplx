import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle.freezed.dart';
part 'vehicle.g.dart';

@freezed
class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String vehicleType, // 'A1' or 'A2'
    required String description,
    required int minutes,
    required int minPoint,
    required int totalQuestionsPerQuiz,
    required Map<String, ChapterData> chapters,
    required List<int> deadPointQuestions,
  }) = _Vehicle;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);

  // Get all question numbers for this Vehicle
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
