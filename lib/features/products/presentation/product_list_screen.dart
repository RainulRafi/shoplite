import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_message.dart';
import '../../browsing/presentation/browsing_provider.dart';
import '../../home/presentation/home_provider.dart';
import '../../shell/shell_tabs.dart';
import '../domain/product_query.dart';
import 'product_detail_screen.dart';
import 'product_list_provider.dart';
import 'widgets/filter_sheet.dart';
import 'widgets/product_skeleton_tile.dart';
import 'widgets/product_tile.dart';
import 'widgets/search_field.dart';
import 'widgets/sort_sheet.dart';

// ============================================
// Shop Tab। StatefulWidget, কারণ মনে রাখতে হয়: Search ঘরের লেখা আর ফোকাস, স্ক্রল কতদূর, আর
// Provider ও Tab-বদলের খবর শুনতে হয়। সবই dispose()-এ বন্ধ করা জরুরি
// ============================================
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late final ProductListProvider _list;
  late final ShellTabs _tabs;

  int _handledSyncToken = 0;
  int _handledFocusRequest = 0;
  ProductQuery _lastQuery = const ProductQuery();

  @override
  void initState() {
    super.initState();
    _list = context.read<ProductListProvider>();
    _tabs = context.read<ShellTabs>();

    _handledSyncToken = _list.searchSyncToken;
    _handledFocusRequest = _tabs.searchFocusRequest;
    _lastQuery = _list.query;
    _searchController.text = _list.query.search;

    _scrollController.addListener(_onScroll);
    // লেখা আর ফোকাস বদলালে ইতিহাস-তালিকা দেখানো বা লুকানো ঠিক করতে আবার আঁকি
    _searchController.addListener(_rebuild);
    _searchFocus.addListener(_rebuild);
    _list.addListener(_onListChanged);
    _tabs.addListener(_onTabsChanged);
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabsChanged);
    _list.removeListener(_onListChanged);
    _searchFocus.removeListener(_rebuild);
    _searchController.removeListener(_rebuild);
    _scrollController.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onListChanged() {
    // বাইরের বদলে (Home থেকে আগে-সাজানো Shop) Search বাক্সের লেখা মিলিয়ে নিই।
    // ব্যবহারকারী টাইপ করার সময় token বাড়ে না, তাই তার লেখা কখনো মুছে যায় না
    if (_list.searchSyncToken != _handledSyncToken) {
      _handledSyncToken = _list.searchSyncToken;
      final text = _list.query.search;
      if (_searchController.text.trim() != text) _searchController.text = text;
    }

    // নতুন খোঁজা বা সাজানো হলে তালিকা আবার উপর থেকে দেখাই
    if (_list.query != _lastQuery) {
      _lastQuery = _list.query;
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    }
  }

  void _onTabsChanged() {
    if (_tabs.searchFocusRequest == _handledFocusRequest) return;
    _handledFocusRequest = _tabs.searchFocusRequest;
    // Tab বদলের পরের Frame-এ: তখনই Shop Screen সত্যিই পর্দায় আসে, আগে ফোকাস চাইলে ধরে না
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  // শেষের ৪০০ পিক্সেলের কাছে পৌঁছালে আরও চাই। বাড়তি ডাকে Provider কিছু করে না
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _list.loadMore();
    }
  }

  // ---------------- খোঁজা ----------------

  void _submitSearch(String text) {
    _searchFocus.unfocus();
    _list.search(text);
    // ইতিহাসে রাখি শুধু Enter বা ইতিহাসে ট্যাপে, টাইপের মাঝপথে না
    context.read<BrowsingProvider>().recordSearch(text);
  }

  void _useHistory(String term) {
    _searchController.text = term;
    _submitSearch(term);
  }

  void _clearSearch() {
    _searchController.clear();
    _list.search('');
  }

  String _summary(ProductListProvider p) {
    final searching = p.query.search.isNotEmpty;
    final noun = searching
        ? (p.total == 1 ? 'result' : 'results')
        : (p.total == 1 ? 'product' : 'products');
    final base = 'Showing ${p.products.length} of ${p.total} $noun';
    return searching ? '$base for "${p.query.search}"' : base;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<ProductListProvider>();
    final browsing = context.watch<BrowsingProvider>();

    final showHistory =
        _searchFocus.hasFocus &&
        _searchController.text.isEmpty &&
        browsing.searches.isNotEmpty;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Shop',
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
              focusNode: _searchFocus,
              onChanged: _list.onQueryChanged,
              onSubmitted: _submitSearch,
              onClear: _clearSearch,
            ),
          ),
          Expanded(
            child: showHistory
                ? _HistoryPanel(
                    searches: browsing.searches,
                    onPick: _useHistory,
                    onRemove: browsing.removeSearch,
                    onClearAll: browsing.clearSearches,
                  )
                : _Results(
                    provider: provider,
                    scrollController: _scrollController,
                    summary: _summary(provider),
                    onClearSearch: _clearSearch,
                  ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  final ProductListProvider provider;
  final ScrollController scrollController;
  final String summary;
  final VoidCallback onClearSearch;

  const _Results({
    required this.provider,
    required this.scrollController,
    required this.summary,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final query = provider.query;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: _ControlButton(
                  icon: Icons.swap_vert,
                  label: 'Sort: ${query.sort.title}',
                  onTap: () => showSortSheet(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ControlButton(
                  icon: Icons.tune,
                  label: query.filters.activeCount == 0
                      ? 'Filter'
                      : 'Filter (${query.filters.activeCount})',
                  onTap: () => showFilterSheet(context),
                ),
              ),
            ],
          ),
        ),
        if (query.category != null || query.filters.isActive)
          _ActiveFilters(provider: provider),
        Expanded(child: _body(context, c)),
      ],
    );
  }

  Widget _body(BuildContext context, AppColors c) {
    switch (provider.status) {
      case LoadStatus.loading:
        return const _SkeletonList();

      case LoadStatus.error:
        return _ErrorView(error: provider.error!, onRetry: provider.load);

      case LoadStatus.success:
        if (provider.products.isEmpty) return _emptyState(c);

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
                summary,
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
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.message)));
                  }
                },
                child: ListView.separated(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: provider.products.length + (showFooter ? 1 : 0),
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
                          builder: (_) => ProductDetailScreen(product: product),
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
  }

  Widget _emptyState(AppColors c) {
    final query = provider.query;

    ButtonStyle buttonStyle() => TextButton.styleFrom(
      foregroundColor: c.accentFg,
      minimumSize: const Size(140, 48),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    );

    if (query.category != null || query.filters.isActive) {
      return StateMessage(
        title: 'No products match',
        body: 'Try removing a filter or choosing another category.',
        action: TextButton(
          onPressed: provider.clearRefinements,
          style: buttonStyle(),
          child: const Text('Clear filters'),
        ),
      );
    }
    if (query.search.isNotEmpty) {
      return StateMessage(
        title: 'No results for "${query.search}"',
        body: 'Check the spelling or try a shorter word.',
        action: TextButton(
          onPressed: onClearSearch,
          style: buttonStyle(),
          child: const Text('Clear search'),
        ),
      );
    }
    return const StateMessage(
      title: 'No products yet',
      body: 'Check back a little later.',
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: c.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
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

class _ActiveFilters extends StatelessWidget {
  final ProductListProvider provider;

  const _ActiveFilters({required this.provider});

  String _priceLabel(ProductFilters f) {
    final min = f.minPrice;
    final max = f.maxPrice;
    if (min != null && max != null) return '${min.format()} to ${max.format()}';
    if (min != null) return 'From ${min.format()}';
    return 'Up to ${max!.format()}';
  }

  String _ratingLabel(double rating) {
    final text = rating == rating.roundToDouble()
        ? '${rating.round()}'
        : '$rating';
    return '$text stars and up';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final query = provider.query;
    final f = query.filters;
    final home = context.watch<HomeProvider>();

    final chips = <(String, VoidCallback)>[
      if (query.category != null)
        (home.categoryName(query.category!), () => provider.setCategory(null)),
      if (f.hasPrice)
        (
          _priceLabel(f),
          () => provider.setFilters(
            f.copyWith(clearMinPrice: true, clearMaxPrice: true),
          ),
        ),
      if (f.inStockOnly)
        ('In stock', () => provider.setFilters(f.copyWith(inStockOnly: false))),
      if (f.minRating > 0)
        (
          _ratingLabel(f.minRating),
          () => provider.setFilters(f.copyWith(minRating: 0)),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Wrap(
        spacing: 8,
        children: [
          for (final chip in chips)
            Semantics(
              button: true,
              label: 'Remove filter: ${chip.$1}',
              excludeSemantics: true,
              child: InkWell(
                onTap: chip.$2,
                borderRadius: BorderRadius.circular(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    widthFactor: 1,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.border),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            chip.$1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.close, size: 16, color: c.subtle),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          TextButton(
            onPressed: provider.clearRefinements,
            style: TextButton.styleFrom(
              foregroundColor: c.accentFg,
              minimumSize: const Size(64, 48),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  final List<String> searches;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const _HistoryPanel({
    required this.searches,
    required this.onPick,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'RECENT SEARCHES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: c.faint,
                ),
              ),
            ),
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                foregroundColor: c.accentFg,
                minimumSize: const Size(64, 48),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              child: const Text('Clear all'),
            ),
          ],
        ),
        for (final term in searches)
          InkWell(
            onTap: () => onPick(term),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  Icon(Icons.history, size: 20, color: c.subtle),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      term,
                      style: TextStyle(fontSize: 15, color: c.ink),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(term),
                    tooltip: 'Remove "$term"',
                    constraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                    icon: Icon(Icons.close, size: 18, color: c.subtle),
                  ),
                ],
              ),
            ),
          ),
      ],
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

    return StateMessage(
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
