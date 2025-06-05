// Provider để lưu trữ các đề thi đã được generate
import 'package:flutter_riverpod/flutter_riverpod.dart';

final generatedTestSetsProvider = StateProvider<List<List<int>>>((ref) => []);