import 'package:gh247_user/core/data/local_storage.dart';
import 'package:gh247_user/core/services/api/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  // ignore: unused_field
  final ApiService _apiService;
  final LocalStorage _localService;

  AuthRepository(this._apiService, this._localService);

  Future<String> getAccessToken() async {
    return await _localService.getAccessToken();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final localService = ref.read(localStorageProvider);

  return AuthRepository(apiService, localService);
});

Future<AsyncValue<bool>> login() async {
  // TODO: implement login
  return Future.value(const AsyncValue.data(false));
}

Future<AsyncValue<bool>> logout() async {
  // TODO: implement login
  return Future.value(const AsyncValue.data(false));
}
