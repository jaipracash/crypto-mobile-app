import 'package:dio/dio.dart';

class DeviceIdInterceptor extends Interceptor {
  DeviceIdInterceptor(this.deviceId);

  final String deviceId;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Device-ID'] = deviceId;
    handler.next(options);
  }
}
