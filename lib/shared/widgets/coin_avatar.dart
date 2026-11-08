import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_sizes.dart';

class CoinAvatar extends StatelessWidget {
  const CoinAvatar({
    required this.symbol,
    this.imageUrl,
    this.size,
    this.enableHero = true,
    super.key,
  });
  final String symbol;
  final String? imageUrl;
  final double? size;
  final bool enableHero;
  @override
  Widget build(BuildContext context) {
    final size = this.size ?? AppSizes.coinLogo.w;
    final fallback = CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        symbol.isEmpty ? '?' : symbol.characters.first.toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    final image = CachedNetworkImage(
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
    );
    if (!enableHero) return image;
    return Hero(tag: 'coin-${imageUrl!}', child: image);
  }
}
