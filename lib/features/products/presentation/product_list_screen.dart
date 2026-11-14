import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import 'product_detail_screen.dart';
import 'product_list_provider.dart';
import 'widgets/product_skeleton_tile.dart';
import 'widgets/product_tile.dart';
import 'widgets/search_field.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      context.read<ProductListProvider>().loadMore();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProductListProvider>().search('');
  }

  String _summary(ProductListProvider p) {
    final noun = p.query.isEmpty
        ? (p.total == 1 ? 'product' : 'products')
        : (p.total == 1 ? 'result' : 'results');
    final base = 'Showing ${p.products.length} of ${p.total} $noun';
    return p.query.isEmpty ? base : '$base for "${p.query}"';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Products',
          style: TextStyle(
            color: c.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SearchField(
              controller: _searchController,
              onChanged: (text) =>
                  context.read<ProductListProvider>().onQueryChanged(text),
              onSubmitted: (text) =>
                  context.read<ProductListProvider>().search(text),
              onClear: _clearSearch,
            ),
          ),
          Expanded(
            child: Consumer<ProductListProvider>(
              builder: (context, provider, child) {
                switch (provider.status) {
                  case LoadStatus.loading:
                    return const _SkeletonList();

                  case LoadStatus.error:
                    return _ErrorView(
                      error: provider.error!,
                      onRetry: provider.load,
                    );

                  case LoadStatus.success:
                    if (provider.products.isEmpty) {
                      if (provider.query.isNotEmpty) {
                        return _Message(
                          title: 'No results for "${provider.query}"',
                          body: 'Check the spelling or try a shorter word.',
                          action: TextButton(
                            onPressed: _clearSearch,
                            style: TextButton.styleFrom(
                              foregroundColor: c.accentFg,
                              minimumSize: const Size(120, 48),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            child: const Text('Clear search'),
                          ),
                        );
                      }
                      return const _Message(
                        title: 'No products yet',
                        body: 'Check back a little later.',
                      );
                    }

                    final showFooter =
                        provider.hasMore ||
                        provider.isLoadingMore ||
                        provider.loadMoreError != null;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Text(
                            _summary(provider),
                            style: TextStyle(fontSize: 13, color: c.faint),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            color: c.accentFg,
                            backgroundColor: c.surface,
                            onRefresh: () async {
                              final failure = await provider.refresh();
                              if (failure != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(failure.message)),
                                );
                              }
                            },
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),

                              itemCount:
                                  provider.products.length +
                                  (showFooter ? 1 : 0),
                              separatorBuilder: (_, _) =>
                                  Divider(height: 1, color: c.border),
                              itemBuilder: (context, index) {
                                if (index == provider.products.length) {
                                  return _ListFooter(provider: provider);
                                }
                                final product = provider.products[index];
                                return ProductTile(
                                  product: product,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailScreen(product: product),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final ProductListProvider provider;

  const _ListFooter({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final error = provider.loadMoreError;

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              'Could not load more products. ${error.message}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
            ),
            if (error.isRetryable)
              TextButton(
                onPressed: provider.retryLoadMore,
                style: TextButton.styleFrom(
                  foregroundColor: c.accentFg,
                  minimumSize: const Size(120, 48),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Try again'),
              ),
          ],
        ),
      );
    }

    if (provider.isLoadingMore) {
      return Semantics(
        label: 'Loading more products',
        child: const ProductSkeletonTile(),
      );
    }

    return const SizedBox(height: 24);
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      label: 'Loading products',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        itemCount: 8,
        separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
        itemBuilder: (_, _) => const ProductSkeletonTile(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ApiException error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return _Message(
      title: 'Could not load products',
      body: error.message,
      titleColor: c.danger,
      action: error.isRetryable
          ? FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Try again'),
            )
          : null,
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String body;
  final Color? titleColor;
  final Widget? action;

  const _Message({
    required this.title,
    required this.body,
    this.titleColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor ?? c.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
