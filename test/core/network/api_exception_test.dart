import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/network/api_exception.dart';

DioException _dioError(DioExceptionType type, {int? status, Object? error}) {
  final options = RequestOptions(path: '/test');
  return DioException(
    requestOptions: options,
    type: type,
    error: error,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status),
  );
}

void main() {
  group('ApiException.fromDio', () {
    test('every kind of timeout becomes a retryable timeout', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        final result = ApiException.fromDio(_dioError(type));
        expect(result.type, ApiErrorType.timeout);
        expect(result.isRetryable, isTrue);
      }
    });

    test('connection error means no connection and can be retried', () {
      final result = ApiException.fromDio(
        _dioError(DioExceptionType.connectionError),
      );
      expect(result.type, ApiErrorType.noConnection);
      expect(result.isRetryable, isTrue);
    });

    test('a wrapped SocketException is also treated as no connection', () {
      final result = ApiException.fromDio(
        _dioError(
          DioExceptionType.unknown,
          error: const SocketException('Failed host lookup'),
        ),
      );
      expect(result.type, ApiErrorType.noConnection);
    });

    test('404 is notFound and is not worth retrying', () {
      final result = ApiException.fromDio(
        _dioError(DioExceptionType.badResponse, status: 404),
      );
      expect(result.type, ApiErrorType.notFound);
      expect(result.statusCode, 404);
      expect(result.isRetryable, isFalse);
    });

    test('401 is unauthorized', () {
      final result = ApiException.fromDio(
        _dioError(DioExceptionType.badResponse, status: 401),
      );
      expect(result.type, ApiErrorType.unauthorized);
      expect(result.isRetryable, isFalse);
    });

    test('429 is retryable, 500 is a retryable server error', () {
      final tooMany = ApiException.fromDio(
        _dioError(DioExceptionType.badResponse, status: 429),
      );
      expect(tooMany.type, ApiErrorType.tooManyRequests);
      expect(tooMany.isRetryable, isTrue);

      final server = ApiException.fromDio(
        _dioError(DioExceptionType.badResponse, status: 500),
      );
      expect(server.type, ApiErrorType.server);
      expect(server.isRetryable, isTrue);
    });

    test('the server message is kept when the body has one', () {
      final options = RequestOptions(path: '/login');
      final error = DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: options,
          statusCode: 400,
          data: {'message': 'Invalid credentials'},
        ),
      );
      final result = ApiException.fromDio(error);
      expect(result.type, ApiErrorType.badRequest);
      expect(result.serverMessage, 'Invalid credentials');
    });
  });
  test('a parsing error is not worth retrying', () {
    const error = ApiException.parsing();
    expect(error.type, ApiErrorType.parsing);
    expect(error.isRetryable, isFalse);
  });
}
