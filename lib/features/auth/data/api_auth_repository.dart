import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'auth_repository.dart';
import 'auth_session.dart';
import 'user_profile.dart';

import '../../../core/config/app_config.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _api;
  ApiAuthRepository(this._api);

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    try {
      final json = await _api.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
          'expiresInMins': AppConfig.accessTokenMinutes,
        },
      );
      return await _parse(
        () => AuthSession.fromJson(json as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      if (e.type == ApiErrorType.badRequest ||
          e.type == ApiErrorType.unauthorized) {
        throw const ApiException.invalidCredentials();
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> fetchProfile() async {
    final json = await _api.get('/auth/me', requiresAuth: true);
    return _parse(() => UserProfile.fromJson(json as Map<String, dynamic>));
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError catch (e) {
      if (kDebugMode) debugPrint('Could not parse response: $e');
      throw const ApiException.parsing();
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('Could not parse response: $e');
      throw const ApiException.parsing();
    }
  }
}
