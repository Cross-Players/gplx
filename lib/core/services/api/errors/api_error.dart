import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gplx/core/services/api/errors/error_code.dart';

part 'api_error.freezed.dart';
part 'api_error.g.dart';

@freezed
class ApiError with _$ApiError {
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory ApiError({
    required String? message,
    ErrorCode? code,
  }) = _ApiError;

  factory ApiError.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorFromJson(json);
}
