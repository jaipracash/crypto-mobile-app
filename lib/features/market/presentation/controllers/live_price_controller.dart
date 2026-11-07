import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/providers/core_providers.dart';
import '../../domain/coin.dart';

class LivePriceUpdate {
  const LivePriceUpdate({required this.coinId, required this.price});

  final String coinId;
  final double price;
}

final liveCoinPricesProvider =
    NotifierProvider<LiveCoinPricesController, Map<String, double>>(
      LiveCoinPricesController.new,
    );

class LiveCoinPricesController extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => const {};

  void apply(String currency, List<LivePriceUpdate> updates) {
    if (updates.isEmpty) return;
    final next = Map<String, double>.of(state);
    for (final update in updates) {
      next[_priceKey(currency, update.coinId)] = update.price;
    }
    state = Map.unmodifiable(next);
  }
}

final simulatedPriceUpdatesProvider = StreamProvider.autoDispose
    .family<List<LivePriceUpdate>, String>((ref, currency) async* {
      final apiUri = Uri.parse(ref.watch(apiBaseUrlProvider));
      final scheme = switch (apiUri.scheme) {
        'http' => 'ws',
        'https' => 'wss',
        'ws' || 'wss' => apiUri.scheme,
        _ => throw StateError(
          'Unsupported API URL scheme for the price stream: ${apiUri.scheme}',
        ),
      };
      final path =
          '${apiUri.path.replaceFirst(RegExp(r'/+$'), '')}/api/ws/prices';
      final socketUri = Uri(
        scheme: scheme,
        userInfo: apiUri.userInfo,
        host: apiUri.host,
        port: apiUri.hasPort ? apiUri.port : (scheme == 'wss' ? 443 : 80),
        path: path,
        queryParameters: {'currency': currency},
      );

      var disposed = false;
      var reconnectDelay = const Duration(seconds: 3);
      WebSocketChannel? channel;
      ref.onDispose(() {
        disposed = true;
        unawaited(channel?.sink.close());
      });

      while (!disposed) {
        try {
          final activeChannel = WebSocketChannel.connect(socketUri);
          channel = activeChannel;
          await activeChannel.ready;
          reconnectDelay = const Duration(seconds: 3);
          await for (final message in activeChannel.stream) {
            if (disposed) return;
            yield _decodeUpdates(message, currency);
          }
          if (!disposed) {
            throw StateError('The simulated price stream disconnected.');
          }
        } catch (error, stackTrace) {
          if (disposed) return;
          debugPrint(
            'Price stream disconnected; retrying in '
            '${reconnectDelay.inSeconds}s: $error\n$stackTrace',
          );
          await Future<void>.delayed(reconnectDelay);
          final nextDelaySeconds = reconnectDelay.inSeconds * 2;
          reconnectDelay = Duration(
            seconds: nextDelaySeconds > 60 ? 60 : nextDelaySeconds,
          );
        } finally {
          final activeChannel = channel;
          channel = null;
          if (activeChannel != null) {
            unawaited(activeChannel.sink.close());
          }
        }
      }
    });

List<LivePriceUpdate> _decodeUpdates(dynamic message, String currency) {
  final decoded = jsonDecode(message.toString());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Price stream message must be a JSON object.');
  }
  if (decoded['source'] != 'mock') {
    throw const FormatException('Unexpected price stream source.');
  }
  if (decoded['currency'] != currency) {
    throw const FormatException('Price stream currency does not match.');
  }

  final type = decoded['type'];
  final rawUpdates = switch (type) {
    'snapshot' => decoded['prices'],
    'price_update' => decoded['updates'],
    _ => throw FormatException('Unsupported price stream message: $type'),
  };
  if (rawUpdates is! List) {
    throw const FormatException('Price stream updates must be a list.');
  }

  return rawUpdates
      .map((rawUpdate) {
        if (rawUpdate is! Map) {
          throw const FormatException('Price stream update must be an object.');
        }
        final coinId = rawUpdate['coin_id'];
        final price = rawUpdate['price'];
        if (coinId is! String || coinId.isEmpty || price is! num) {
          throw const FormatException(
            'Price stream update has invalid fields.',
          );
        }
        final parsedPrice = price.toDouble();
        if (!parsedPrice.isFinite || parsedPrice <= 0) {
          throw const FormatException(
            'Price stream update has an invalid price.',
          );
        }
        return LivePriceUpdate(coinId: coinId, price: parsedPrice);
      })
      .toList(growable: false);
}

Coin withLivePrice(
  Coin coin,
  Map<String, double> prices, {
  required String currency,
}) {
  final price = prices[_priceKey(currency, coin.id)];
  return price == null ? coin : coin.copyWith(price: price);
}

String _priceKey(String currency, String coinId) => '$currency:$coinId';
