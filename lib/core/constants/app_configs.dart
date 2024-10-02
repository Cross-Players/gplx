class AppConfigs {
  AppConfigs._();

  static const baseUrl = String.fromEnvironment('API_END_POINT');
  static const realtimeApiEndpoint =
      String.fromEnvironment('REALTIME_API_END_POINT');
  static const apiVersion = String.fromEnvironment('API_VERSION');
  static const appName = String.fromEnvironment('APP_NAME');
  static const appSuffix = String.fromEnvironment('APP_SUFFIX');
  static const connectTimeout = String.fromEnvironment('CONNECT_TIME_OUT');
  static const receiveTimeout = String.fromEnvironment('RECEIVE_TIME_OUT');
  static const loggingInterceptorEnabled =
      String.fromEnvironment('LOGGING_INTERCEPTOR_ENABLED');
}
