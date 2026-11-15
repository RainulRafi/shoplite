import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/config/app_config.dart';
import 'package:shoplite/core/network/api_client.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/features/auth/data/api_auth_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiAuthRepository repository;

  setUp(() {
    api = MockApiClient();
    repository = ApiAuthRepository(api);
  });

  final loginJson = {
    'id': 1,
    'username': 'emilys',
    'email': 'emily@x.test',
    'firstName': 'Emily',
    'lastName': 'Johnson',
    'image': 'https://x.test/e.png',
    'accessToken': 'ACCESS',
    'refreshToken': 'REFRESH',
  };

  test('login sends the credentials and reads tokens and user', () async {
    when(() => api.post('/auth/login', data: any(named: 'data')))
        .thenAnswer((_) async => loginJson);

    final session = await repository.login(username: 'emilys', password: 'pw');

    expect(session.tokens.accessToken, 'ACCESS');
    expect(session.tokens.refreshToken, 'REFRESH');
    expect(session.user.fullName, 'Emily Johnson');

    final sent =
        verify(() => api.post('/auth/login', data: captureAny(named: 'data')))
                .captured
                .single
            as Map<String, dynamic>;
    expect(sent['username'], 'emilys');
    expect(sent['password'], 'pw');
    expect(sent['expiresInMins'], AppConfig.accessTokenMinutes);
  });

  test('a rejected login becomes a clear invalid-credentials error', () async {
    for (final type in [ApiErrorType.badRequest, ApiErrorType.unauthorized]) {
      when(() => api.post('/auth/login', data: any(named: 'data')))
          .thenThrow(ApiException(type: type, message: 'raw'));

      await expectLater(
        repository.login(username: 'emilys', password: 'bad'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.invalidCredentials,
          ),
        ),
      );
    }
  });

  test(
    'other login errors, like no internet, pass through unchanged',
    () async {
      when(() => api.post('/auth/login', data: any(named: 'data'))).thenThrow(
        const ApiException(
          type: ApiErrorType.noConnection,
          message: 'No internet',
        ),
      );

      await expectLater(
        repository.login(username: 'emilys', password: 'pw'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.noConnection,
          ),
        ),
      );
    },
  );

  test('fetchProfile asks for a protected request', () async {
    when(() => api.get('/auth/me', requiresAuth: true))
        .thenAnswer((_) async => loginJson);

    final user = await repository.fetchProfile();

    expect(user.username, 'emilys');
    verify(() => api.get('/auth/me', requiresAuth: true)).called(1);
  });

  test(
    'a response without the required fields becomes a parsing error',
    () async {
      when(() => api.get('/auth/me', requiresAuth: true))
          .thenAnswer((_) async => {'unexpected': true});

      await expectLater(
        repository.fetchProfile(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.type,
            'type',
            ApiErrorType.parsing,
          ),
        ),
      );
    },
  );
}
