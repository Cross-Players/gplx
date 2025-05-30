import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/data/class_data.dart';
import 'package:gplx/features/test/models/class_data.dart';

final classDataRepositoryProvider = Provider<ClassDataRepository>(
  (ref) => ClassDataRepository(),
);

final selectedClassTypeProvider = StateProvider<ClassData>((ref) => a1);

class ClassDataRepository {
  List<ClassData> getAllClassData() {
    return ClassDataRepository.allClassData();
  }

  List<String> getAllClassTypes() {
    return ClassDataRepository.getAllAvailableClassTypes();
  }

  ClassData findClassData(String classType) {
    return ClassDataRepository.getClassData(classType);
  }

  List<int> generateExamQuestions(String classType) {
    final random = Random();
    final classData = findClassData(classType);
    final result = <int>[];
    final allSelectedQuestions = <int>{};

    final distribution = <String, int>{
      'deadPoint': 1,
      'chapter1.1': 1,
      'chapter1.2': 6,
      'chapter1.3': 1,
      'chapter3': 1,
      'chapter4': 1,
      'chapter6': 7,
      'chapter7': 7,
    };

    _getQuestionsForExam(result, allSelectedQuestions, classData, distribution);

    _fillUpToRequiredQuestionCount(result, allSelectedQuestions, classData, 25);

    result.shuffle(random);
    return result;
  }

  List<List<int>> generateMultipleExamSets(String classType, int numberOfSets) {
    final result = <List<int>>[];
    for (int i = 0; i < numberOfSets; i++) {
      result.add(generateExamQuestions(classType));
    }
    return result;
  }

  void _getQuestionsForExam(
    List<int> result,
    Set<int> allSelectedQuestions,
    ClassData classData,
    Map<String, int> distribution,
  ) {
    if (distribution.containsKey('deadPoint')) {
      final deadPointCount = distribution['deadPoint'] ?? 0;
      final deadPointQuestions = _getRandomQuestions(
        classData.deadPointQuestions,
        deadPointCount,
        allSelectedQuestions,
      );
      result.addAll(deadPointQuestions);
      allSelectedQuestions.addAll(deadPointQuestions);
    }

    final chapter1 = classData.chapters['chapter 1'];
    if (chapter1 != null && chapter1.subChapters != null) {
      _getQuestionsFromSubChapter(
        result,
        allSelectedQuestions,
        chapter1.subChapters!,
        'chapter 1.1',
        distribution['chapter1.1'] ?? 0,
      );

      _getQuestionsFromSubChapter(
        result,
        allSelectedQuestions,
        chapter1.subChapters!,
        'chapter 1.2',
        distribution['chapter1.2'] ?? 0,
      );

      _getQuestionsFromSubChapter(
        result,
        allSelectedQuestions,
        chapter1.subChapters!,
        'chapter 1.3',
        distribution['chapter1.3'] ?? 0,
      );
    }

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      classData,
      'chapter 3',
      distribution['chapter3'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      classData,
      'chapter 4',
      distribution['chapter4'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      classData,
      'chapter 5',
      distribution['chapter5'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      classData,
      'chapter 6',
      distribution['chapter6'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      classData,
      'chapter 7',
      distribution['chapter7'] ?? 0,
    );
  }

  void _getQuestionsFromSubChapter(
    List<int> result,
    Set<int> allSelectedQuestions,
    Map<String, List<int>> subChapters,
    String subChapterKey,
    int count,
  ) {
    if (count <= 0) return;

    final questions = subChapters[subChapterKey] ?? [];
    final selected = _getRandomQuestions(
      questions,
      count,
      allSelectedQuestions,
    );
    result.addAll(selected);
    allSelectedQuestions.addAll(selected);
  }

  void _getQuestionsFromChapter(
    List<int> result,
    Set<int> allSelectedQuestions,
    ClassData classData,
    String chapterKey,
    int count,
  ) {
    if (count <= 0) return;

    final chapter = classData.chapters[chapterKey];
    if (chapter != null) {
      final questions = chapter.getAllQuestionNumbers();
      final selected = _getRandomQuestions(
        questions,
        count,
        allSelectedQuestions,
      );
      result.addAll(selected);
      allSelectedQuestions.addAll(selected);
    }
  }

  void _fillUpToRequiredQuestionCount(
    List<int> result,
    Set<int> allSelectedQuestions,
    ClassData classData,
    int requiredCount,
  ) {
    if (result.length < requiredCount) {
      final allQuestions = classData.getAllQuestionNumbers();
      allQuestions.removeWhere((q) => allSelectedQuestions.contains(q));

      allQuestions.shuffle(Random());

      result.addAll(allQuestions.take(requiredCount - result.length));
    }
  }

  List<int> _getRandomQuestions(
    List<int> sourceQuestions,
    int count,
    Set<int> allSelectedQuestions,
  ) {
    final random = Random();

    final availableQuestions = List<int>.from(sourceQuestions);

    availableQuestions.removeWhere((q) => allSelectedQuestions.contains(q));

    if (availableQuestions.length <= count) {
      return availableQuestions;
    }

    final selected = <int>[];
    for (int i = 0; i < count; i++) {
      if (availableQuestions.isEmpty) break;
      final index = random.nextInt(availableQuestions.length);
      selected.add(availableQuestions[index]);
      availableQuestions.removeAt(index);
    }

    return selected;
  }

  static List<ClassData> allClassData() {
    return [a1, a2];
  }

  static ClassData? getClassDataByType(String classType) {
    try {
      return allClassData().firstWhere(
        (classData) =>
            classData.classType.toUpperCase() == classType.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<String> getAllAvailableClassTypes() {
    return allClassData().map((classData) => classData.classType).toList();
  }

  static ClassData getClassData(String classType) {
    final classData = getClassDataByType(classType);
    if (classData != null) {
      return classData;
    }
    throw ArgumentError('Unknown class type: $classType');
  }

  static List<int> getDeadPointQuestions(String classType) {
    return getClassData(classType).deadPointQuestions;
  }

  static int getTotalQuestions(String classType) {
    return getClassData(classType).getAllQuestionNumbers().length;
  }

  static List<int> getAllQuestions(String classType) {
    return getClassData(classType).getAllQuestionNumbers();
  }

  static List<int> generateRandomExamSet(String classType) {
    return ClassDataRepository().generateExamQuestions(classType);
  }

  static List<List<int>> generateMultipleRandomExamSets(
    String classType,
    int numberOfSets,
  ) {
    return ClassDataRepository().generateMultipleExamSets(
      classType,
      numberOfSets,
    );
  }
}
