class ApiEndpoints {
  // static endpoints
  static const post = '/posts';
  static const refreshToken = '/refresh_token';
  static const logout = '/auth/logout';

  // Decalre dynamic endpoints here, for example:
  final int? userId;

  ApiEndpoints({
    this.userId,
  });

  String get postDetail => '/posts/$userId';
}
