import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/market_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

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
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.search)),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: ref.read(searchQueryProvider.notifier).set,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: AppStrings.searchCoins,
                  prefixIcon: const Icon(Icons.search),
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
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Expanded(
                child: query.trim().length < 2
                    ? const Center(child: Text(AppStrings.searchCoins))
                    : results.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => ErrorView(
                          message: error.toString(),
                          onRetry: () =>
                              ref.read(searchResultsProvider.notifier).retry(),
                        ),
                        data: (items) => items.isEmpty
                            ? const Center(child: Text(AppStrings.noCoinsFound))
                            : ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: AppSizes.hairline,
                                  color: Theme.of(context).dividerColor,
                                ),
                                itemBuilder: (context, index) {
                                  final coin = items[index];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CoinAvatar(
                                      symbol: coin.symbol,
                                      imageUrl: coin.image,
                                    ),
                                    title: Text(coin.name),
                                    subtitle: Text(coin.symbol.toUpperCase()),
                                    trailing: coin.rank == null
                                        ? null
                                        : Text('#${coin.rank}'),
                                    onTap: () {
                                      ref
                                          .read(searchQueryProvider.notifier)
                                          .set('');
                                      context.push('/coin/${coin.id}');
                                    },
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
