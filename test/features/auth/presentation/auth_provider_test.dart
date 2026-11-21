import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/core/storage/token_store.dart';
import 'package:shoplite/features/auth/data/auth_repository.dart';
import 'package:shoplite/features/auth/data/auth_session.dart';
import 'package:shoplite/features/auth/data/user_profile.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';

import '../../../helpers/fake_token_store.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _tokens = AuthTokens(accessToken: 'A', refreshToken: 'R');
const _emily = UserProfile(
  id: 1,
  username: 'emilys',
  firstName: 'Emily',
  lastName: 'Johnson',
);
const _noInternet = ApiException(
  type: ApiErrorType.noConnection,
  message: 'No internet',
);

void main() {
  late MockAuthRepository repo;
  late FakeTokenStore store;
  late AuthProvider auth;

  setUp(() {
    repo = MockAuthRepository();
    store = FakeTokenStore();
    auth = AuthProvider(repo, store);
  });

  void stubLoginSuccess() {
    when(
      () => repo.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const AuthSession(tokens: _tokens, user: _emily));
  }

  group('opening the app', () {
    test(
      'with no saved token the user is a guest and no profile is requested',
      () async {
        await auth.restore();

        expect(auth.status, AuthStatus.signedOut);
        verifyNever(() => repo.fetchProfile());
      },
    );

    test(
      'with a saved token the user is signed in and the profile loads',
      () async {
        await store.write(_tokens);
        when(() => repo.fetchProfile()).thenAnswer((_) async => _emily);

        await auth.restore();

        expect(auth.status, AuthStatus.signedIn);
        expect(auth.user!.fullName, 'Emily Johnson');
      },
    );

    test('being offline does not sign the user out', () async {
      await store.write(_tokens);
      when(() => repo.fetchProfile())
          .thenAnswer((_) => Future.error(_noInternet));

      await auth.restore();

      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user, isNull);
      expect(auth.profileError!.type, ApiErrorType.noConnection);
      expect(await store.read(), isNotNull);
    });

    test('a profile that arrives after sign out is ignored', () async {
      await store.write(_tokens);
      final completer = Completer<UserProfile>();
      when(() => repo.fetchProfile()).thenAnswer((_) => completer.future);

      final restoring = auth.restore();
      await Future<void>.delayed(Duration.zero);
      await auth.signOut();
      completer.complete(_emily);
      await restoring;

      expect(auth.user, isNull);
      expect(auth.status, AuthStatus.signedOut);
    });
  });

  group('signing in', () {
    test('success saves the tokens and returns no error', () async {
      stubLoginSuccess();

      final error = await auth.signIn('  emilys ', 'pw');

      expect(error, isNull);
      expect(auth.status, AuthStatus.signedIn);
      expect(auth.user!.username, 'emilys');
      expect((await store.read())!.accessToken, 'A');

      verify(() => repo.login(username: 'emilys', password: 'pw')).called(1);
    });

    test('wrong credentials are returned and nothing is saved', () async {
      when(
        () => repo.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) => Future.error(const ApiException.invalidCredentials()),
      );

      final error = await auth.signIn('emilys', 'bad');

      expect(error!.type, ApiErrorType.invalidCredentials);
      expect(auth.status, isNot(AuthStatus.signedIn));
      expect(await store.read(), isNull);
      expect(auth.signingIn, isFalse);
    });
  });

  group('signing out and losing the session', () {
    test('sign out clears the tokens and the user', () async {
      stubLoginSuccess();
      await auth.signIn('emilys', 'pw');

      await auth.signOut();

      expect(auth.status, AuthStatus.signedOut);
      expect(auth.user, isNull);
      expect(await store.read(), isNull);
    });

    test(
      'an expired session shows a notice once and signs the user out',
      () async {
        stubLoginSuccess();
        await auth.signIn('emilys', 'pw');

        auth.handleSessionExpired();
        expect(auth.status, AuthStatus.signedOut);
        expect(auth.notice, AuthProvider.sessionEndedNotice);

        auth.handleSessionExpired();
        expect(auth.notice, AuthProvider.sessionEndedNotice);

        auth.dismissNotice();
        expect(auth.notice, isNull);
      },
    );

    test('signing in again clears an old session notice', () async {
      stubLoginSuccess();
      await auth.signIn('emilys', 'pw');
      auth.handleSessionExpired();

      await auth.signIn('emilys', 'pw');

      expect(auth.notice, isNull);
      expect(auth.status, AuthStatus.signedIn);
    });
  });

  group('remembering who is signed in', () {
    test('the user id is saved at sign in and survives a restart', () async {
      stubLoginSuccess();
      await auth.signIn('emilys', 'pw');
      expect(auth.userId, 1);
      expect(await store.readUserId(), 1);

      when(() => repo.fetchProfile()).thenAnswer((_) async => _emily);
      final restarted = AuthProvider(repo, store);
      await restarted.restore();
      expect(restarted.userId, 1);
    });

    test('a missing id is filled in once the profile loads', () async {
      await store.write(_tokens);
      when(() => repo.fetchProfile()).thenAnswer((_) async => _emily);

      await auth.restore();

      expect(auth.userId, 1);
      expect(await store.readUserId(), 1);
    });

    test('signing out forgets the id', () async {
      stubLoginSuccess();
      await auth.signIn('emilys', 'pw');

      await auth.signOut();

      expect(auth.userId, isNull);
      expect(await store.readUserId(), isNull);
    });
  });
}
