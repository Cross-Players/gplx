import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';
import 'package:gh247_user/core/constants/app_configs.dart';
import 'package:gh247_user/core/services/api/api_interceptor.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provides the ApiService instance
final apiServiceProvider = Provider<ApiService>((ref) => ApiService(ref));

class ApiService {
  final Dio _dio;
  final ProviderRef<ApiService>? _ref;

  ApiService([this._ref])
      : _dio = Dio(
          BaseOptions(
            baseUrl:
                //AppConfigs.baseUrl,
                'https://jsonplaceholder.typicode.com',
            connectTimeout:
                Duration(seconds: int.parse(AppConfigs.connectTimeout)),
            receiveTimeout:
                Duration(seconds: int.parse(AppConfigs.receiveTimeout)),
          ),
        ) {
    _dio.interceptors.add(ApiInterceptor(
      ref: _ref,
      dio: _dio,
    ));

    // Logging in debug mode
    if (kDebugMode) {
      _dio.interceptors.addAll([
        AwesomeDioInterceptor(
          logRequestHeaders: false,
          logResponseHeaders: false,
          logRequestTimeout: false,
        ),
        CurlLoggerDioInterceptor(printOnSuccess: true)
      ]);
    }
  }

  Future<Response> get(
    String endpoint, {
    Options? options,
    Map<String, dynamic>? params,
    bool isAuthorized = true,
  }) {
    if (!isAuthorized) {
      options = options.unAuthorizeOptions();
    }

    final result = _dio.get(
      endpoint,
      options: options,
      queryParameters: params,
    );

    return result;
  }

  Future<Response> post(
    String endpoint, {
    required dynamic bodyData,
    Options? options,
    Map<String, dynamic>? params,
    bool isAuthorized = true,
  }) {
    if (!isAuthorized) {
      options = options.unAuthorizeOptions();
    }

    final result = _dio.post(
      endpoint,
      options: options,
      queryParameters: params,
      data: bodyData,
    );

    return result;
  }

  Future<Response> put(
    String endpoint, {
    Options? options,
    Map<String, dynamic>? params,
    bool isAuthorized = true,
  }) {
    if (!isAuthorized) {
      options = options.unAuthorizeOptions();
    }

    final result = _dio.put(
      endpoint,
      options: options,
      queryParameters: params,
    );

    return result;
  }

  Future<Response> delete(
    String endpoint, {
    Options? options,
    Map<String, dynamic>? params,
    dynamic data,
    bool isAuthorized = true,
  }) {
    if (!isAuthorized) {
      options = options.unAuthorizeOptions();
    }

    final result = _dio.delete(
      endpoint,
      options: options,
      queryParameters: params,
      data: data,
    );

    return result;
  }
}

extension OptionsExtension on Options? {
  Options? unAuthorizeOptions() {
    final option = this ?? Options();
    final extra = ((option).extra ?? <String, dynamic>{})
      ..addAll({'isAuthorized': false});

    return option..extra = extra;
  }
}
