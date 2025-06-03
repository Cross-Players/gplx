import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/data/questions_repository.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test_sets/controllers/test_set_repository.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';

/// Provider để lấy câu hỏi dựa trên TestSetId
final quizQuestionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  testSetId,
) async {
  final questionRepo = ref.read(questionRepositoryProvider);

  // Kiểm tra nếu là deadpoints
  if (testSetId.startsWith('deadpoints-')) {
    final vehicleType =
        testSetId.split('-')[1]; // Extract vehicleType từ 'deadpoints-A1'
    final deadPointNumbers =
        VehicleRepository().getDeadPointQuestions(vehicleType);
    return questionRepo.fetchQuestionsByNumbers(deadPointNumbers);
  }
  if (testSetId.startsWith('practice-')) {
    // Trường hợp là đề luyện tập theo chương
    final parts = testSetId.split('-');
    // Format: practice-{chapterKey}-{vehicleType}
    // Ví dụ: practice-chapter 1-A1

    if (parts.length >= 3) {
      final chapterKey = parts[1]; // Key của chapter trong map vehicle.chapters
      final vehicleType = parts[2]; // Loại bằng lái xe (ví dụ: "A1")

      final vehicle = VehicleRepository().getVehicleByType(vehicleType);
      if (vehicle != null) {
        // Tìm chapter cụ thể từ key
        final targetChapter = vehicle.chapters[chapterKey];

        if (targetChapter != null) {
          // Lấy tất cả câu hỏi từ chapter cụ thể
          List<int> questionNumbers = [];

          // Nếu chapter có subChapters, lấy câu hỏi từ các subChapter
          if (targetChapter.subChapters != null &&
              targetChapter.subChapters!.isNotEmpty) {
            for (final subChapterQuestions
                in targetChapter.subChapters!.values) {
              questionNumbers.addAll(subChapterQuestions);
            }
          }
          // Nếu chapter có danh sách câu hỏi trực tiếp
          else if (targetChapter.questions != null) {
            questionNumbers.addAll(targetChapter.questions!);
          }

          return questionRepo.fetchQuestionsByNumbers(questionNumbers);
        }
      }

      // Nếu không tìm thấy chapter hoặc vehicle, ném ngoại lệ
      throw Exception(
          'Không tìm thấy chương "$chapterKey" cho loại bằng "$vehicleType"');
    }
  }

  if (testSetId.startsWith('all-')) {
    // Trường hợp là đề tất cả, có thể cần xử lý khác
    final vehicleType = testSetId.split('-')[1];
    final allQuestions = VehicleRepository().getAllQuestions(vehicleType);
    return questionRepo.fetchQuestionsByNumbers(allQuestions);
  }

  // Xử lý bình thường cho Test sets
  final testSet = await ref.watch(testSetByIdProvider(testSetId).future);

  if (testSet == null) {
    throw Exception('Không tìm thấy bộ đề $testSetId');
  }

  return questionRepo.fetchQuestionsByNumbers(testSet.questionNumbers);
});

/// Provider để lấy thông tin TestSet dựa trên TestSetId
final testSetProvider = FutureProvider.family<TestSet?, String>((
  ref,
  testSetId,
) async {
  // Xử lý trường hợp deadpoints
  if (testSetId.startsWith('deadpoints-')) {
    final vehicleType = testSetId.split('-')[1];
    final deadPointNumbers =
        VehicleRepository().getDeadPointQuestions(vehicleType);

    // Tạo một TestSet ảo cho deadpoints
    return TestSet(
      id: testSetId,
      title: 'Câu điểm liệt hạng $vehicleType',
      vehicleType: vehicleType,
      questionNumbers: deadPointNumbers,
      description: 'Tập hợp các câu hỏi điểm liệt cho hạng $vehicleType',
    );
  }
  if (testSetId.startsWith('practice-')) {
    final parts = testSetId.split('-');

    if (parts.length >= 3) {
      final chapterKey = parts[1]; // Key của chapter trong map
      final vehicleType = parts[2]; // Loại bằng lái

      final vehicle = VehicleRepository().getVehicleByType(vehicleType);
      if (vehicle != null) {
        final targetChapter = vehicle.chapters[chapterKey];

        if (targetChapter != null) {
          List<int> questionNumbers = [];

          if (targetChapter.subChapters != null &&
              targetChapter.subChapters!.isNotEmpty) {
            for (final subChapterQuestions
                in targetChapter.subChapters!.values) {
              questionNumbers.addAll(subChapterQuestions);
            }
          } else if (targetChapter.questions != null) {
            questionNumbers.addAll(targetChapter.questions!);
          }

          return TestSet(
            id: testSetId,
            title: 'Ôn tập ${targetChapter.chapterName}',
            vehicleType: vehicleType,
            questionNumbers: questionNumbers,
            description:
                'Bài tập ôn tập ${targetChapter.chapterName} cho hạng $vehicleType',
          );
        }
      }

      throw Exception(
          'Không tìm thấy chương "$chapterKey" cho loại bằng "$vehicleType"');
    }
  }

  if (testSetId.startsWith('all-')) {
    // Trường hợp là đề tất cả, có thể cần xử lý khác
    final vehicleType = testSetId.split('-')[1];
    final allQuestions = VehicleRepository().getAllQuestions(vehicleType);

    return TestSet(
      id: testSetId,
      title: 'Đề tất cả hạng $vehicleType',
      vehicleType: vehicleType,
      questionNumbers: allQuestions,
      description: 'Đề tất cả cho hạng $vehicleType',
    );
  }

  // Xử lý bình thường cho Test sets
  return ref.watch(testSetByIdProvider(testSetId).future);
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});
