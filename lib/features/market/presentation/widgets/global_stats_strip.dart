import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/market_models.dart';
import '../controllers/market_controller.dart';
import 'market_sheets.dart';

class GlobalStatsStrip extends ConsumerWidget {
  const GlobalStatsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(globalStatsControllerProvider);
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    final snapshot = stats.asData?.value;
    final cap = stats.isLoading
        ? const _MetricSkeleton()
        : _MetricCard(
            label: AppStrings.totalMarketCap,
            value: snapshot == null
                ? AppStrings.unavailableShort
                : Formatters.compact(
                    snapshot.totalMarketCap,
                    currencyCode: currency,
                  ),
            change: snapshot?.marketCapChange24hPct,
          );
    final volume = stats.isLoading
        ? const _MetricSkeleton()
        : _MetricCard(
            label: AppStrings.volume24h,
            value: snapshot == null
                ? AppStrings.unavailableShort
                : Formatters.compact(
                    snapshot.totalVolume24h,
                    currencyCode: currency,
                  ),
          );
    return Row(
      children: [
        Expanded(
          child: _OverviewTap(snapshot: snapshot, child: cap),
        ),
        SizedBox(width: AppSizes.sm.w),
        Expanded(
          child: _OverviewTap(snapshot: snapshot, child: volume),
        ),
      ],
    );
  }
}

class _OverviewTap extends StatelessWidget {
  const _OverviewTap({required this.snapshot, required this.child});
  final MarketSnapshot? snapshot;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
    onTap: () =>
        showMarketSheet(context, MarketOverviewSheet(snapshot: snapshot)),
    child: child,
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, this.change});
  final String label;
  final String value;
  final double? change;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      minHeight: (AppSizes.marketCardHeight - AppSizes.sm).h,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.md.w,
      vertical: AppSizes.sm.w,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: AppSizes.xs.w),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (change != null) ChangePill(change: change, compact: true),
          ],
        ),
      ],
    ),
  );
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      minHeight: (AppSizes.marketCardHeight - AppSizes.sm).h,
    ),
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.md.w,
      vertical: AppSizes.sm.w,
    ),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShimmerBox(width: 84, height: 12),
        SizedBox(height: AppSizes.sm.w),
        ShimmerBox(width: 120, height: 18),
      ],
    ),
  );
}
