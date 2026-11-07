import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/cupertino_loader.dart';
import '../../../../shared/widgets/data_source_banner.dart';
import '../../../../shared/widgets/simulated_price_banner.dart';
import '../../../market/domain/coin.dart';
import '../../../market/presentation/controllers/live_price_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../../domain/coin_details.dart';
import '../controllers/coin_details_controller.dart';
import '../widgets/price_chart.dart';
import '../widgets/stats_grid.dart';

class CoinDetailsScreen extends ConsumerStatefulWidget {
  const CoinDetailsScreen({required this.coinId, super.key});
  final String coinId;
  @override
  ConsumerState<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends ConsumerState<CoinDetailsScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _favoriteAnimationController;
  late final Animation<double> _favoriteScale;
  PricePoint? _hoveredPoint;
  int _days = 7;
  int _rangeHours = 7 * 24;
  bool _aboutExpanded = false;
  PriceChartSeries _series = PriceChartSeries.price;
  PriceChartStyle _chartStyle = PriceChartStyle.line;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoriteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _favoriteScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1, end: 1.28), weight: 28),
          TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.9), weight: 34),
          TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.06), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 18),
        ]).animate(
          CurvedAnimation(
            parent: _favoriteAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  @override
  void didUpdateWidget(covariant CoinDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coinId != widget.coinId) {
      _days = 7;
      _rangeHours = 7 * 24;
      _series = PriceChartSeries.price;
      _chartStyle = PriceChartStyle.line;
      _hoveredPoint = null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _favoriteAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(coinDetailsControllerProvider(widget.coinId));
    final chart = ref.watch(coinChartProvider((widget.coinId, _days)));
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    final livePrices = ref.watch(liveCoinPricesProvider);
    final detailsData = details.asData?.value;
    final liveDetailsCoin = detailsData == null
        ? null
        : withLivePrice(detailsData.coin, livePrices, currency: currency);
    final watched =
        ref
            .watch(watchlistControllerProvider)
            .asData
            ?.value
            .items
            .any((coin) => coin.id == widget.coinId) ??
        false;
    return Theme(
      data: AppTheme.light(),
      child: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: true,
            titleSpacing: 0,
            title: liveDetailsCoin == null
                ? const SizedBox.shrink()
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CoinAvatar(
                        symbol: liveDetailsCoin.symbol,
                        imageUrl: liveDetailsCoin.image,
                        size: 28,
                        enableHero: false,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Text(
                        liveDetailsCoin.symbol.toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              tabs: const [
                Tab(text: AppStrings.overview),
                Tab(text: AppStrings.info),
                Tab(text: AppStrings.news),
              ],
              labelColor: AppColors.brand,
              unselectedLabelColor: AppColors.lightTextSecondary,
              labelStyle: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.brand, width: 2),
                insets: EdgeInsets.symmetric(horizontal: 8),
              ),
              dividerColor: AppColors.lightBorder,
              dividerHeight: 0.5,
              indicatorWeight: 2,
            ),
            actions: [
              IconButton(
                tooltip: AppStrings.searchCoins,
                onPressed: () => context.push(Routes.search),
                icon: SvgPicture.asset(
                  'assets/search2.svg',
                  width: AppSizes.iconSmall,
                  height: AppSizes.iconSmall,
                  colorFilter: const ColorFilter.mode(
                    AppColors.lightTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: AppStrings.notifications,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.noNotifications)),
                ),
                icon: SvgPicture.asset(
                  'assets/notification-6-svgrepo-com.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    AppColors.lightTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: watched
                    ? AppStrings.removeFromWatchlist
                    : AppStrings.addToWatchlist,
                onPressed: detailsData == null
                    ? null
                    : () {
                        _favoriteAnimationController.forward(from: 0);
                        _toggle(liveDetailsCoin!);
                      },
                icon: ScaleTransition(
                  scale: _favoriteScale,
                  child: SvgPicture.asset(
                    watched ? 'assets/star-filled.svg' : 'assets/star.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      watched
                          ? AppColors.watchlistStar
                          : AppColors.lightTextSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          body: AsyncValueView(
            value: details,
            onRetry: () =>
                ref.invalidate(coinDetailsControllerProvider(widget.coinId)),
            builder: (data) => _buildDetails(context, data, chart, currency),
          ),
        ),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    CoinDetails data,
    AsyncValue<CoinChart> chart,
    String currency,
  ) {
    final loadedChart = chart.asData?.value;
    final chartData =
        loadedChart?.coinId == widget.coinId &&
            loadedChart?.days == _days &&
            loadedChart?.currency == currency
        ? loadedChart
        : null;
    final chartForSelectedRange = chart.hasError
        ? chart
        : chartData == null
        ? const AsyncLoading<CoinChart>()
        : chart;
    final coin = data.coin.copyWith(
      isWatchlisted:
          ref
              .watch(watchlistControllerProvider)
              .asData
              ?.value
              .items
              .any((item) => item.id == data.coin.id) ??
          data.coin.isWatchlisted,
    );
    final coinWithCurrentPrice = withLivePrice(
      coin,
      ref.watch(liveCoinPricesProvider),
      currency:
          ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd',
    );
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverview(
          context,
          data,
          coinWithCurrentPrice,
          chartForSelectedRange,
          chartData,
          currency,
        ),
        _buildInfo(
          context,
          data,
          coinWithCurrentPrice,
          chartData,
          chartForSelectedRange,
          currency,
        ),
        _buildNews(context),
      ],
    );
  }

  Widget _buildOverview(
    BuildContext context,
    CoinDetails data,
    Coin coin,
    AsyncValue<CoinChart> chartForSelectedRange,
    CoinChart? chartData,
    String currency,
  ) {
    final selectedPoints = _selectedPoints(chartData);
    final latestSelectedPoint = selectedPoints.isEmpty
        ? null
        : selectedPoints.last;
    final displayedPrice =
        _hoveredPoint?.price ?? coin.price ?? latestSelectedPoint?.price;
    final displayedDate = _hoveredPoint?.timestamp;
    final selectedChange = _selectedRangeChange(selectedPoints);
    final isPositive = (selectedChange ?? coin.change24hPct ?? 0) >= 0;
    final color = isPositive ? AppColors.lightGain : AppColors.lightLoss;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        AppSizes.xxl,
      ),
      children: [
        const SizedBox(height: AppSizes.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSizes.sm,
          runSpacing: AppSizes.xs,
          children: [
            Text(
              _series == PriceChartSeries.price
                  ? Formatters.currency(displayedPrice, currency)
                  : Formatters.compact(displayedPrice, currencyCode: currency),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
            ChangePill(
              change:
                  selectedChange ??
                  (_days == 1 && _rangeHours == 24 ? coin.change24hPct : null),
              showBackground: false,
            ),
            Text(
              '(${_timeframeLabel(_days)})',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                coin.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (coin.rank != null) ...[
              const SizedBox(width: AppSizes.sm),
              _RankBadge(rank: coin.rank!),
            ],
          ],
        ),
        if (displayedDate != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            Formatters.dateTime(displayedDate),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSizes.md),
        _chartToolbar(context, chartData),
        if (chartData != null &&
            chartData.candles.isEmpty &&
            _series == PriceChartSeries.price) ...[
          const SizedBox(height: AppSizes.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.candleChartUnavailable,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
        const SizedBox(height: AppSizes.md),
        DataSourceBanner(source: chartData?.dataSource ?? data.dataSource),
        if (ref.watch(liveCoinPricesProvider).isNotEmpty)
          const SimulatedPriceBanner(),
        AsyncValueView(
          value: chartForSelectedRange,
          onRetry: () =>
              ref.invalidate(coinChartProvider((widget.coinId, _days))),
          loading: const SizedBox(
            height: AppSizes.chartHeight,
            child: Center(child: CupertinoLoader()),
          ),
          isEmpty: (value) =>
              (_series == PriceChartSeries.price
                      ? value.prices
                      : value.marketCaps)
                  .isEmpty,
          emptyTitle: _series == PriceChartSeries.marketCap
              ? AppStrings.marketCapChartUnavailable
              : AppStrings.noChartData,
          builder: (value) => PriceChart(
            chart: value,
            currency: currency,
            series: _series,
            style: _chartStyle,
            rangeHours: _days == 1 ? _rangeHours : null,
            onTouch: (point) => setState(() => _hoveredPoint = point),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartMarker(
                label: AppStrings.low,
                value: _formatChartValue(_chartMin(selectedPoints), currency),
              ),
              _ChartMarker(
                label: AppStrings.change,
                value: Formatters.percent(selectedChange),
              ),
              _ChartMarker(
                label: AppStrings.high,
                value: _formatChartValue(_chartMax(selectedPoints), currency),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfo(
    BuildContext context,
    CoinDetails data,
    Coin coin,
    CoinChart? chart,
    AsyncValue<CoinChart> chartState,
    String currency,
  ) {
    final points = _selectedPoints(chart);
    final historicalPoints = points.reversed.take(12);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        AppSizes.xxl,
      ),
      children: [
        Text(
          AppStrings.info,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSizes.md),
        StatsGrid(details: data, currency: currency),
        const SizedBox(height: AppSizes.xl),
        Text(
          AppStrings.historicalData,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSizes.sm),
        if (chartState.isLoading && chart == null)
          const Padding(
            padding: EdgeInsets.all(AppSizes.lg),
            child: Center(child: CupertinoLoader()),
          )
        else if (chartState.hasError)
          Text(
            chartState.error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          )
        else if (historicalPoints.isEmpty)
          Text(
            AppStrings.noChartData,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          _HistoricalDataTable(
            points: historicalPoints.toList(growable: false),
            currency: currency,
            series: _series,
          ),
        const SizedBox(height: AppSizes.xl),
        Text(
          '${AppStrings.aboutCoin} ${coin.name}',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          data.description.isEmpty
              ? AppStrings.descriptionUnavailable
              : data.description,
          maxLines: _aboutExpanded ? null : 4,
          overflow: _aboutExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (data.description.length > 180)
          TextButton(
            onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded),
            child: Text(
              _aboutExpanded ? AppStrings.showLess : AppStrings.readMore,
            ),
          ),
        if (data.website != null || data.whitepaper != null) ...[
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            children: [
              if (data.website != null)
                _LinkButton(label: AppStrings.website, url: data.website!),
              if (data.whitepaper != null)
                _LinkButton(
                  label: AppStrings.whitepaper,
                  url: data.whitepaper!,
                ),
            ],
          ),
        ],
      ],
    );
  }

  double? _chartMin(List<PricePoint> points) {
    if (points.isEmpty) return null;
    return points.map((point) => point.price).reduce((a, b) => a < b ? a : b);
  }

  double? _chartMax(List<PricePoint> points) {
    if (points.isEmpty) return null;
    return points.map((point) => point.price).reduce((a, b) => a > b ? a : b);
  }

  String _formatChartValue(double? value, String currency) =>
      _series == PriceChartSeries.price
      ? Formatters.currency(value, currency)
      : Formatters.compact(value, currencyCode: currency);

  Widget _timeframes(BuildContext context) {
    const timeframes = [
      (1, 1, '1H'),
      (1, 24, '24H'),
      (7, 168, '7D'),
      (30, 720, '30D'),
      (90, 2160, '90D'),
      (365, 8760, '1Y'),
    ];
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F6),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: timeframes.map((entry) {
          final selected = _days == entry.$1 && _rangeHours == entry.$2;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  onTap: () {
                    if (selected) return;
                    setState(() {
                      _days = entry.$1;
                      _rangeHours = entry.$2;
                      _hoveredPoint = null;
                      _chartStyle = PriceChartStyle.line;
                    });
                  },
                  child: Center(
                    child: Text(
                      entry.$3,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        color: selected
                            ? AppColors.lightTextPrimary
                            : AppColors.lightTextSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _toggle(Coin coin) async {
    try {
      await ref.read(watchlistControllerProvider.notifier).toggle(coin);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Widget _buildNews(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.newspaper_outlined,
            size: 40,
            color: AppColors.lightTextSecondary,
          ),
          const SizedBox(height: AppSizes.md),
          Text(AppStrings.news, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSizes.xs),
          Text(
            AppStrings.newsUnavailable,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );

  List<PricePoint> _selectedPoints(CoinChart? chart) {
    if (chart == null) return const [];
    final points = _series == PriceChartSeries.price
        ? chart.prices
        : chart.marketCaps;
    final sorted = [...points]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (_days == 1 && _rangeHours < 24 && sorted.isNotEmpty) {
      final cutoff = sorted.last.timestamp.subtract(
        Duration(hours: _rangeHours),
      );
      sorted.removeWhere((point) => point.timestamp.isBefore(cutoff));
    }
    return sorted;
  }

  double? _selectedRangeChange(List<PricePoint> points) {
    if (points.length < 2 || points.first.price == 0) return null;
    return (points.last.price - points.first.price) / points.first.price * 100;
  }

  String _timeframeLabel(int days) {
    if (days == 1 && _rangeHours == 1) return '1H';
    return switch (days) {
      1 => '24H',
      7 => '7D',
      30 => '30D',
      90 => '90D',
      365 => '1Y',
      _ => '$days D',
    };
  }

  Widget _chartToolbar(BuildContext context, CoinChart? chart) => Row(
    children: [
      Expanded(child: _timeframes(context)),
      const SizedBox(width: AppSizes.sm),
      SizedBox(
        width: 38,
        height: 38,
        child: IconButton(
          tooltip: AppStrings.filter,
          onPressed: () => _showChartOptions(chart),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.lightTextPrimary,
            backgroundColor: const Color(0xFFF0F3F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
          ),
          icon: SvgPicture.asset(
            'assets/filter-svgrepo-com.svg',
            width: AppSizes.iconMedium,
            height: AppSizes.iconMedium,
            colorFilter: const ColorFilter.mode(
              AppColors.lightTextPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    ],
  );

  Future<void> _showChartOptions(CoinChart? chart) async {
    final canShowCandles = chart?.candles.isNotEmpty ?? false;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.only(top: AppSizes.xxl),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.sheetHandleWidth,
                    height: AppSizes.sheetHandleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                Text(
                  AppStrings.filter,
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  AppStrings.chartSeries,
                  style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                    color: AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<PriceChartSeries>(
                    segments: const [
                      ButtonSegment(
                        value: PriceChartSeries.price,
                        icon: Icon(Icons.attach_money_rounded),
                        label: Text(AppStrings.price),
                      ),
                      ButtonSegment(
                        value: PriceChartSeries.marketCap,
                        icon: Icon(Icons.bar_chart_rounded),
                        label: Text(AppStrings.marketCap),
                      ),
                    ],
                    selected: {_series},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => setState(() {
                      _series = selection.first;
                      if (_series == PriceChartSeries.marketCap) {
                        _chartStyle = PriceChartStyle.line;
                      }
                      _hoveredPoint = null;
                    }),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  AppStrings.chartType,
                  style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                    color: AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<PriceChartStyle>(
                    segments: [
                      const ButtonSegment(
                        value: PriceChartStyle.line,
                        icon: Icon(Icons.show_chart_rounded),
                        label: Text(AppStrings.lineChart),
                      ),
                      ButtonSegment(
                        value: PriceChartStyle.candles,
                        icon: const Icon(Icons.candlestick_chart_rounded),
                        label: const Text(AppStrings.candleChart),
                        enabled:
                            canShowCandles && _series == PriceChartSeries.price,
                      ),
                    ],
                    selected: {_chartStyle},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => setState(() {
                      _chartStyle = selection.first;
                      _hoveredPoint = null;
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartMarker extends StatelessWidget {
  const _ChartMarker({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppColors.lightTextSecondary),
      ),
      Text(
        value,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _HistoricalDataTable extends StatelessWidget {
  const _HistoricalDataTable({
    required this.points,
    required this.currency,
    required this.series,
  });

  final List<PricePoint> points;
  final String currency;
  final PriceChartSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E7EC)),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          for (var index = 0; index < points.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: Color(0xFFE9EDF2)),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    Formatters.dateTime(points[index].timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    series == PriceChartSeries.price
                        ? Formatters.currency(points[index].price, currency)
                        : Formatters.compact(
                            points[index].price,
                            currencyCode: currency,
                          ),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.sm,
      vertical: AppSizes.xs,
    ),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F3F6),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
    child: Text(
      '#$rank',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: AppColors.lightTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.url});
  final String label;
  final String url;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Text(label),
  );
}
