import 'package:dio/dio.dart';

class ApiLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Keep diagnostics concise and avoid logging personal headers or payloads.
    // ignore: avoid_print
    print('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // ignore: avoid_print
    print('<-- ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }
}
