import 'package:shoplite/core/storage/token_store.dart';

class FakeTokenStore implements TokenStore {
  AuthTokens? _tokens;
  int? _userId;

  FakeTokenStore([this._tokens, this._userId]);

  @override
  Future<AuthTokens?> read() async => _tokens;

  @override
  Future<void> write(AuthTokens tokens) async => _tokens = tokens;

  @override
  Future<int?> readUserId() async => _userId;

  @override
  Future<void> writeUserId(int id) async => _userId = id;

  @override
  Future<void> clear() async {
    _tokens = null;
    _userId = null;
  }
}