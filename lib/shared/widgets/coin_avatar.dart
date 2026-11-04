import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class CoinAvatar extends StatelessWidget {
  const CoinAvatar({
    required this.symbol,
    this.imageUrl,
    this.size = AppSizes.coinLogo,
    super.key,
  });
  final String symbol;
  final String? imageUrl;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        symbol.isEmpty ? '?' : symbol.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    return Hero(
      tag: 'coin-${imageUrl!}',
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        imageBuilder: (context, provider) => CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.transparent,
          backgroundImage: provider,
        ),
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
