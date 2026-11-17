import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_message.dart';
import '../../auth/presentation/require_login.dart';
import '../../orders/presentation/checkout_screen.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../products/presentation/widgets/product_skeleton_tile.dart';
import '../../shell/shell_tabs.dart';
import '../domain/cart_item.dart';
import 'cart_provider.dart';
import 'widgets/cart_line_tile.dart';
import 'widgets/cart_summary.dart';
import 'widgets/coupon_section.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _remove(BuildContext context, CartItem item) {
    final cart = context.read<CartProvider>();
    final removed = cart.remove(item.productId);
    if (removed == null) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Removed from your cart.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => cart.restore(removed),
          ),
        ),
      );
  }

  Future<void> _checkout(BuildContext context) async {
    final signedIn = await requireLogin(
      context,
      reason: 'Sign in to check out.',
    );
    if (!signedIn || !context.mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cart = context.watch<CartProvider>();
    final showBar = cart.status == CartStatus.ready && !cart.isEmpty;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Cart',
          style: TextStyle(
            color: c.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (cart.status) {
        CartStatus.loading => Semantics(
          label: 'Loading your cart',
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
        CartStatus.error => StateMessage(
          title: 'Could not load your cart',
          body: 'Something went wrong reading your cart from this phone.',
          titleColor: c.danger,
          action: FilledButton(
            onPressed: cart.retry,
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
          ),
        ),
        CartStatus.ready =>
          cart.isEmpty
              ? StateMessage(
                  title: 'Your cart is empty',
                  body: 'Items you add stay here, even if you close the app.',
                  action: FilledButton(
                    onPressed: () =>
                        context.read<ShellTabs>().go(ShellTab.shop),
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
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    for (final item in cart.items) ...[
                      CartLineTile(
                        item: item,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              product: item.toPlaceholderProduct(),
                            ),
                          ),
                        ),
                        onIncrement: () => cart.increment(item.productId),
                        onDecrement: () => cart.decrement(item.productId),
                        onRemove: () => _remove(context, item),
                      ),
                      Divider(height: 1, color: c.border),
                    ],
                    const SizedBox(height: 24),
                    const CouponSection(),
                    const SizedBox(height: 28),
                    CartSummary(totals: cart.totals),
                  ],
                ),
      },
      bottomNavigationBar: showBar
          ? Container(
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                      Text(
                        cart.totals.total.format(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _checkout(context),
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
                      child: const Text('Checkout'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
