import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/idempotency_key.dart';
import '../../../core/widgets/state_message.dart';
import '../../addresses/presentation/address_form_screen.dart';
import '../../addresses/presentation/address_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../products/data/product_repository.dart';
import '../../products/presentation/widgets/product_skeleton_tile.dart';
import '../data/order_repository.dart';
import '../domain/checkout_pricing.dart';
import '../domain/delivery_method.dart';
import '../domain/payment.dart';
import 'checkout_provider.dart';
import 'demo_payment_screen.dart';
import 'order_placed_screen.dart';
import 'orders_provider.dart';
import 'widgets/line_item_row.dart';
import 'widgets/price_breakdown.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CheckoutProvider(
        products: ctx.read<ProductRepository>(),
        orders: ctx.read<OrderRepository>(),
        cart: ctx.read<CartProvider>(),
        addresses: ctx.read<AddressProvider>(),
        auth: ctx.read<AuthProvider>(),
        idempotencyKey: newIdempotencyKey(),
        onPlaced: ctx.read<OrdersProvider>().addPlaced,
      )..verify(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final checkout = context.watch<CheckoutProvider>();

    return PopScope(
      canPop: !checkout.placing,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: c.ink),
          centerTitle: false,
          title: Text(
            'Checkout',
            style: TextStyle(
              color: c.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: switch (checkout.status) {
          CheckoutStatus.verifying => Semantics(
            label: 'Checking your items',
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
          CheckoutStatus.verifyFailed => StateMessage(
            title: 'Could not check your items',
            body:
                '${checkout.verifyMessage ?? 'Something went wrong.'} '
                'We check prices and stock before you order.',
            titleColor: c.danger,
            action: FilledButton(
              onPressed: checkout.verify,
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
          CheckoutStatus.empty => StateMessage(
            title: 'Your cart is empty',
            body: checkout.changes.isEmpty
                ? 'There is nothing to check out.'
                : checkout.changes.map((ch) => ch.describe()).join(' '),
            action: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
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
              child: const Text('Back to cart'),
            ),
          ),
          CheckoutStatus.ready => const _ReadyBody(),
        },
        bottomNavigationBar: checkout.status == CheckoutStatus.ready
            ? const _PlaceOrderBar()
            : null,
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final checkout = context.watch<CheckoutProvider>();
    final now = DateTime.now();

    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: c.faint,
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (checkout.changes.isNotEmpty) const _ChangesBanner(),

        title('DELIVERY ADDRESS').withoutTopGap(),
        const _AddressSection(),

        title('DELIVERY'),
        for (final method in DeliveryMethod.values) ...[
          _ChoiceCard(
            selected: checkout.delivery == method,
            title: method.title,
            subtitle:
                'Arrives ${formatDateRange(method.earliest(now), method.latest(now))}'
                ' (${method.etaText})',
            trailing: _shippingText(checkout, method),
            onTap: () => checkout.setDelivery(method),
          ),
          const SizedBox(height: 8),
        ],

        title('PAYMENT'),
        _ChoiceCard(
          selected: checkout.payment == PaymentMethod.cashOnDelivery,
          title: PaymentMethod.cashOnDelivery.title,
          subtitle: 'Pay in cash when your order arrives.',
          onTap: () => checkout.setPayment(PaymentMethod.cashOnDelivery),
        ),
        const SizedBox(height: 8),
        _ChoiceCard(
          selected: checkout.payment == PaymentMethod.onlineDemo,
          title: PaymentMethod.onlineDemo.title,
          subtitle: 'A practice flow. No card details are asked or stored.',
          onTap: () => checkout.setPayment(PaymentMethod.onlineDemo),
        ),

        title('ORDER SUMMARY'),
        for (final item in checkout.items) ...[
          LineItemRow(
            thumbnail: item.thumbnail,
            title: item.title,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            lineTotal: item.lineTotal,
          ),
          Divider(height: 1, color: c.border),
        ],
        const SizedBox(height: 14),
        PriceBreakdown.fromTotals(checkout.totals),
        const SizedBox(height: 16),
        Text(
          'Practice app: nothing is charged and nothing is delivered.',
          style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
        ),
      ],
    );
  }

  String _shippingText(CheckoutProvider checkout, DeliveryMethod method) {
    final shipping = CheckoutPricing.compute(
      checkout.items,
      couponCode: checkout.couponCode,
      method: method,
    ).shipping;
    return shipping.isZero ? 'Free' : shipping.format();
  }
}

extension on Widget {
  Widget withoutTopGap() =>
      Transform.translate(offset: const Offset(0, -18), child: this);
}

class _ChangesBanner extends StatelessWidget {
  const _ChangesBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final checkout = context.read<CheckoutProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            liveRegion: true,
            child: Text(
              'We updated your cart',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (final change in checkout.changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, right: 8),
              child: Text(
                change.describe(),
                style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: checkout.dismissChanges,
              style: TextButton.styleFrom(
                foregroundColor: c.accentFg,
                minimumSize: const Size(64, 48),
              ),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final checkout = context.watch<CheckoutProvider>();
    final address = checkout.selectedAddress;

    if (address == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Where should we deliver?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a delivery address to place your order.',
              style: TextStyle(fontSize: 14, color: c.muted),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => _addAddress(context),
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
              child: const Text('Add address'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                address.label.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _chooseAddress(context),
                style: TextButton.styleFrom(
                  foregroundColor: c.accentFg,
                  minimumSize: const Size(64, 48),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Change'),
              ),
            ],
          ),
          Text(address.fullName, style: TextStyle(fontSize: 14, color: c.ink)),
          const SizedBox(height: 2),
          Text(address.phone, style: TextStyle(fontSize: 14, color: c.muted)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(
              address.singleLine,
              style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _addAddress(BuildContext context) async {
  final checkout = context.read<CheckoutProvider>();
  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const AddressFormScreen(),
    ),
  );

  if (saved == true) checkout.selectNewestAddress();
}

Future<void> _chooseAddress(BuildContext context) async {
  final checkout = context.read<CheckoutProvider>();

  final wantsNew = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),

    builder: (sheetContext) => ListenableBuilder(
      listenable: checkout,
      builder: (context, _) {
        final c = context.colors;
        final selected = checkout.selectedAddress;

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.8,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              children: [
                Text(
                  'Choose an address',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 12),
                for (final a in checkout.addresses) ...[
                  _ChoiceCard(
                    selected: selected?.id == a.id,
                    title: '${a.label.title}: ${a.fullName}',
                    subtitle: a.singleLine,
                    onTap: () {
                      checkout.selectAddress(a.id!);
                      Navigator.of(sheetContext).pop(false);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: c.accentFg,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  child: const Text('Add a new address'),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  if (wantsNew == true && context.mounted) await _addAddress(context);
}

class _ChoiceCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(
              color: selected ? c.accentFg : c.border,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.accentFg : c.subtle,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c.accentFg,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: c.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailing!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar();

  Future<void> _place(BuildContext context) async {
    final checkout = context.read<CheckoutProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final online = checkout.payment == PaymentMethod.onlineDemo;

    if (online) {
      final Money amount = checkout.totals.total;
      final outcome = await navigator.push<PaymentOutcome>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DemoPaymentScreen(amount: amount),
        ),
      );
      if (!context.mounted) return;
      if (outcome == null || outcome == PaymentOutcome.cancelled) return;
      if (outcome == PaymentOutcome.failed) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Payment failed. You were not charged and your cart is unchanged. '
                'Try again or choose cash on delivery.',
              ),
            ),
          );
        return;
      }
    }

    final result = await checkout.placeOrder(demoPaymentSucceeded: online);
    if (!context.mounted) return;

    switch (result) {
      case PlaceResult.placed:
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                OrderPlacedScreen(orderId: checkout.placedOrder!.id),
          ),
        );
      case PlaceResult.alreadyPlacing:
        break;
      case PlaceResult.noAddress:
        _snack(messenger, 'Choose a delivery address first.');
      case PlaceResult.failed:
        _snack(
          messenger,
          checkout.placeError ?? 'We could not place your order.',
        );
      case PlaceResult.notSignedIn:
        _snack(messenger, 'Please sign in to place an order.');
      case PlaceResult.emptyCart:
      case PlaceResult.notReady:
      case PlaceResult.paymentRequired:
        _snack(messenger, 'Please review your order and try again.');
    }
  }

  void _snack(ScaffoldMessengerState messenger, String text) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final checkout = context.watch<CheckoutProvider>();
    final total = checkout.totals.total;

    final String? hint = checkout.selectedAddress == null
        ? 'Choose a delivery address to continue.'
        : null;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null) ...[
              Text(hint, style: TextStyle(fontSize: 13, color: c.muted)),
              const SizedBox(height: 8),
            ],
            Row(
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
                      total.format(),
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
                    onPressed: checkout.canPlace ? () => _place(context) : null,
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
                    child: Text(
                      checkout.placing ? 'Placing order...' : 'Place order',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
