import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/storage/token_store.dart';
import 'package:shoplite/features/auth/data/auth_repository.dart';
import 'package:shoplite/features/auth/data/auth_session.dart';
import 'package:shoplite/features/auth/data/user_profile.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';

import 'fake_token_store.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const testUser = UserProfile(
  id: 1,
  username: 'emilys',
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@x.test',
);

const testUser2 = UserProfile(
  id: 2,
  username: 'michaelw',
  firstName: 'Michael',
  lastName: 'Williams',
);

class AuthRig {
  AuthRig() {
    when(() => repo.fetchProfile()).thenAnswer((_) async => testUser);
  }

  final MockAuthRepository repo = MockAuthRepository();
  final FakeTokenStore store = FakeTokenStore();
  late final AuthProvider auth = AuthProvider(repo, store);

  Future<void> signIn([UserProfile user = testUser]) async {
    when(
      () => repo.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) async => AuthSession(
        tokens: const AuthTokens(accessToken: 'A', refreshToken: 'R'),
        user: user,
      ),
    );
    await auth.signIn(user.username, 'pw');
  }

  void dispose() => auth.dispose();
}
