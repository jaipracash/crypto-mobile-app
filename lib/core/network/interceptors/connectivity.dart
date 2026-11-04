import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

final isOfflineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = ref.watch(connectivityProvider);
  final initial = await connectivity.checkConnectivity();
  yield initial.every((result) => result == ConnectivityResult.none);
  await for (final results in connectivity.onConnectivityChanged) {
    yield results.every((result) => result == ConnectivityResult.none);
  }
});
