class AuthTokens {
  final String accessToken;
  final String refreshToken; // ফাঁকা মানে নেই

  const AuthTokens({required this.accessToken, required this.refreshToken});

  bool get canRefresh => refreshToken.isNotEmpty;
}

abstract class TokenStore {
  Future<AuthTokens?> read();
  Future<void> write(AuthTokens tokens);
  Future<void> clear();
}
