class AuthTokens {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({required this.accessToken, required this.refreshToken});

  bool get canRefresh => refreshToken.isNotEmpty;
}

abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);

  Future<int?> readUserId();
  Future<void> writeUserId(int id);

  Future<void> clear();
}
