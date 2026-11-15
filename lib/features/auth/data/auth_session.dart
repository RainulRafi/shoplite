import '../../../core/storage/token_store.dart';
import 'user_profile.dart';

class AuthSession {
  final AuthTokens tokens;
  final UserProfile user;

  const AuthSession({required this.tokens, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      tokens: AuthTokens(
        accessToken: json['accessToken'] as String,

        refreshToken: json['refreshToken'] as String? ?? '',
      ),
      user: UserProfile.fromJson(json),
    );
  }
}
