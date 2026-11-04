import 'package:dio/dio.dart';

import '../../error/app_exception.dart';

class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final body = err.response?.data;
    if (body is Map<String, dynamic>) {
      final error = body['error'];
      if (error is Map<String, dynamic>) {
        final code = error['code']?.toString() ?? 'UNKNOWN';
        final message = error['message']?.toString() ?? 'The request failed.';
        handler.next(
          err.copyWith(
            error: AppException(
              code,
              message,
              statusCode: err.response?.statusCode,
            ),
          ),
        );
        return;
      }
    }
    handler.next(err);
  }
}
