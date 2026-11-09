import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'app.dart';
import 'core/constants/storage_keys.dart';
import 'core/providers/core_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  var deviceId = preferences.getString(StorageKeys.deviceId);
  if (deviceId == null || deviceId.isEmpty) {
    deviceId = const Uuid().v4();
    await preferences.setString(StorageKeys.deviceId, deviceId);
  }
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        deviceIdProvider.overrideWithValue(deviceId),
      ],
      child: const CryptoResearchApp(),
    ),
  );
}
