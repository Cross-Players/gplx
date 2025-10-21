import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test/models/license_data.dart';
import 'package:gplx/features/test_sets/controllers/test_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

final deadPointQuestionsCountProvider =
    FutureProvider.family.autoDispose<int, LicenseType>((
  ref,
  licenseType,
) async {
  try {
    // 1. Try to get from cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'dead_point_count_${licenseType.name}';
    final cachedCount = prefs.getInt(cacheKey);

    if (cachedCount != null) {
      return cachedCount;
    }

    // 2. If not cached, fetch ALL test sets from Firebase
    final controller = TestController();
    final deadPointQuestions = await controller.fetchDeadPointQuestions(
      licenseType,
    );
    final count = deadPointQuestions.length;

    // 3. Cache the result for future use
    await prefs.setInt(cacheKey, count);

    return count;
  } catch (e) {
    return 0;
  }
});
