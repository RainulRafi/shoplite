import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/utils/text_format.dart';
import '../data/product.dart';
import '../data/product_repository.dart';
import 'product_detail_provider.dart';
import 'widgets/product_image.dart';
import 'widgets/stock_note.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../shell/shell_tabs.dart';
import '../../auth/presentation/require_login.dart';
import '../../wishlist/presentation/wishlist_provider.dart';
import '../../browsing/presentation/browsing_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => ProductDetailProvider(
        ctx.read<ProductRepository>(),
        product,
        onViewed: ctx.read<BrowsingProvider>().recordView,
      )..refresh(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<ProductDetailProvider>();
    final product = provider.product;

    final meta = [
      product.brand ?? '',
      prettyCategory(product.category),
    ].where((part) => part.isNotEmpty).join('  ·  ');

    final images = product.images.isNotEmpty
        ? product.images
        : (product.thumbnail.isNotEmpty ? [product.thumbnail] : <String>[]);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        actions: [_WishlistButton(product: product)],
        title: Text(
          'Details',
          style: TextStyle(
            color: c.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: provider.refreshing
              ? LinearProgressIndicator(
                  minHeight: 2,
                  color: c.accentFg,
                  backgroundColor: c.track,
                )
              : const SizedBox(height: 2),
        ),
      ),
      bottomNavigationBar: _AddToCartBar(product: product),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (provider.refreshError != null) ...[
            _RefreshNotice(
              error: provider.refreshError!,
              onRetry: provider.refresh,
            ),
            const SizedBox(height: 16),
          ],

          _Gallery(images: images, title: product.title),
          const SizedBox(height: 20),

          Text(
            product.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: c.ink,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meta, style: TextStyle(fontSize: 14, color: c.muted)),
          ],
          const SizedBox(height: 16),

          _PriceRow(product: product),
          if (product.rating > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Rated ${product.rating.toStringAsFixed(1)} out of 5',
              style: TextStyle(fontSize: 13, color: c.faint),
            ),
          ],
          StockNote(product: product, showInStock: true),

          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'ABOUT THIS PRODUCT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: c.faint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: TextStyle(fontSize: 15, height: 1.5, color: c.ink),
            ),
          ],

          _InfoRows(product: product),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  final List<String> images;
  final String title;

  const _Gallery({required this.images, required this.title});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final urls = widget.images.isEmpty ? const [''] : widget.images;
    final shown = _index < urls.length ? _index : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < 340 ? constraints.maxWidth : 340.0;

        return Column(
          children: [
            SizedBox(
              height: side,
              child: PageView.builder(
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => Center(
                  child: ProductImage(
                    url: urls[i],
                    label: '${widget.title}, photo ${i + 1} of ${urls.length}',
                    size: side,
                  ),
                ),
              ),
            ),
            if (urls.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                '${shown + 1} of ${urls.length}',
                style: TextStyle(fontSize: 13, color: c.faint),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Product product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Wrap(
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(
          formatPrice(
            product.hasDiscount ? product.discountedPrice : product.price,
          ),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
        ),
        if (product.hasDiscount) ...[
          Text(
            formatPrice(product.price),
            style: TextStyle(
              fontSize: 15,
              color: c.faint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '${product.discountPercentage.round()}% off',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.highlight,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRows extends StatelessWidget {
  final Product product;

  const _InfoRows({required this.product});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final rows = <(String, String)>[
      if (product.shippingInformation != null)
        ('Shipping', product.shippingInformation!),
      if (product.warrantyInformation != null)
        ('Warranty', product.warrantyInformation!),
      if (product.returnPolicy != null) ('Returns', product.returnPolicy!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Divider(height: 1, color: c.border),
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      row.$1,
                      style: TextStyle(fontSize: 14, color: c.muted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

class _RefreshNotice extends StatelessWidget {
  final ApiException error;
  final VoidCallback onRetry;

  const _RefreshNotice({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing the details we already have. ${error.message}',
              style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
            ),
          ),

          if (error.isRetryable)
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

class _AddToCartBar extends StatelessWidget {
  final Product product;

  const _AddToCartBar({required this.product});

  void _add(BuildContext context) {
    final cart = context.read<CartProvider>();
    final tabs = context.read<ShellTabs>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final result = cart.addProduct(product);
    messenger.clearSnackBars();

    switch (result) {
      case AddToCartResult.added:
      case AddToCartResult.increased:
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Added to your cart.'),
            action: SnackBarAction(
              label: 'View cart',

              onPressed: () {
                navigator.popUntil((route) => route.isFirst);
                tabs.go(ShellTab.cart);
              },
            ),
          ),
        );
      case AddToCartResult.limitReached:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('You already have all we have in stock.'),
          ),
        );
      case AddToCartResult.outOfStock:
        messenger.showSnackBar(
          const SnackBar(content: Text('This product is out of stock.')),
        );
      case AddToCartResult.notReady:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Your cart is still loading. Try again in a moment.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cart = context.watch<CartProvider>();
    final inCart = cart.quantityOf(product.id);

    final bool canAdd;
    final String label;
    if (!product.inStock) {
      canAdd = false;
      label = 'Out of stock';
    } else if (inCart >= product.stock) {
      canAdd = false;
      label = 'Maximum in your cart';
    } else {
      canAdd = cart.status == CartStatus.ready;
      label = inCart > 0 ? 'Add another ($inCart in cart)' : 'Add to cart';
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatPrice(
                    product.hasDiscount
                        ? product.discountedPrice
                        : product.price,
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                if (product.hasDiscount)
                  Text(
                    formatPrice(product.price),
                    style: TextStyle(
                      fontSize: 13,
                      color: c.faint,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: canAdd ? () => _add(context) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  final Product product;

  const _WishlistButton({required this.product});

  Future<void> _toggle(BuildContext context) async {
    final wishlist = context.read<WishlistProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final signedIn = await requireLogin(
      context,
      reason: 'Sign in to save items to your wishlist.',
    );
    if (!signedIn) return;
    final result = await wishlist.toggle(product);
    messenger.clearSnackBars();
    switch (result) {
      case WishlistResult.added:
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved to your wishlist.')),
        );
      case WishlistResult.removed:
        messenger.showSnackBar(
          const SnackBar(content: Text('Removed from your wishlist.')),
        );
      case WishlistResult.failed:
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not update your wishlist.')),
        );
      case WishlistResult.signInRequired:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final saved = context.select<WishlistProvider, bool>(
      (w) => w.contains(product.id),
    );

    return IconButton(
      onPressed: () => _toggle(context),
      tooltip: saved ? 'Remove from wishlist' : 'Save to wishlist',
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Icon(
        saved ? Icons.favorite : Icons.favorite_border,
        color: saved ? c.accentFg : c.ink,
      ),
    );
  }
}
