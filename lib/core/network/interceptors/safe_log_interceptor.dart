import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SafeLogInterceptor extends Interceptor {
  final String tag;
  SafeLogInterceptor({this.tag = 'api'});

  static const String _startKey = '_logStartedAt';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now().millisecondsSinceEpoch;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, '${response.statusCode}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      err.requestOptions,
      err.response?.statusCode?.toString() ?? err.type.name,
    );
    handler.next(err);
  }

  void _log(RequestOptions options, String result) {
    final started = options.extra[_startKey];
    final ms = started is int
        ? ' (${DateTime.now().millisecondsSinceEpoch - started} ms)'
        : '';
    final query = options.uri.hasQuery ? '?${options.uri.query}' : '';
    debugPrint(
      '[$tag] ${options.method} ${options.uri.path}$query -> $result$ms',
    );
  }
}
