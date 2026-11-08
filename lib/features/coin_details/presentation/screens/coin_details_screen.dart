import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/simulated_price_banner.dart';
import '../../../market/domain/coin.dart';
import '../../../market/presentation/controllers/live_price_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../../domain/coin_details.dart';
import '../controllers/coin_details_controller.dart';
import '../widgets/historical_data_card.dart';
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
  PriceChartSeries _series = PriceChartSeries.price;
  PriceChartStyle _chartStyle = PriceChartStyle.line;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                      SizedBox(width: AppSizes.sm.w),
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
              labelPadding: EdgeInsets.symmetric(horizontal: AppSizes.lg.w),
              tabs: const [
                Tab(text: AppStrings.overview),
                Tab(text: AppStrings.info),
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
                  width: AppSizes.iconMedium.w,
                  height: AppSizes.iconMedium.w,
                  colorFilter: const ColorFilter.mode(
                    AppColors.lightTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: AppStrings.notifications,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.noNotifications)),
                ),
                icon: SvgPicture.asset(
                  'assets/notification-6-svgrepo-com.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.lightTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      watched
                          ? AppColors.watchlistStar
                          : AppColors.lightTextSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          body: AsyncValueView(
            value: details,
            onRetry: () =>
                ref.invalidate(coinDetailsControllerProvider(widget.coinId)),
            loading: _detailsLoading(),
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
      physics: const PageScrollPhysics(),
      dragStartBehavior: DragStartBehavior.start,
      children: [
        _buildOverview(
          context,
          data,
          coinWithCurrentPrice,
          chartForSelectedRange,
          chartData,
          currency,
        ),
        _buildInfo(context, data, coinWithCurrentPrice, currency),
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
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding.w,
        AppSizes.sm.w,
        AppSizes.screenPadding.w,
        AppSizes.xxl.w,
      ),
      children: [
        SizedBox(height: AppSizes.md.w),
        Row(
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
              SizedBox(width: AppSizes.sm.w),
              _RankBadge(rank: coin.rank!),
            ],
          ],
        ),
        SizedBox(height: AppSizes.xs.w),
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSizes.sm.w,
          runSpacing: AppSizes.xs.w,
          children: [
            Text(
              _series == PriceChartSeries.price
                  ? Formatters.currency(displayedPrice, currency)
                  : Formatters.compact(displayedPrice, currencyCode: currency),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: color,
                fontSize: 30,
                fontWeight: FontWeight.w800,
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
        if (displayedDate != null) ...[
          SizedBox(height: AppSizes.xs.w),
          Text(
            Formatters.dateTime(displayedDate),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        SizedBox(height: AppSizes.md.w),
        _chartToolbar(context, chartData),
        if (chartData != null &&
            chartData.candles.isEmpty &&
            _series == PriceChartSeries.price) ...[
          SizedBox(height: AppSizes.xs.w),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.candleChartUnavailable,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ],
        SizedBox(height: AppSizes.md.w),
        if (ref.watch(liveCoinPricesProvider).isNotEmpty) ...[
          const SimulatedPriceBanner(horizontalInset: false),
          SizedBox(height: AppSizes.sm.w),
        ],
        AsyncValueView(
          value: chartForSelectedRange,
          onRetry: () =>
              ref.invalidate(coinChartProvider((widget.coinId, _days))),
          loading: ShimmerBox(
            height: AppSizes.chartHeight.h,
            radius: AppSizes.radiusSm.r,
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
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.md.w,
            vertical: AppSizes.sm.w,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm.r),
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
        SizedBox(height: AppSizes.xl.w),
        Text(
          AppStrings.marketStatistics,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSizes.sm.w),
        StatsGrid(details: data, currency: currency),
      ],
    );
  }

  Widget _buildInfo(
    BuildContext context,
    CoinDetails data,
    Coin coin,
    String currency,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSizes.screenPadding.w,
        AppSizes.lg.w,
        AppSizes.screenPadding.w,
        AppSizes.xxl.w,
      ),
      children: [
        Text(
          AppStrings.info,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: AppSizes.md.w),
        StatsGrid(details: data, currency: currency),
        SizedBox(height: AppSizes.xl.w),
        HistoricalDataCard(details: data, currency: currency),
        SizedBox(height: AppSizes.xl.w),
        Text(
          '${AppStrings.aboutCoin} ${coin.name}',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: AppSizes.sm.w),
        Text(
          data.description.isEmpty
              ? AppStrings.descriptionUnavailable
              : data.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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
        borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
      ),
      child: Row(
        children: timeframes.map((entry) {
          final selected = _days == entry.$1 && _rangeHours == entry.$2;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: selected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm.r),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm.r),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
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
      SizedBox(width: AppSizes.sm.w),
      SizedBox(
        width: 38,
        height: 38,
        child: IconButton(
          tooltip: _chartStyle == PriceChartStyle.candles
              ? AppStrings.lineChart
              : AppStrings.candleChart,
          onPressed:
              chart?.candles.isNotEmpty == true &&
                  _series == PriceChartSeries.price
              ? () => setState(() {
                  _chartStyle = _chartStyle == PriceChartStyle.candles
                      ? PriceChartStyle.line
                      : PriceChartStyle.candles;
                  _hoveredPoint = null;
                })
              : null,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: _chartStyle == PriceChartStyle.candles
                ? AppColors.brand
                : AppColors.lightTextPrimary,
            backgroundColor: _chartStyle == PriceChartStyle.candles
                ? AppColors.brand.withValues(alpha: 0.12)
                : const Color(0xFFF0F3F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm.r),
            ),
          ),
          icon: _chartStyle == PriceChartStyle.candles
              ? Icon(Icons.show_chart_rounded, size: AppSizes.iconMedium.w)
              : Icon(
                  Icons.candlestick_chart_rounded,
                  size: AppSizes.iconMedium.w,
                ),
        ),
      ),
      SizedBox(width: AppSizes.xs.w),
      SizedBox(
        width: 38,
        height: 38,
        child: IconButton(
          tooltip: AppStrings.filter,
          onPressed: _showChartOptions,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            foregroundColor: AppColors.lightTextPrimary,
            backgroundColor: const Color(0xFFF0F3F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusSm.r),
            ),
          ),
          icon: SvgPicture.asset(
            'assets/filter-svgrepo-com.svg',
            width: AppSizes.iconMedium.w,
            height: AppSizes.iconMedium.w,
            colorFilter: const ColorFilter.mode(
              AppColors.lightTextPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    ],
  );

  Future<void> _showChartOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(top: AppSizes.xxl.w),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusLg.r),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.lg.w,
              AppSizes.md.w,
              AppSizes.lg.w,
              AppSizes.xl.w,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.sheetHandleWidth.w,
                    height: AppSizes.sheetHandleHeight.h,
                    decoration: BoxDecoration(
                      color: AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(
                        AppSizes.radiusPill.r,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.lg.w),
                Text(
                  AppStrings.filter,
                  style: Theme.of(sheetContext).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: AppSizes.md.w),
                Text(
                  AppStrings.chartSeries,
                  style: Theme.of(sheetContext).textTheme.labelLarge?.copyWith(
                    color: AppColors.lightTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSizes.xs.w),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsLoading() => ListView(
    padding: EdgeInsets.fromLTRB(
      AppSizes.screenPadding.w,
      AppSizes.lg.w,
      AppSizes.screenPadding.w,
      AppSizes.xxl.w,
    ),
    children: [
      const ShimmerBox(width: 132, height: 16),
      SizedBox(height: AppSizes.md.w),
      const ShimmerBox(width: 196, height: 34),
      SizedBox(height: AppSizes.lg.w),
      Row(
        children: [
          ShimmerBox(width: 64, height: 32, radius: AppSizes.radiusSm.r),
          SizedBox(width: AppSizes.sm.w),
          ShimmerBox(width: 64, height: 32, radius: AppSizes.radiusSm.r),
          SizedBox(width: AppSizes.sm.w),
          ShimmerBox(width: 64, height: 32, radius: AppSizes.radiusSm.r),
          SizedBox(width: AppSizes.sm.w),
          ShimmerBox(width: 64, height: 32, radius: AppSizes.radiusSm.r),
        ],
      ),
      SizedBox(height: AppSizes.md.w),
      ShimmerBox(height: AppSizes.chartHeight.h, radius: AppSizes.radiusSm.r),
      SizedBox(height: AppSizes.md.w),
      ShimmerBox(height: 52, radius: AppSizes.radiusSm.r),
      SizedBox(height: AppSizes.xl.w),
      ShimmerBox(height: 168, radius: AppSizes.radiusSm.r),
    ],
  );
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

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.sm.w, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F3F6),
      borderRadius: BorderRadius.circular(AppSizes.radiusPill.r),
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
