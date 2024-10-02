import 'package:gh247_user/core/services/api/errors/error_code.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
