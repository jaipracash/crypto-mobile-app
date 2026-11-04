import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import '../network/dio_client.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('SharedPreferences must be initialized in main.'),
);

final deviceIdProvider = Provider<String>(
  (ref) => throw StateError('The device ID must be initialized in main.'),
);

final apiBaseUrlProvider = Provider<String>(
  (ref) => ApiConstants.apiBaseUrl,
);

final dioProvider = Provider<DioClient>((ref) {
  return DioClient(
    baseUrl: ref.watch(apiBaseUrlProvider),
    deviceId: ref.watch(deviceIdProvider),
  );
});
