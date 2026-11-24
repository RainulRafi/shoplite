import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../browsing/domain/viewed_product.dart';
import '../../browsing/presentation/browsing_provider.dart';
import '../../cart/domain/coupon.dart';
import '../../cart/domain/pricing_rules.dart';
import '../../products/data/product.dart';
import '../../products/data/product_category.dart';
import '../../products/data/product_money.dart';
import '../../products/domain/product_query.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/product_list_provider.dart';
import '../../profile/presentation/profile_provider.dart';
import '../../shell/shell_tabs.dart';
import 'categories_screen.dart';
import 'home_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(BuildContext context) async {
    final failure = await context.read<HomeProvider>().refresh();
    if (failure != null && context.mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  void _openShop(BuildContext context, ProductQuery preset) {
    context.read<ProductListProvider>().applyPreset(preset);
    context.read<ShellTabs>().go(ShellTab.shop);
  }

  void _openProduct(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final home = context.watch<HomeProvider>();
    final browsing = context.watch<BrowsingProvider>();
    final firstName = context.select<ProfileProvider, String?>(
      (p) => p.effective?.firstName,
    );

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ShopLite',
              style: TextStyle(
                color: c.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (firstName != null && firstName.isNotEmpty)
              Text(
                'Hello, $firstName',
                style: TextStyle(color: c.muted, fontSize: 13),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: c.accentFg,
        backgroundColor: c.surface,
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Semantics(
                button: true,
                label: 'Search products',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => context.read<ShellTabs>().openShopWithSearch(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: c.field,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: c.subtle),
                        const SizedBox(width: 10),
                        Text(
                          'Search products',
                          style: TextStyle(color: c.subtle, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _OfferRail(),
            const SizedBox(height: 28),

            _SectionHeader(
              title: 'Shop by category',
              actionLabel: 'See all',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _CategoryStrip(
              state: home.categories,
              onRetry: home.retryCategories,
              onPick: (slug) =>
                  _openShop(context, ProductQuery(category: slug)),
            ),
            const SizedBox(height: 28),

            // ---- Deals ----
            _SectionHeader(
              title: 'Deals',
              actionLabel: 'See all',
              onAction: () => _openShop(
                context,
                const ProductQuery(sort: ProductSort.biggestDiscount),
              ),
            ),
            const SizedBox(height: 12),
            _ProductSection(
              state: home.deals,
              onRetry: home.retryDeals,
              onOpen: (p) => _openProduct(context, p),
              showDiscountBadge: true,
            ),
            const SizedBox(height: 28),

            // ---- Top rated ----
            _SectionHeader(
              title: 'Top rated',
              actionLabel: 'See all',
              onAction: () => _openShop(
                context,
                const ProductQuery(sort: ProductSort.topRated),
              ),
            ),
            const SizedBox(height: 12),
            _ProductSection(
              state: home.topRated,
              onRetry: home.retryTopRated,
              onOpen: (p) => _openProduct(context, p),
            ),

            if (browsing.viewed.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Recently viewed',
                actionLabel: 'Clear',
                onAction: browsing.clearViewed,
              ),
              const SizedBox(height: 12),
              _ViewedRail(
                items: browsing.viewed.take(12).toList(),
                onOpen: (p) => _openProduct(context, p),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: c.accentFg,
              minimumSize: const Size(64, 48),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _OfferRail extends StatelessWidget {
  const _OfferRail();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final coupon = Coupon.all.first; // SAVE10

    Widget card({
      required String title,
      required String body,
      VoidCallback? onTap,
    }) {
      return SizedBox(
        width: 250,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.accentFg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card(
              title: 'Free shipping',
              body:
                  'On standard delivery for orders over ${PricingRules.freeShippingFrom.format()}.',
            ),
            const SizedBox(width: 12),
            card(
              title: coupon.code,
              body: '${coupon.description}. Tap to copy the code.',
              onTap: () {
                Clipboard.setData(ClipboardData(text: coupon.code));
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    SnackBar(content: Text('${coupon.code} copied.')),
                  );
              },
            ),
            const SizedBox(width: 12),
            card(
              title: 'Pay on delivery',
              body: 'Cash on delivery is available on every order.',
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final SectionState<List<ProductCategory>> state;
  final VoidCallback onRetry;
  final ValueChanged<String> onPick;

  const _CategoryStrip({
    required this.state,
    required this.onRetry,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    switch (state.status) {
      case SectionStatus.loading:
        return SizedBox(
          height: 48,
          child: Semantics(
            label: 'Loading categories',
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, _) => Container(
                width: 96,
                decoration: BoxDecoration(
                  color: c.track,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        );

      case SectionStatus.error:
        return _InlineError(error: state.error!, onRetry: onRetry);

      case SectionStatus.ready:
        final list = state.data!.take(10).toList();
        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => InkWell(
              onTap: () => onPick(list[i].slug),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.border),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  list[i].name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _ProductSection extends StatelessWidget {
  final SectionState<List<Product>> state;
  final VoidCallback onRetry;
  final ValueChanged<Product> onOpen;
  final bool showDiscountBadge;

  const _ProductSection({
    required this.state,
    required this.onRetry,
    required this.onOpen,
    this.showDiscountBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = ProductCard.heightFor(context);

    switch (state.status) {
      case SectionStatus.loading:
        return SizedBox(
          height: height,
          child: Semantics(
            label: 'Loading products',
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => SizedBox(
                width: ProductCard.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: ProductCard.width,
                      height: ProductCard.width,
                      decoration: BoxDecoration(
                        color: c.track,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: c.track,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 70,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c.track,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case SectionStatus.error:
        return _InlineError(error: state.error!, onRetry: onRetry);

      case SectionStatus.ready:
        final products = state.data!;
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = products[i];
              return ProductCard(
                thumbnail: p.thumbnail,
                title: p.title,
                price: p.saleMoney,
                listPrice: p.hasDiscount ? p.listMoney : null,
                badge: showDiscountBadge && p.hasDiscount
                    ? '${p.discountPercentage.round()}% off'
                    : null,
                onTap: () => onOpen(p),
              );
            },
          ),
        );
    }
  }
}

class _ViewedRail extends StatelessWidget {
  final List<ViewedProduct> items;
  final ValueChanged<Product> onOpen;

  const _ViewedRail({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProductCard.heightFor(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final v = items[i];
          return ProductCard(
            thumbnail: v.thumbnail,
            title: v.title,
            price: v.unitPrice,
            listPrice: v.hasDiscount ? v.listPrice : null,
            onTap: () => onOpen(v.toPlaceholderProduct()),
          );
        },
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final dynamic error; // ApiException
  final VoidCallback onRetry;

  const _InlineError({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Could not load this. ${error.message}',
              style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
            ),
          ),
          if (error.isRetryable as bool)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: c.accentFg,
                minimumSize: const Size(64, 48),
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  static const double width = 156;

  final String thumbnail;
  final String title;
  final Money price;
  final Money? listPrice;
  final String? badge;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.price,
    this.listPrice,
    this.badge,
    required this.onTap,
  });

  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 1.6)
        .toDouble();
    return width + 76 * scale;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    thumbnail,
                    width: width,
                    height: width,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: width,
                      height: width,
                      color: c.track,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: c.subtle,
                      ),
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: c.accentFg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          color: c.surface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.ink,
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  child: Text(
                    price.format(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (listPrice != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      listPrice!.format(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
