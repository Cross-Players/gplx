import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/data/local_storage.dart';
import 'package:gplx/core/services/api/api_response.dart';
import 'package:gplx/core/services/api/api_service.dart';
import 'package:gplx/core/services/api/errors/api_error.dart';
import 'package:gplx/core/services/api/errors/api_exceptions.dart';
import 'package:gplx/core/services/api/errors/error_code.dart';

class ApiInterceptor extends InterceptorsWrapper {
  ApiInterceptor({
    required Ref<ApiService>? ref,
    Dio? dio,
  })  : _ref = ref,
        _dio = dio;

  final Ref<ApiService>? _ref;
  // ignore: unused_field
  final Dio? _dio;

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['isAuthorized'] == false) {
      return;
    }

    // Default isAuthorized is true -> get token and add to headers
    final token = await _ref?.read(localStorageProvider).getAccessToken();

    if ((token ?? '').isNotEmpty) {
      options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Deserialize the gplx response from the JSON if needed
    try {
      // final baseResponse =
      //     ApiResponse.fromJson(response.data as Map<String, dynamic>);
      // response.data = baseResponse.data;

      super.onResponse(response, handler);
    } catch (e) {
      // If something goes wrong in deserialization, return the error
      throw ApiException(
        error: const ApiError(message: 'Failed to deserialize BaseResponse'),
        errorType: ApiErrorType.badResponse,
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: implement sutiable error message
    // or defined by message_key if need localization support
    var type = ApiErrorType.unknown;
    var message = err.message;

    switch (err.type) {
      case DioExceptionType.badResponse:
        // status code 401
        if (err.response?.statusCode == HttpStatus.unauthorized) {
          _handleUnauthorized(err, handler);

          return;
        }

        throw _getCustomError(err);
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        type = ApiErrorType.timeout;
        break;
      case DioExceptionType.connectionError:
        type = ApiErrorType.network;
        break;
      case DioExceptionType.cancel:
        type = ApiErrorType.cancel;
        break;
      default:
        type = ApiErrorType.unknown;
        message = 'Something went wrong, please try again!';
    }

    throw ApiException(
      error: ApiError(
        code: ErrorCode.dioException,
        message: message,
      ),
      errorType: type,
    );
  }

  ApiException _getCustomError(DioException err) {
    var type = ApiErrorType.badRequest;
    var message = err.message;
    ApiError? error;

    switch (err.response?.statusCode) {
      case HttpStatus.internalServerError: // 500
      case HttpStatus.badGateway: // 502
      case HttpStatus.serviceUnavailable: // 503
      case HttpStatus.gatewayTimeout: // 504
        type = ApiErrorType.server;
        message = 'Cant not connect to server, please try again later!';
        break;
      default:
        if (err.response?.data != null) {
          try {
            final baseResponse = ApiResponse.fromJson(
                err.response?.data as Map<String, dynamic>);
            error = baseResponse.error;
          } catch (e) {
            type = ApiErrorType.badResponse;
            message = 'Failed to deserialize BaseResponse';
          }
        }
        break;
    }

    return ApiException(
      error: error ?? ApiError(message: message),
      errorType: type,
    );
  }

  void _handleUnauthorized(DioException err, ErrorInterceptorHandler handler) {
    // TODO(anyone): implement handle unauthorized error
    // Maybe get re-get access token from refresh token
    // Or Clear session, show snackbar / alert
    // and force to login page if refresh token is expired
  }
}
