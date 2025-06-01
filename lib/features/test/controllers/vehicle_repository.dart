import 'dart:math';

import 'package:gplx/features/test/data/vehicle_data.dart';
import 'package:gplx/features/test/models/vehicle.dart';

class VehicleRepository {
  List<Vehicle> getAllVehicle() {
    return VehicleRepository.allVehicle();
  }

  List<String> getAllvehicleTypes() {
    return VehicleRepository.getAllAvailablevehicleTypes();
  }

  Vehicle findVehicle(String vehicleType) {
    return VehicleRepository.getVehicle(vehicleType);
  }

  List<int> generateExamQuestions(String vehicleType) {
    final random = Random();
    final vehicle = findVehicle(vehicleType);
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

    _getQuestionsForExam(result, allSelectedQuestions, vehicle, distribution);

    _fillUpToRequiredQuestionCount(result, allSelectedQuestions, vehicle, 25);

    result.shuffle(random);
    return result;
  }

  List<List<int>> generateMultipleExamSets(
      String vehicleType, int numberOfSets) {
    final result = <List<int>>[];
    for (int i = 0; i < numberOfSets; i++) {
      result.add(generateExamQuestions(vehicleType));
    }
    return result;
  }

  void _getQuestionsForExam(
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

  static List<Vehicle> allVehicle() {
    return [a1, a2];
  }

  static Vehicle? getVehicleByType(String vehicleType) {
    try {
      return allVehicle().firstWhere(
        (vehicle) =>
            vehicle.vehicleType.toUpperCase() == vehicleType.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  static List<String> getAllAvailablevehicleTypes() {
    return allVehicle().map((vehicle) => vehicle.vehicleType).toList();
  }

  static Vehicle getVehicle(String vehicleType) {
    final vehicle = getVehicleByType(vehicleType);
    if (vehicle != null) {
      return vehicle;
    }
    throw ArgumentError('Unknown class type: $vehicleType');
  }

  static List<int> getDeadPointQuestions(String vehicleType) {
    return getVehicle(vehicleType).deadPointQuestions;
  }

  static int getTotalQuestions(String vehicleType) {
    return getVehicle(vehicleType).getAllQuestionNumbers().length;
  }

  static List<int> getDeadPointQuestionsList(String vehicleType) {
    return getVehicle(vehicleType).deadPointQuestions;
  }

  static List<int> getAllQuestions(String vehicleType) {
    return getVehicle(vehicleType).getAllQuestionNumbers();
  }

  static List<int> generateRandomExamSet(String vehicleType) {
    return VehicleRepository().generateExamQuestions(vehicleType);
  }

  static List<List<int>> generateMultipleRandomExamSets(
    String vehicleType,
    int numberOfSets,
  ) {
    return VehicleRepository().generateMultipleExamSets(
      vehicleType,
      numberOfSets,
    );
  }
}
