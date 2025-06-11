import 'dart:math';

import 'package:gplx/features/test/data/vehicle_data.dart';
import 'package:gplx/features/test/models/vehicle.dart';

class VehicleRepository {
  static const List<Vehicle> _allVehicles = [a1, a2, b2];

  // Get all available vehicles
  List<Vehicle> getAllVehicle() {
    return _allVehicles;
  }

  // Get all vehicle type names
  List<String> getAllVehicleTypes() {
    return _allVehicles.map((vehicle) => vehicle.vehicleType).toList();
  }

  // Find vehicle by type (nullable)
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

  // Get vehicle by type (throws exception if not found)
  Vehicle getVehicle(String vehicleType) {
    final vehicle = getVehicleByType(vehicleType);
    if (vehicle != null) {
      return vehicle;
    }
    throw ArgumentError('Unknown vehicle type: $vehicleType');
  }

  // Get dead point questions for a vehicle type
  List<int> getDeadPointQuestions(String vehicleType) {
    return getVehicle(vehicleType).deadPointQuestions;
  }

  // Get total number of questions for a vehicle type
  int getTotalQuestions(String vehicleType) {
    return getVehicle(vehicleType).getAllQuestionNumbers().length;
  }

  // Get all question numbers for a vehicle type
  List<int> getAllQuestions(String vehicleType) {
    return getVehicle(vehicleType).getAllQuestionNumbers();
  }

  // Get all chapters for a vehicle
  List<ChapterData> getAllChapters(Vehicle vehicle) {
    return vehicle.chapters.values.toList();
  }

  // Generate random test questions based on distribution rules
  List<int> generateTestQuestions(String vehicleType) {
    final vehicle = getVehicle(vehicleType);
    final result = <int>[];
    final allSelectedQuestions = <int>{};

    final testConfig = _getTestConfiguration(vehicleType);

    _selectQuestionsByDistribution(
        result, allSelectedQuestions, vehicle, testConfig.distribution);

    _fillToRequiredCount(
        result, allSelectedQuestions, vehicle, testConfig.requiredCount);

    result.shuffle(Random());
    return result;
  }

  // Generate multiple test sets
  List<List<int>> generateMultipleTestSets(
      String vehicleType, int numberOfSets) {
    return List.generate(
        numberOfSets, (_) => generateTestQuestions(vehicleType));
  }

  // Test configuration structure
  ({Map<String, int> distribution, int requiredCount}) _getTestConfiguration(
      String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'A1':
      case 'A2':
      case 'A3':
      case 'A4':
        return (
          distribution: {
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
          },
          requiredCount: 25
        );

      case 'B1':
        return (
          distribution: {
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
          },
          requiredCount: 30
        );

      case 'B2':
        return (
          distribution: {
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
          },
          requiredCount: 35
        );

      case 'C':
        return (
          distribution: {
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
          },
          requiredCount: 40
        );

      case 'D':
      case 'E':
      case 'F':
        return (
          distribution: {
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
          },
          requiredCount: 45
        );

      default:
        return (
          distribution: {
            'deadPoint': 1,
            'chapter1.1': 1,
            'chapter1.2': 6,
            'chapter1.3': 1,
            'chapter3': 1,
            'chapter4': 1,
            'chapter5': 1,
            'chapter6': 7,
            'chapter7': 7,
          },
          requiredCount: 25
        );
    }
  }

  // Select questions based on distribution rules
  void _selectQuestionsByDistribution(
    List<int> result,
    Set<int> allSelectedQuestions,
    Vehicle vehicle,
    Map<String, int> distribution,
  ) {
    // Handle dead point questions
    _addDeadPointQuestions(result, allSelectedQuestions, vehicle, distribution);

    // Handle chapter 1 sub-chapters
    _addChapter1Questions(result, allSelectedQuestions, vehicle, distribution);

    // Handle other chapters
    for (final chapterKey in [
      'chapter2',
      'chapter3',
      'chapter4',
      'chapter5',
      'chapter6',
      'chapter7'
    ]) {
      _addChapterQuestions(result, allSelectedQuestions, vehicle, chapterKey,
          distribution[chapterKey] ?? 0);
    }
  }

  // Add dead point questions
  void _addDeadPointQuestions(
    List<int> result,
    Set<int> allSelectedQuestions,
    Vehicle vehicle,
    Map<String, int> distribution,
  ) {
    final deadPointCount = distribution['deadPoint'] ?? 0;
    if (deadPointCount > 0) {
      final selected = _selectRandomQuestions(
        vehicle.deadPointQuestions,
        deadPointCount,
        allSelectedQuestions,
      );
      result.addAll(selected);
      allSelectedQuestions.addAll(selected);
    }
  }

  // Add chapter 1 questions from sub-chapters
  void _addChapter1Questions(
    List<int> result,
    Set<int> allSelectedQuestions,
    Vehicle vehicle,
    Map<String, int> distribution,
  ) {
    final chapter1 = vehicle.chapters['chapter 1'];
    if (chapter1?.subChapters != null) {
      for (final subChapterKey in [
        'chapter 1.1',
        'chapter 1.2',
        'chapter 1.3'
      ]) {
        final count = distribution[subChapterKey.replaceAll(' ', '')] ?? 0;
        if (count > 0) {
          _addSubChapterQuestions(
            result,
            allSelectedQuestions,
            chapter1!.subChapters!,
            subChapterKey,
            count,
          );
        }
      }
    }
  }

  // Add questions from a specific sub-chapter
  void _addSubChapterQuestions(
    List<int> result,
    Set<int> allSelectedQuestions,
    Map<String, List<int>> subChapters,
    String subChapterKey,
    int count,
  ) {
    final questions = subChapters[subChapterKey] ?? [];
    final selected =
        _selectRandomQuestions(questions, count, allSelectedQuestions);
    result.addAll(selected);
    allSelectedQuestions.addAll(selected);
  }

  // Add questions from a specific chapter
  void _addChapterQuestions(
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
      final selected =
          _selectRandomQuestions(questions, count, allSelectedQuestions);
      result.addAll(selected);
      allSelectedQuestions.addAll(selected);
    }
  }

  // Fill remaining slots to reach required question count
  void _fillToRequiredCount(
    List<int> result,
    Set<int> allSelectedQuestions,
    Vehicle vehicle,
    int requiredCount,
  ) {
    if (result.length >= requiredCount) return;

    final remainingQuestions = vehicle
        .getAllQuestionNumbers()
        .where((q) => !allSelectedQuestions.contains(q))
        .toList();

    remainingQuestions.shuffle(Random());

    final needed = requiredCount - result.length;
    result.addAll(remainingQuestions.take(needed));
  }

  // Select random questions from a source list, avoiding duplicates
  List<int> _selectRandomQuestions(
    List<int> sourceQuestions,
    int count,
    Set<int> excludeQuestions,
  ) {
    final availableQuestions =
        sourceQuestions.where((q) => !excludeQuestions.contains(q)).toList();

    if (availableQuestions.length <= count) {
      return availableQuestions;
    }

    final random = Random();
    final selected = <int>[];
    final remaining = List<int>.from(availableQuestions);

    for (int i = 0; i < count && remaining.isNotEmpty; i++) {
      final index = random.nextInt(remaining.length);
      selected.add(remaining.removeAt(index));
    }

    return selected;
  }
}
