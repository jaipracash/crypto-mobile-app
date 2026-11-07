import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/cupertino_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/simulated_price_banner.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/coin.dart';
import '../../domain/market_models.dart';
import '../controllers/market_controller.dart';
import '../controllers/live_price_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({this.animateFromHome = false, super.key});

  static const homeSearchHeroTag = 'home-search-field';

  final bool animateFromHome;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _tabs = [
    HomeTab.trending,
    HomeTab.all,
    HomeTab.gainers,
    HomeTab.losers,
  ];

  late final TextEditingController _controller;
  HomeTab _selectedTab = HomeTab.trending;

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
    final livePrices = ref.watch(liveCoinPricesProvider);
    final marketCoinsById = {
      for (final coin in [
        ...?listState.asData?.value.items,
        ...?trendingState.asData?.value.items,
      ])
        coin.id: withLivePrice(coin, livePrices, currency: currency),
    };
    final AsyncValue<List<Coin>> marketState = _selectedTab == HomeTab.trending
        ? trendingState.whenData((data) => data.items)
        : listState.whenData((data) => data.items);
    final searchField = _searchField(query);
    final theme = Theme.of(context);
    final searchTheme = theme.brightness == Brightness.light
        ? theme.copyWith(
            scaffoldBackgroundColor: Colors.white,
            colorScheme: theme.colorScheme.copyWith(surface: Colors.white),
          )
        : theme;

    return Theme(
      data: searchTheme,
      child: Scaffold(
        backgroundColor: searchTheme.scaffoldBackgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPadding,
                  AppSizes.md,
                  AppSizes.screenPadding,
                  0,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    widget.animateFromHome
                        ? Hero(
                            tag: SearchScreen.homeSearchHeroTag,
                            child: Material(
                              color: Colors.transparent,
                              child: searchField,
                            ),
                          )
                        : searchField,
                    const SizedBox(height: AppSizes.lg),
                    if (query.trim().isEmpty) ...[
                      Text(
                        'Popular Coins',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _tabStrip(),
                    ],
                    const SizedBox(height: AppSizes.sm),
                    if (livePrices.isNotEmpty)
                      const SimulatedPriceBanner(horizontalInset: false),
                  ]),
                ),
              ),
              if (query.trim().isNotEmpty)
                _searchResults(query, results, marketCoinsById, currency)
              else
                _marketResults(marketState, marketCoins, currency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField(String query) => TextField(
    controller: _controller,
    autofocus: false,
    onChanged: ref.read(searchQueryProvider.notifier).set,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: AppStrings.searchCoins,
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 48),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: AppSizes.md, right: AppSizes.xs),
        child: SvgPicture.asset(
          'assets/search2.svg',
          width: 14,
          height: 14,
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
    height: AppSizes.chipHeight + AppSizes.xs,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: _tabs.length,
      separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
      itemBuilder: (context, index) {
        final tab = _tabs[index];
        final selected = tab == _selectedTab;
        final scheme = Theme.of(context).colorScheme;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            onTap: () => setState(() => _selectedTab = tab),
            child: Container(
              height: AppSizes.chipHeight,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Text(
                _tabLabel(tab),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? Colors.white
                      : scheme.onSurfaceVariant.withValues(alpha: 0.85),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  Widget _marketResults(
    AsyncValue<List<Coin>> state,
    List<Coin> coins,
    String currency,
  ) => state.when(
    loading: () => const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CupertinoLoader()),
    ),
    error: (error, _) => SliverFillRemaining(
      hasScrollBody: false,
      child: ErrorView(
        error: error,
        onRetry: _selectedTab == HomeTab.trending
            ? () => ref.read(trendingControllerProvider.notifier).refresh()
            : () => ref.read(coinListControllerProvider.notifier).refresh(),
      ),
    ),
    data: (_) => coins.isEmpty
        ? const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(AppStrings.noCoinsFound)),
          )
        : SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              0,
              AppSizes.screenPadding,
              AppSizes.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: _MarketCoinTable(coins: coins, currency: currency),
            ),
          ),
  );

  Widget _searchResults(
    String query,
    AsyncValue<List<SearchCoin>> results,
    Map<String, Coin> marketCoinsById,
    String currency,
  ) {
    if (query.trim().length < 2) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text(AppStrings.searchCoins)),
      );
    }
    return results.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CupertinoLoader()),
      ),
      error: (error, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          error: error,
          onRetry: () => ref.read(searchResultsProvider.notifier).retry(),
        ),
      ),
      data: (items) => items.isEmpty
          ? const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(AppStrings.noCoinsFound)),
            )
          : SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                0,
                AppSizes.screenPadding,
                AppSizes.lg,
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.sm),
                itemBuilder: (context, index) {
                  final coin = items[index];
                  return _SearchResultCard(
                    coin: coin,
                    marketData: marketCoinsById[coin.id],
                    currency: currency,
                  );
                },
              ),
            ),
    );
  }

  String _tabLabel(HomeTab tab) => switch (tab) {
    HomeTab.all => AppStrings.all,
    HomeTab.trending => AppStrings.trending,
    HomeTab.gainers => AppStrings.gainers,
    HomeTab.losers => AppStrings.losers,
    HomeTab.overview => AppStrings.overview,
  };
}

class _MarketCoinTable extends StatelessWidget {
  const _MarketCoinTable({required this.coins, required this.currency});

  final List<Coin> coins;
  final String currency;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final coin in coins)
        _MarketSearchRow(coin: coin, currency: currency),
    ],
  );
}

class _MarketSearchRow extends StatelessWidget {
  const _MarketSearchRow({required this.coin, required this.currency});

  final Coin coin;
  final String currency;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/coin/${coin.id}'),
    child: SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        child: Row(
          children: [
            CoinAvatar(symbol: coin.symbol, imageUrl: coin.image),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    coin.symbol.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(coin.price, currency),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  ChangePill(
                    change: coin.change24hPct,
                    compact: true,
                    showBackground: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.coin,
    required this.marketData,
    required this.currency,
  });

  final SearchCoin coin;
  final Coin? marketData;
  final String currency;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/coin/${coin.id}'),
    child: SizedBox(
      height: 76,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        child: Row(
          children: [
            CoinAvatar(symbol: coin.symbol, imageUrl: coin.image),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    coin.symbol.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(marketData?.price, currency),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  ChangePill(
                    change: marketData?.change24hPct,
                    compact: true,
                    showBackground: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
