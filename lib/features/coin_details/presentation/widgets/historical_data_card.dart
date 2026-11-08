import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/coin_details.dart';

class HistoricalDataCard extends StatelessWidget {
  const HistoricalDataCard({
    required this.details,
    required this.currency,
    super.key,
  });

  final CoinDetails details;
  final String currency;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSizes.lg.w),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.historicalData,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.lg.w),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HistoricalValue(
                label: AppStrings.high24h,
                value: Formatters.currency(details.high24h, currency),
              ),
            ),
            const SizedBox(width: AppSizes.md.w),
            Expanded(
              child: _HistoricalValue(
                label: AppStrings.low24h,
                value: Formatters.currency(details.low24h, currency),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xl.w),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HistoricalValue(
                label: AppStrings.allTimeHigh,
                value: Formatters.currency(details.ath, currency),
                change: details.athChangePct,
                date: details.athDate,
              ),
            ),
            const SizedBox(width: AppSizes.md.w),
            Expanded(
              child: _HistoricalValue(
                label: AppStrings.allTimeLow,
                value: Formatters.currency(details.atl, currency),
                change: details.atlChangePct,
                date: details.atlDate,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _HistoricalValue extends StatelessWidget {
  const _HistoricalValue({
    required this.label,
    required this.value,
    this.change,
    this.date,
  });

  final String label;
  final String value;
  final double? change;
  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final changeColor = (change ?? 0) >= 0
        ? AppColors.lightGain
        : AppColors.lightLoss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.lightTextSecondary),
        ),
        const SizedBox(height: AppSizes.xs.w),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSizes.xs.w,
          runSpacing: 0,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.lightTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (change != null) ...[
              Icon(
                change! >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: AppSizes.iconSmall.w,
                color: changeColor,
              ),
              Text(
                Formatters.percent(change),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: changeColor, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        if (date != null) ...[
          const SizedBox(height: 2),
          Text(
            _formatDate(date!),
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.lightTextSecondary),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final daysAgo = DateTime.now().difference(localDate).inDays;
    return '${DateFormat('MMMM dd, yyyy').format(localDate)} '
        '(${daysAgo < 0 ? 0 : daysAgo} days)';
  }
}
