import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/state/data_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_message.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../products/data/product_repository.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../../products/presentation/widgets/product_skeleton_tile.dart';
import '../../shell/shell_tabs.dart';
import '../domain/wishlist_item.dart';
import 'wishlist_provider.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Set<int> _adding = {};

  Future<void> _addToCart(WishlistItem item) async {
    if (_adding.contains(item.productId)) return;

    final products = context.read<ProductRepository>();
    final cart = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _adding.add(item.productId));
    String message;
    try {
      final fresh = await products.fetchProduct(item.productId);
      message = switch (cart.addProduct(fresh)) {
        AddToCartResult.added ||
        AddToCartResult.increased => 'Added to your cart.',
        AddToCartResult.limitReached =>
          'You already have all we have in stock.',
        AddToCartResult.outOfStock => 'This product is out of stock.',
        AddToCartResult.notReady =>
          'Your cart is still loading. Try again in a moment.',
      };
    } on ApiException catch (e) {
      message = e.message;
    }

    if (mounted) setState(() => _adding.remove(item.productId));
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _remove(WishlistItem item) async {
    final wishlist = context.read<WishlistProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final removed = await wishlist.remove(item.productId);
    if (removed == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Removed from your wishlist.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => wishlist.restore(removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wishlist = context.watch<WishlistProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Wishlist',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (wishlist.status) {
        DataStatus.loading => Semantics(
          label: 'Loading your wishlist',
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: const [
              ProductSkeletonTile(),
              ProductSkeletonTile(),
              ProductSkeletonTile(),
            ],
          ),
        ),
        DataStatus.error => StateMessage(
          title: 'Could not load your wishlist',
          body: 'Something went wrong reading it from this phone.',
          titleColor: c.danger,
          action: FilledButton(
            onPressed: wishlist.retry,
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Try again'),
          ),
        ),
        DataStatus.ready =>
          wishlist.items.isEmpty
              ? StateMessage(
                  title: 'Nothing saved yet',
                  body: 'Tap the heart on a product to keep it here.',
                  action: FilledButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      context.read<ShellTabs>().go(ShellTab.shop);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      minimumSize: const Size(180, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    child: const Text('Browse products'),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  itemCount: wishlist.items.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: c.border),
                  itemBuilder: (context, index) {
                    final item = wishlist.items[index];
                    return _WishlistTile(
                      item: item,
                      adding: _adding.contains(item.productId),
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: item.toPlaceholderProduct(),
                          ),
                        ),
                      ),
                      onAddToCart: () => _addToCart(item),
                      onRemove: () => _remove(item),
                    );
                  },
                ),
      },
    );
  }
}

class _WishlistTile extends StatelessWidget {
  final WishlistItem item;
  final bool adding;
  final VoidCallback onOpen;
  final VoidCallback onAddToCart;
  final VoidCallback onRemove;

  const _WishlistTile({
    required this.item,
    required this.adding,
    required this.onOpen,
    required this.onAddToCart,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(url: item.thumbnail, label: item.title, size: 80),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: c.ink,
                    ),
                  ),
                  if (item.brand != null && item.brand!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.brand!,
                      style: TextStyle(fontSize: 13, color: c.muted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        item.unitPrice.format(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      if (item.hasDiscount)
                        Text(
                          item.listPrice.format(),
                          style: TextStyle(
                            fontSize: 13,
                            color: c.faint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: adding ? null : onAddToCart,
                        style: FilledButton.styleFrom(
                          backgroundColor: c.accent,
                          foregroundColor: c.onAccent,
                          minimumSize: const Size(120, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        child: Text(adding ? 'Adding...' : 'Add to cart'),
                      ),
                      TextButton(
                        onPressed: onRemove,
                        style: TextButton.styleFrom(
                          foregroundColor: c.muted,
                          minimumSize: const Size(64, 48),
                          textStyle: const TextStyle(fontSize: 14),
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
