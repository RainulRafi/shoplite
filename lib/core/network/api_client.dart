import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/safe_log_interceptor.dart';

Dio createDio() {
  assert(
    AppConfig.baseUrl.startsWith('http'),
    'API_BASE_URL must start with http:// or https://, but it is "${AppConfig.baseUrl}"',
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Accept': 'application/json'},
    ),
  );
  if (kDebugMode) dio.interceptors.add(SafeLogInterceptor());
  return dio;
}

class ApiClient {
  final Dio _dio;

  ApiClient({
    Dio? dio,
    TokenStore? tokenStore,
    void Function()? onSessionExpired,
    int accessTokenMinutes = AppConfig.accessTokenMinutes,
  }) : _dio = dio ?? createDio() {
    if (tokenStore != null) {
      _dio.interceptors.add(
        AuthInterceptor(
          dio: _dio,
          refreshDio: createDio(),
          store: tokenStore,
          accessTokenMinutes: accessTokenMinutes,
          onSessionExpired: onSessionExpired,
        ),
      );
    }
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = false,
  }) {
    return _run(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _options(requiresAuth),
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? data,
    bool requiresAuth = false,
  }) {
    return _run(
      () =>
          _dio.post<dynamic>(path, data: data, options: _options(requiresAuth)),
    );
  }

  Options? _options(bool requiresAuth) {
    if (!requiresAuth) return null;
    return Options(extra: {AuthInterceptor.requiresAuthKey: true});
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
