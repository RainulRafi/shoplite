import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/core/network/interceptors/auth_interceptor.dart';
import 'package:shoplite/core/storage/token_store.dart';

import '../../helpers/fake_token_store.dart';

class _FakeServer implements HttpClientAdapter {
  _FakeServer({required this.validAccessToken});

  String validAccessToken;
  final String nextAccessToken = 'T1';
  bool refreshAllowed = true;
  bool refreshNetworkDown = false;
  bool alwaysReject = false;
  Duration refreshDelay = Duration.zero;

  final Map<String, int> hits = {};
  final List<String?> authHeaders = [];

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    hits[path] = (hits[path] ?? 0) + 1;

    if (path == '/auth/refresh') {
      await Future<void>.delayed(refreshDelay);
      if (refreshNetworkDown) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: 'offline',
        );
      }
      if (!refreshAllowed) {
        return _json({'message': 'Invalid refresh token'}, 401);
      }
      validAccessToken = nextAccessToken;
      return _json({'accessToken': nextAccessToken, 'refreshToken': 'R1'}, 200);
    }

    if (path == '/secure/missing') return _json({'message': 'Not found'}, 404);

    if (path.startsWith('/secure')) {
      final header = options.headers['Authorization'] as String?;
      authHeaders.add(header);
      if (!alwaysReject && header == 'Bearer $validAccessToken') {
        return _json({'ok': true}, 200);
      }
      return _json({'message': 'Token Expired!'}, 401);
    }

    authHeaders.add(options.headers['Authorization'] as String?);
    return _json({'ok': true}, 200);
  }

  @override
  void close({bool force = false}) {}
}

class _Rig {
  _Rig({AuthTokens? tokens, String serverToken = 'OLD'}) {
    store = FakeTokenStore(
      tokens ?? const AuthTokens(accessToken: 'T0', refreshToken: 'R0'),
    );
    server = _FakeServer(validAccessToken: serverToken);
    dio = _newDio();
    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        refreshDio: _newDio(),
        store: store,
        accessTokenMinutes: 30,
        onSessionExpired: () => expiredCalls++,
      ),
    );
  }

  late final FakeTokenStore store;
  late final _FakeServer server;
  late final Dio dio;
  int expiredCalls = 0;

  Dio _newDio() =>
      Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server;

  Future<Response<dynamic>> protected(String path) => dio.get<dynamic>(
    path,
    options: Options(extra: {AuthInterceptor.requiresAuthKey: true}),
  );
}

void main() {
  test('a protected request carries the stored token', () async {
    final rig = _Rig(serverToken: 'T0');

    final response = await rig.protected('/secure/me');

    expect(response.statusCode, 200);
    expect(rig.server.authHeaders.single, 'Bearer T0');
  });

  test('a public request never carries a token', () async {
    final rig = _Rig();

    await rig.dio.get<dynamic>('/products');

    expect(rig.server.authHeaders.single, isNull);
  });

  test(
    'an expired token is refreshed once and the request is retried',
    () async {
      final rig = _Rig();

      final response = await rig.protected('/secure/me');

      expect(response.statusCode, 200);
      expect(rig.server.hits['/auth/refresh'], 1);
      expect(rig.server.hits['/secure/me'], 2);
      final saved = await rig.store.read();
      expect(saved!.accessToken, 'T1');
      expect(saved.refreshToken, 'R1');
      expect(rig.expiredCalls, 0);
    },
  );

  test('several requests failing together trigger only one refresh', () async {
    final rig = _Rig();
    rig.server.refreshDelay = const Duration(milliseconds: 50);

    final responses = await Future.wait([
      rig.protected('/secure/a'),
      rig.protected('/secure/b'),
      rig.protected('/secure/c'),
    ]);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(rig.server.hits['/auth/refresh'], 1);
  });

  test('a rejected refresh token ends the session exactly once', () async {
    final rig = _Rig();
    rig.server.refreshAllowed = false;

    final results = await Future.wait([
      rig
          .protected('/secure/a')
          .then<Object?>((_) => null, onError: (Object e) => e),
      rig
          .protected('/secure/b')
          .then<Object?>((_) => null, onError: (Object e) => e),
    ]);

    expect(
      results.every((e) => e is DioException && e.error is SessionExpiredError),
      isTrue,
    );
    expect(rig.expiredCalls, 1);
    expect(await rig.store.read(), isNull);
  });

  test(
    'a network failure while refreshing does not sign the user out',
    () async {
      final rig = _Rig();
      rig.server.refreshNetworkDown = true;

      await expectLater(
        rig.protected('/secure/me'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.connectionError)
              .having(
                (e) => e.error is SessionExpiredError,
                'is expired',
                isFalse,
              ),
        ),
      );

      expect(rig.expiredCalls, 0);
      expect(await rig.store.read(), isNotNull);
    },
  );

  test('a retried request that is still rejected does not loop', () async {
    final rig = _Rig();
    rig.server.alwaysReject = true;

    await expectLater(
      rig.protected('/secure/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );

    expect(rig.server.hits['/auth/refresh'], 1);
  });

  test(
    'having no refresh token ends the session without calling the server',
    () async {
      final rig = _Rig(
        tokens: const AuthTokens(accessToken: 'T0', refreshToken: ''),
      );

      await expectLater(
        rig.protected('/secure/me'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error is SessionExpiredError,
            'is expired',
            isTrue,
          ),
        ),
      );

      expect(rig.server.hits['/auth/refresh'], isNull);
      expect(rig.expiredCalls, 1);
      expect(await rig.store.read(), isNull);
    },
  );

  test('only a 401 triggers a refresh, a 404 passes through', () async {
    final rig = _Rig();

    await expectLater(
      rig.protected('/secure/missing'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          404,
        ),
      ),
    );

    expect(rig.server.hits['/auth/refresh'], isNull);
  });
}
