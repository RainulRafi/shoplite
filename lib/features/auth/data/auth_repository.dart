import 'auth_session.dart';
import 'user_profile.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String username,
    required String password,
  });

  Future<UserProfile> fetchProfile();
}
