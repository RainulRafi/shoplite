import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

enum ApiErrorType {
  noConnection,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  tooManyRequests,
  server,
  cancelled,
  parsing,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorType type;

  final String message;

  final int? statusCode;

  final String? serverMessage;

  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.serverMessage,
  });

  const ApiException.parsing()
    : type = ApiErrorType.parsing,
      message = 'The server sent data we could not read.',
      statusCode = null,
      serverMessage = null;

  bool get isRetryable =>
      type == ApiErrorType.noConnection ||
      type == ApiErrorType.timeout ||
      type == ApiErrorType.tooManyRequests ||
      type == ApiErrorType.server;

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message: 'The server took too long to respond. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiErrorType.noConnection,
          message: 'No internet connection. Check your network and try again.',
        );

      case DioExceptionType.badResponse:
        return _fromStatus(e.response);

      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiErrorType.cancelled,
          message: 'The request was cancelled.',
        );

      case DioExceptionType.badCertificate:
        return const ApiException(
          type: ApiErrorType.unknown,
          message: 'A secure connection could not be made.',
        );

      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return const ApiException(
            type: ApiErrorType.noConnection,
            message:
                'No internet connection. Check your network and try again.',
          );
        }
        return const ApiException(
          type: ApiErrorType.unknown,
          message: 'Something unexpected happened. Please try again.',
        );
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  static ApiException _fromStatus(Response<dynamic>? response) {
    final code = response?.statusCode;
    final serverMessage = _serverMessage(response);

    ApiException make(ApiErrorType type, String message) => ApiException(
      type: type,
      message: message,
      statusCode: code,
      serverMessage: serverMessage,
    );

    if (code == 400) {
      return make(ApiErrorType.badRequest, 'That request was not accepted.');
    }
    if (code == 401) {
      return make(
        ApiErrorType.unauthorized,
        'You are not signed in, or your session has ended.',
      );
    }
    if (code == 403) {
      return make(ApiErrorType.forbidden, 'You do not have access to this.');
    }
    if (code == 404) {
      return make(ApiErrorType.notFound, 'We could not find that.');
    }
    if (code == 429) {
      return make(
        ApiErrorType.tooManyRequests,
        'Too many requests. Please wait a moment and try again.',
      );
    }
    if (code != null && code >= 500) {
      return make(
        ApiErrorType.server,
        'The server had a problem. Please try again later.',
      );
    }
    return make(
      ApiErrorType.unknown,
      'Something unexpected happened. Please try again.',
    );
  }

  static String? _serverMessage(Response<dynamic>? response) {
    final data = response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return null;
  }

  @override
  String toString() => 'ApiException(${type.name}, $statusCode): $message';
}
