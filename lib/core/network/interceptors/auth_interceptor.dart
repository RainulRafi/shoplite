import 'dart:async';

import 'package:dio/dio.dart';

import '../../storage/token_store.dart';
import '../api_exception.dart';

class _RefreshRejected implements Exception {
  const _RefreshRejected();
}

class AuthInterceptor extends Interceptor {
  static const String requiresAuthKey = 'requiresAuth';

  static const String _retriedKey = 'authRetried';

  final Dio _dio;
  final Dio _refreshDio;
  final TokenStore _store;
  final int _accessTokenMinutes;
  final void Function()? _onSessionExpired;

  AuthInterceptor({
    required this._dio,
    required this._refreshDio,
    required this._store,
    required this._accessTokenMinutes,
    this._onSessionExpired,
  });

  Future<AuthTokens>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[requiresAuthKey] == true) {
      final tokens = await _store.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final needsAuth = options.extra[requiresAuthKey] == true;
    final alreadyRetried = options.extra[_retriedKey] == true;

    if (err.response?.statusCode != 401 || !needsAuth || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final usedToken = _bearerFrom(options.headers['Authorization']);
      final current = await _store.read();

      final AuthTokens fresh;
      if (current != null &&
          usedToken != null &&
          current.accessToken != usedToken) {
        fresh = current;
      } else {
        fresh = await _refresh();
      }

      final retryOptions = options.copyWith(
        headers: {
          ...options.headers,
          'Authorization': 'Bearer ${fresh.accessToken}',
        },
        extra: {...options.extra, _retriedKey: true},
      );
      final response = await _dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on _RefreshRejected {
      handler.reject(
        DioException(
          requestOptions: options,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: const SessionExpiredError(),
        ),
      );
    } on DioException catch (e) {
      handler.reject(e);
    }
  }

  String? _bearerFrom(Object? header) {
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }

  Future<AuthTokens> _refresh() {
    final running = _refreshing;
    if (running != null) return running;

    final future = _doRefresh().whenComplete(() => _refreshing = null);
    _refreshing = future;
    return future;
  }

  Future<AuthTokens> _doRefresh() async {
    final current = await _store.read();
    if (current == null || !current.canRefresh) {
      await _endSession();
      throw const _RefreshRejected();
    }

    try {
      final response = await _refreshDio.post<dynamic>(
        '/auth/refresh',
        data: {
          'refreshToken': current.refreshToken,
          'expiresInMins': _accessTokenMinutes,
        },
      );

      final data = response.data;
      final access = data is Map ? data['accessToken'] : null;
      if (access is! String || access.isEmpty) {
        await _endSession();
        throw const _RefreshRejected();
      }

      final newRefresh = (data as Map)['refreshToken'];
      final fresh = AuthTokens(
        accessToken: access,
        refreshToken: newRefresh is String && newRefresh.isNotEmpty
            ? newRefresh
            : current.refreshToken,
      );
      await _store.write(fresh);
      return fresh;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) {
        await _endSession();
        throw const _RefreshRejected();
      }
      rethrow;
    }
  }

  Future<void> _endSession() async {
    await _store.clear();
    _onSessionExpired?.call();
  }
}
