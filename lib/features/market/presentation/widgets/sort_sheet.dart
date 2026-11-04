import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';

class SortSheet extends StatelessWidget {
  const SortSheet({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  final String selected;
  final ValueChanged<String> onSelected;

  static const options = {
    AppStrings.marketCap: ('market_cap_desc', 'market_cap_asc'),
    AppStrings.price: ('price_desc', 'price_asc'),
    AppStrings.change24h: ('change_desc', 'change_asc'),
    AppStrings.volume: ('volume_desc', 'volume_asc'),
  };

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.sortCoins,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.md),
          ...options.entries.map((entry) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.key),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChoiceChip(
                    label: const Text(AppStrings.high),
                    selected: selected == entry.value.$1,
                    onSelected: (_) => onSelected(entry.value.$1),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  ChoiceChip(
                    label: const Text(AppStrings.low),
                    selected: selected == entry.value.$2,
                    onSelected: (_) => onSelected(entry.value.$2),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ),
  );
}
