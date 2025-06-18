import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/test_sets/controllers/test_set_repository.dart';
import 'package:gplx/features/test_sets/models/test_set.dart';

final generatedTestSetsProvider = StateProvider<List<List<int>>>((ref) => []);
// Provider cho TestSetRepository
final testSetRepositoryProvider = Provider<TestSetRepository>((ref) {
  return TestSetRepository(ref);
});

// Provider cho một TestSet cụ thể theo ID
final testSetByIdProvider = FutureProvider.family<TestSet?, String>((
  ref,
  testSetId,
) async {
  return ref.read(testSetRepositoryProvider).getTestSetById(testSetId);
});
