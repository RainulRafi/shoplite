import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

class SecureTokenStore implements TokenStore {
  static const String _accessKey = 'auth_access_token';
  static const String _refreshKey = 'auth_refresh_token';

  final FlutterSecureStorage _storage;

  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<AuthTokens?> read() async {
    try {
      final access = await _storage.read(key: _accessKey);
      if (access == null || access.isEmpty) return null;
      final refresh = await _storage.read(key: _refreshKey) ?? '';
      return AuthTokens(accessToken: access, refreshToken: refresh);
    } on Exception {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    // ignore: empty_catches
    } on Exception {}
  }
}
