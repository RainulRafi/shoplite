import 'package:shoplite/core/storage/token_store.dart';

class FakeTokenStore implements TokenStore {
  AuthTokens? _tokens;

  FakeTokenStore([this._tokens]);

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<void> clear() async => _tokens = null;
}
