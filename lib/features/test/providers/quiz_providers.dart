import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/vehicle_repository.dart';
import 'package:gplx/features/test/controllers/exam_set_repository.dart';
import 'package:gplx/features/test/data/questions_repository.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test_sets/models/exam_set.dart';

/// Provider để lấy câu hỏi dựa trên examSetId
final quizQuestionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  examSetId,
) async {
  final questionRepo = ref.read(questionRepositoryProvider);

  // Kiểm tra nếu là deadpoints
  if (examSetId.startsWith('deadpoints-')) {
    final classType =
        examSetId.split('-')[1]; // Extract classType từ 'deadpoints-A1'
    final deadPointNumbers =
        VehicleRepository().getDeadPointQuestions(classType);
    return questionRepo.fetchQuestionsByNumbers(deadPointNumbers);
  }

  // Xử lý bình thường cho exam sets
  final examSet = await ref.watch(examSetByIdProvider(examSetId).future);

  if (examSet == null) {
    throw Exception('Không tìm thấy bộ đề $examSetId');
  }

  return questionRepo.fetchQuestionsByNumbers(examSet.questionNumbers);
});

/// Provider để lấy thông tin examSet dựa trên examSetId
final examSetProvider = FutureProvider.family<ExamSet?, String>((
  ref,
  examSetId,
) async {
  // Xử lý trường hợp deadpoints
  if (examSetId.startsWith('deadpoints-')) {
    final classType = examSetId.split('-')[1];
    final deadPointNumbers =
        VehicleRepository().getDeadPointQuestions(classType);

    // Tạo một ExamSet ảo cho deadpoints
    return ExamSet(
      id: examSetId,
      title: 'Câu điểm liệt hạng $classType',
      vehicleType: classType,
      questionNumbers: deadPointNumbers,
      createdAt: DateTime.now(),
      description: 'Tập hợp các câu hỏi điểm liệt cho hạng $classType',
    );
  }

  // Xử lý bình thường cho exam sets
  return ref.watch(examSetByIdProvider(examSetId).future);
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository();
});
