import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/controllers/exam_set_repository.dart';
import 'package:gplx/features/test/data/realtime_questions_repository.dart';
import 'package:gplx/features/test/models/question.dart';
import 'package:gplx/features/test_sets/models/exam_set.dart';

/// Provider để lấy câu hỏi dựa trên examSetId
final quizQuestionsProvider = FutureProvider.family<List<Question>, String>((
  ref,
  examSetId,
) async {
  // Lấy thông tin examSet
  final examSet = await ref.watch(examSetByIdProvider(examSetId).future);

  if (examSet == null) {
    throw Exception('Không tìm thấy bộ đề $examSetId');
  }

  // Lấy danh sách câu hỏi từ repository
  final questionRepo = ref.read(questionRepositoryProvider);
  return questionRepo.fetchQuestionsByNumbers(examSet.questionNumbers);
});

/// Provider để lấy thông tin examSet dựa trên examSetId
final examSetProvider = FutureProvider.family<ExamSet?, String>((
  ref, 
  examSetId,
) async {
  return ref.watch(examSetByIdProvider(examSetId).future);
});
