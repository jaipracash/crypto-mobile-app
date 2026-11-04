import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../controllers/market_controller.dart';

class MarketFilterRow extends StatelessWidget {
  const MarketFilterRow({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final MarketFilter selected;
  final ValueChanged<MarketFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (MarketFilter.all, AppStrings.all),
      (MarketFilter.gainers, AppStrings.gainers),
      (MarketFilter.losers, AppStrings.losers),
      (MarketFilter.highVolume, AppStrings.highVolume),
      (MarketFilter.watchlisted, AppStrings.watchlisted),
    ];
    return SizedBox(
      height: AppSizes.chipHeight + AppSizes.sm,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          return ChoiceChip(
            label: Text(label),
            selected: selected == filter,
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}
