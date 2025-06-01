import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam_set.freezed.dart';
part 'exam_set.g.dart';

@freezed
abstract class ExamSet with _$ExamSet {
  const factory ExamSet({
    required String id,
    required String title,
    required String vehicleType,
    required List<int> questionNumbers,
    required DateTime createdAt,
    String? description,
  }) = _ExamSet;

  factory ExamSet.fromJson(Map<String, dynamic> json) =>
      _$ExamSetFromJson(json);
}
