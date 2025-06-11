import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/questions_repository.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test_sets/controllers/test_set_repository.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';

/// Provider to get questions based on TestSetId
final quizQuestionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  testSetId,
) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  final questionNumbers = await _getQuestionNumbers(ref, testSetId);
  return questionRepo.fetchQuestionsByNumbers(questionNumbers);
});

/// Provider to get TestSet information based on TestSetId
final testSetProvider = FutureProvider.family<TestSet?, String>((
  ref,
  testSetId,
) async {
  return await _createTestSet(ref, testSetId);
});

/// Repository provider for questions
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});

/// Provider to preload all questions when app starts
final preloadQuestionsProvider = FutureProvider<void>((ref) async {
  final questionRepo = ref.read(questionRepositoryProvider);
  // Load all questions into cache when app starts
  await questionRepo.fetchQuestions();
});

// Helper function to get question numbers based on test set ID
Future<List<int>> _getQuestionNumbers(Ref ref, String testSetId) async {
  final vehicleRepo = VehicleRepository();

  // Handle dead point questions
  if (testSetId.startsWith('deadpoints-')) {
    final vehicleType = testSetId.split('-')[1];
    return vehicleRepo.getDeadPointQuestions(vehicleType);
  }

  // Handle practice by chapter
  if (testSetId.startsWith('practice-')) {
    return _getPracticeQuestionNumbers(testSetId, vehicleRepo);
  }

  // Handle all questions for a vehicle type
  if (testSetId.startsWith('all-')) {
    final vehicleType = testSetId.split('-')[1];
    return vehicleRepo.getAllQuestions(vehicleType);
  }

  // Handle regular test sets
  final testSet = await ref.watch(testSetByIdProvider(testSetId).future);
  if (testSet == null) {
    throw Exception('Test set not found: $testSetId');
  }
  return testSet.questionNumbers;
}

// Helper function to get practice question numbers
List<int> _getPracticeQuestionNumbers(
    String testSetId, VehicleRepository vehicleRepo) {
  final parts = testSetId.split('-');
  if (parts.length < 3) {
    throw Exception('Invalid practice test set ID format: $testSetId');
  }

  final chapterKey = parts[1];
  final vehicleType = parts[2];

  final vehicle = vehicleRepo.getVehicleByType(vehicleType);
  if (vehicle == null) {
    throw Exception('Vehicle type not found: $vehicleType');
  }

  final targetChapter = vehicle.chapters[chapterKey];
  if (targetChapter == null) {
    throw Exception(
        'Chapter "$chapterKey" not found for vehicle type "$vehicleType"');
  }

  final questionNumbers = <int>[];

  // Get questions from sub-chapters if available
  if (targetChapter.subChapters?.isNotEmpty == true) {
    for (final subChapterQuestions in targetChapter.subChapters!.values) {
      questionNumbers.addAll(subChapterQuestions);
    }
  }
  // Get questions directly from chapter
  else if (targetChapter.questions != null) {
    questionNumbers.addAll(targetChapter.questions!);
  }

  return questionNumbers;
}

// Helper function to create TestSet objects
Future<TestSet?> _createTestSet(Ref ref, String testSetId) async {
  final vehicleRepo = VehicleRepository();

  // Handle dead point test set
  if (testSetId.startsWith('deadpoints-')) {
    final vehicleType = testSetId.split('-')[1];
    final deadPointNumbers = vehicleRepo.getDeadPointQuestions(vehicleType);

    return TestSet(
      id: testSetId,
      title: 'Dead point questions for $vehicleType license',
      vehicleType: vehicleType,
      questionNumbers: deadPointNumbers,
      description:
          'Collection of dead point questions for $vehicleType license',
    );
  }

  // Handle practice test set
  if (testSetId.startsWith('practice-')) {
    return _createPracticeTestSet(testSetId, vehicleRepo);
  }

  // Handle all questions test set
  if (testSetId.startsWith('all-')) {
    final vehicleType = testSetId.split('-')[1];
    final allQuestions = vehicleRepo.getAllQuestions(vehicleType);

    return TestSet(
      id: testSetId,
      title: 'All questions for $vehicleType license',
      vehicleType: vehicleType,
      questionNumbers: allQuestions,
      description: 'Complete question set for $vehicleType license',
    );
  }

  // Handle regular test sets
  return ref.watch(testSetByIdProvider(testSetId).future);
}

// Helper function to create practice test set
TestSet _createPracticeTestSet(
    String testSetId, VehicleRepository vehicleRepo) {
  final parts = testSetId.split('-');
  if (parts.length < 3) {
    throw Exception('Invalid practice test set ID format: $testSetId');
  }

  final chapterKey = parts[1];
  final vehicleType = parts[2];

  final vehicle = vehicleRepo.getVehicleByType(vehicleType);
  if (vehicle == null) {
    throw Exception('Vehicle type not found: $vehicleType');
  }

  final targetChapter = vehicle.chapters[chapterKey];
  if (targetChapter == null) {
    throw Exception(
        'Chapter "$chapterKey" not found for vehicle type "$vehicleType"');
  }

  final questionNumbers = <int>[];

  // Get questions from sub-chapters or directly from chapter
  if (targetChapter.subChapters?.isNotEmpty == true) {
    for (final subChapterQuestions in targetChapter.subChapters!.values) {
      questionNumbers.addAll(subChapterQuestions);
    }
  } else if (targetChapter.questions != null) {
    questionNumbers.addAll(targetChapter.questions!);
  }

  return TestSet(
    id: testSetId,
    title: 'Practice ${targetChapter.chapterName}',
    vehicleType: vehicleType,
    questionNumbers: questionNumbers,
    description:
        'Practice exercises for ${targetChapter.chapterName} - $vehicleType license',
  );
}
