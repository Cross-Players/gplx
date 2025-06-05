import 'dart:math';

import 'package:gplx/features/test/data/vehicle_data.dart';
import 'package:gplx/features/test/models/vehicle.dart';

class VehicleRepository {
  static const List<Vehicle> _allVehicles = [a1, a2, b2];

  List<Vehicle> getAllVehicle() {
    return _allVehicles;
  }

  List<String> getAllVehicleTypes() {
    return _allVehicles.map((vehicle) => vehicle.vehicleType).toList();
  }

  Vehicle? getVehicleByType(String vehicleType) {
    try {
      return _allVehicles.firstWhere(
        (vehicle) =>
            vehicle.vehicleType.toUpperCase() == vehicleType.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  Vehicle getVehicle(String vehicleType) {
    final vehicle = getVehicleByType(vehicleType);
    if (vehicle != null) {
      return vehicle;
    }
    throw ArgumentError('Unknown vehicle type: $vehicleType');
  }

  Vehicle findVehicle(String vehicleType) {
    return getVehicle(vehicleType);
  }

  List<int> getDeadPointQuestions(String vehicleType) {
    return getVehicle(vehicleType).deadPointQuestions;
  }

  int getTotalQuestions(String vehicleType) {
    return getVehicle(vehicleType).getAllQuestionNumbers().length;
  }

  List<int> getDeadPointQuestionsList(String vehicleType) {
    return getVehicle(vehicleType).deadPointQuestions;
  }

  List<int> getAllQuestions(String vehicleType) {
    return getVehicle(vehicleType).getAllQuestionNumbers();
  }

  List<ChapterData> getAllChapters(Vehicle vehicle) {
    return vehicle.chapters.values.toList();
  }

  List<int> generateRandomTestSet(String vehicleType) {
    return generateTestQuestions(vehicleType);
  }

  List<List<int>> generateMultipleRandomTestSets(
    String vehicleType,
    int numberOfSets,
  ) {
    return generateMultipleTestSets(vehicleType, numberOfSets);
  }

  List<int> generateTestQuestions(String vehicleType) {
    final random = Random();
    final vehicle = findVehicle(vehicleType);
    final result = <int>[];
    final allSelectedQuestions = <int>{};
    Map<String, int> distribution;
    int requiredQuestionCount;

    switch (vehicleType.toUpperCase()) {
      case 'A1':
      case 'A2':
      case 'A3':
      case 'A4':
        distribution = <String, int>{
          'deadPoint': 1,
          'chapter1.1': 1,
          'chapter1.2': 6,
          'chapter1.3': 1,
          'chapter2': 0,
          'chapter3': 1,
          'chapter4': 1,
          'chapter5': 0,
          'chapter6': 7,
          'chapter7': 7,
        };
        requiredQuestionCount = 25;
        break;

      case 'B1':
        distribution = <String, int>{
          'deadPoint': 1,
          'chapter1.1': 1,
          'chapter1.2': 6,
          'chapter1.3': 1,
          'chapter2': 0,
          'chapter3': 1,
          'chapter4': 1,
          'chapter5': 1,
          'chapter6': 9,
          'chapter7': 9,
        };
        requiredQuestionCount = 30;
        break;

      case 'B2':
        distribution = <String, int>{
          'deadPoint': 1,
          'chapter1.1': 1,
          'chapter1.2': 7,
          'chapter1.3': 1,
          'chapter2': 1,
          'chapter3': 1,
          'chapter4': 2,
          'chapter5': 1,
          'chapter6': 10,
          'chapter7': 10,
        };
        requiredQuestionCount = 35;
        break;

      case 'C':
        distribution = <String, int>{
          'deadPoint': 1,
          'chapter1.1': 1,
          'chapter1.2': 7,
          'chapter1.3': 1,
          'chapter2': 1,
          'chapter3': 1,
          'chapter4': 2,
          'chapter5': 1,
          'chapter6': 14,
          'chapter7': 11,
        };
        requiredQuestionCount = 40;
        break;

      case 'D':
      case 'E':
      case 'F':
        distribution = <String, int>{
          'deadPoint': 1,
          'chapter1.1': 1,
          'chapter1.2': 7,
          'chapter1.3': 1,
          'chapter2': 1,
          'chapter3': 1,
          'chapter4': 2,
          'chapter5': 1,
          'chapter6': 16,
          'chapter7': 14,
        };
        requiredQuestionCount = 45;
        break;

      default:
        distribution = <String, int>{
          'deadPoint': 1,
          'chapter1.1': 1,
          'chapter1.2': 6,
          'chapter1.3': 1,
          'chapter3': 1,
          'chapter4': 1,
          'chapter5': 1,
          'chapter6': 7,
          'chapter7': 7,
        };
        requiredQuestionCount = 25;
    }

    _getQuestionsForTest(result, allSelectedQuestions, vehicle, distribution);

    _fillUpToRequiredQuestionCount(
        result, allSelectedQuestions, vehicle, requiredQuestionCount);

    result.shuffle(random);
    return result;
  }

  List<List<int>> generateMultipleTestSets(
      String vehicleType, int numberOfSets) {
    final result = <List<int>>[];
    for (int i = 0; i < numberOfSets; i++) {
      result.add(generateTestQuestions(vehicleType));
    }
    return result;
  }

  void _getQuestionsForTest(
    List<int> result,
    Set<int> allSelectedQuestions,
    Vehicle vehicle,
    Map<String, int> distribution,
  ) {
    if (distribution.containsKey('deadPoint')) {
      final deadPointCount = distribution['deadPoint'] ?? 0;
      final deadPointQuestions = _getRandomQuestions(
        vehicle.deadPointQuestions,
        deadPointCount,
        allSelectedQuestions,
      );
      result.addAll(deadPointQuestions);
      allSelectedQuestions.addAll(deadPointQuestions);
    }

    final chapter1 = vehicle.chapters['chapter 1'];
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
      vehicle,
      'chapter 3',
      distribution['chapter3'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      vehicle,
      'chapter 4',
      distribution['chapter4'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      vehicle,
      'chapter 5',
      distribution['chapter5'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      vehicle,
      'chapter 6',
      distribution['chapter6'] ?? 0,
    );

    _getQuestionsFromChapter(
      result,
      allSelectedQuestions,
      vehicle,
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
    Vehicle vehicle,
    String chapterKey,
    int count,
  ) {
    if (count <= 0) return;

    final chapter = vehicle.chapters[chapterKey];
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
    Vehicle vehicle,
    int requiredCount,
  ) {
    if (result.length < requiredCount) {
      final allQuestions = vehicle.getAllQuestionNumbers();
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
}
