import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import 'interceptors/device_id.dart';
import 'interceptors/error.dart';
import 'interceptors/logging.dart';

class DioClient {
  DioClient({required String baseUrl, required String deviceId})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.requestTimeout,
          sendTimeout: ApiConstants.requestTimeout,
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.addAll([
      DeviceIdInterceptor(deviceId),
      ApiErrorInterceptor(),
      ApiLoggingInterceptor(),
    ]);
  }

  final Dio dio;
}
