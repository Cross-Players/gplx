import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gplx/core/services/api/errors/api_error.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

@freezed
class ApiResponse with _$ApiResponse {
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  factory ApiResponse({
    int? code,
    dynamic data,
    String? status,
    ApiError? error,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
}
