import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test_sets/controllers/test_controller.dart';

final deadPointQuestionsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final licenseType = ref.watch(licenseTypeProvider);
  try {
    final controller = TestController();
    final deadPointQuestions = await controller.fetchDeadPointQuestions(
      licenseType,
    );
    return deadPointQuestions.length;
  } catch (e) {
    return 0; // Trả về 0 nếu có lỗi
  }
});
