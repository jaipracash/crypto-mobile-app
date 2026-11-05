import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/coin.dart';
import '../../domain/market_models.dart';
import '../controllers/market_controller.dart';
import '../widgets/coin_row.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.animateFromHome = false, super.key});

  static const homeSearchHeroTag = 'home-search-field';

  final bool animateFromHome;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _tabs = [
    HomeTab.all,
    HomeTab.trending,
    HomeTab.gainers,
    HomeTab.losers,
  ];

  late final TextEditingController _controller;
  HomeTab _selectedTab = HomeTab.all;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final listState = ref.watch(coinListControllerProvider);
    final trendingState = ref.watch(trendingControllerProvider);
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    final marketCoins = ref.watch(visibleCoinsProvider(_selectedTab));
    final AsyncValue<List<Coin>> marketState = _selectedTab == HomeTab.trending
        ? trendingState.whenData((data) => data.items)
        : listState.whenData((data) => data.items);
    final searchField = _searchField(query);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Column(
            children: [
              widget.animateFromHome
                  ? Hero(
                      tag: SearchScreen.homeSearchHeroTag,
                      child: Material(
                        color: Colors.transparent,
                        child: searchField,
                      ),
                    )
                  : searchField,
              const SizedBox(height: AppSizes.md),
              _tabStrip(),
              const SizedBox(height: AppSizes.sm),
              Expanded(
                child: query.trim().isNotEmpty
                    ? _searchResults(query, results)
                    : _marketResults(marketState, marketCoins, currency),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(String query) => TextField(
    controller: _controller,
    autofocus: !widget.animateFromHome,
    onChanged: ref.read(searchQueryProvider.notifier).set,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: AppStrings.searchCoins,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: SvgPicture.asset(
          'assets/search-alt-2-svgrepo-com.svg',
          width: AppSizes.iconMedium,
          height: AppSizes.iconMedium,
          colorFilter: ColorFilter.mode(
            Theme.of(context).colorScheme.onSurfaceVariant,
            BlendMode.srcIn,
          ),
        ),
      ),
      suffixIcon: query.isEmpty
          ? null
          : IconButton(
              tooltip: AppStrings.clearSearch,
              onPressed: () {
                _controller.clear();
                ref.read(searchQueryProvider.notifier).set('');
              },
              icon: const Icon(Icons.close),
            ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      isDense: true,
    ),
  );

  Widget _tabStrip() => SizedBox(
    height: AppSizes.homeTabHeight,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: _tabs.map((tab) {
        final selected = tab == _selectedTab;
        return InkWell(
          onTap: () => setState(() => _selectedTab = tab),
          child: SizedBox(
            width: switch (tab) {
              HomeTab.all => 64,
              HomeTab.trending => 88,
              HomeTab.gainers => 116,
              HomeTab.losers => 74,
              HomeTab.overview => 0,
            },
            height: AppSizes.homeTabHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Center(
                  child: Text(
                    _tabLabel(tab),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: AppSizes.tabIndicatorWidth,
                    height: AppSizes.homeTabUnderlineHeight,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _marketResults(
    AsyncValue<List<Coin>> state,
    List<Coin> coins,
    String currency,
  ) => state.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, _) => ErrorView(
      message: error.toString(),
      onRetry: _selectedTab == HomeTab.trending
          ? () => ref.read(trendingControllerProvider.notifier).refresh()
          : () => ref.read(coinListControllerProvider.notifier).refresh(),
    ),
    data: (_) => coins.isEmpty
        ? const Center(child: Text(AppStrings.noCoinsFound))
        : ListView.separated(
            padding: const EdgeInsets.only(bottom: AppSizes.lg),
            itemCount: coins.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
            itemBuilder: (context, index) =>
                _MarketSearchCard(coin: coins[index], currency: currency),
          ),
  );

  Widget _searchResults(String query, AsyncValue<List<SearchCoin>> results) {
    if (query.trim().length < 2) {
      return const Center(child: Text(AppStrings.searchCoins));
    }
    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.read(searchResultsProvider.notifier).retry(),
      ),
      data: (items) => items.isEmpty
          ? const Center(child: Text(AppStrings.noCoinsFound))
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: AppSizes.lg),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
              itemBuilder: (context, index) =>
                  _SearchResultCard(coin: items[index]),
            ),
    );
  }

  String _tabLabel(HomeTab tab) => switch (tab) {
    HomeTab.all => AppStrings.allCoins,
    HomeTab.trending => AppStrings.trending,
    HomeTab.gainers => AppStrings.topGainers,
    HomeTab.losers => AppStrings.topLosers,
    HomeTab.overview => AppStrings.overview,
  };
}

class _MarketSearchCard extends StatelessWidget {
  const _MarketSearchCard({required this.coin, required this.currency});

  final Coin coin;
  final String currency;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: CoinRow(
      coin: coin,
      currency: currency,
      period: ChangePeriod.day,
      onTap: () => context.push('/coin/${coin.id}'),
    ),
  );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.coin});

  final SearchCoin coin;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: CoinAvatar(symbol: coin.symbol, imageUrl: coin.image),
      title: Text(coin.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(coin.symbol.toUpperCase()),
      trailing: coin.rank == null ? null : Text('#${coin.rank}'),
      onTap: () => context.push('/coin/${coin.id}'),
    ),
  );
}
