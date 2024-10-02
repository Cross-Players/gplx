// import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

// Enum defines custom error form server
// For example:

enum ErrorCode {
  @JsonValue(1)
  dioException,

  @JsonValue(2)
  errorFoo,

  @JsonValue(3)
  errorBar,
  // ...

  @JsonValue(6969)
  serverNotHappy,

  @JsonValue(null)
  unknown
}
