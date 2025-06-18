import 'package:freezed_annotation/freezed_annotation.dart';

part 'test_set.freezed.dart';
part 'test_set.g.dart';

@freezed
abstract class TestSet with _$TestSet {
  const factory TestSet({
    required String id,
    required String title,
    required String vehicleType,
    required List<int> questionNumbers,
  }) = _TestSet;

  factory TestSet.fromJson(Map<String, dynamic> json) =>
      _$TestSetFromJson(json);
}
