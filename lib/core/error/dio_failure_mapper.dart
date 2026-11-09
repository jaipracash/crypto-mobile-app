import 'package:dio/dio.dart';

import 'app_exception.dart';
import 'failure.dart';

Failure mapDioFailure(DioException error) {
  final appException = error.error;
  final code = appException is AppException ? appException.code : '';
  final message = appException is AppException
      ? appException.message
      : 'Unable to load market data. Please try again.';
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return Failure(
      FailureType.timeout,
      'The request timed out. Check your connection and retry.',
    );
  }
  if (error.type == DioExceptionType.connectionError) {
    return const Failure(FailureType.noInternet, 'You appear to be offline.');
  }
  return switch (code) {
    'UPSTREAM_RATE_LIMITED' => Failure(FailureType.rateLimited, message),
    'COIN_NOT_FOUND' => Failure(FailureType.notFound, message),
    'UPSTREAM_ERROR' => Failure(FailureType.server, message),
    _ => Failure(FailureType.unknown, message),
  };
}
