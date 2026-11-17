import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/state_message.dart';
import '../../../core/widgets/tick_builder.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../products/data/product_repository.dart';
import '../../products/presentation/product_detail_screen.dart';
import '../../shell/shell_tabs.dart';
import '../domain/order.dart';
import '../domain/order_lifecycle.dart';
import '../domain/order_status.dart';
import 'orders_provider.dart';
import 'reorder_service.dart';
import 'widgets/line_item_row.dart';
import 'widgets/order_timeline.dart';
import 'widgets/price_breakdown.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _busy = false;

  Future<void> _cancel(Order order) async {
    final provider = context.read<OrdersProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final c = dialogContext.colors;
            return AlertDialog(
              backgroundColor: c.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: c.border),
              ),
              title: Text(
                'Cancel this order?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              content: Text(
                '${order.orderNumber} will be cancelled. This cannot be undone.',
                style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Keep order',
                    style: TextStyle(
                      color: c.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(
                    'Cancel order',
                    style: TextStyle(
                      color: c.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final result = await provider.cancel(order);
    if (mounted) setState(() => _busy = false);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result) {
            CancelResult.cancelled => 'Order cancelled.',
            CancelResult.notAllowed => 'This order has already been shipped, so it can no longer be cancelled.',
            CancelResult.failed =>
              'Could not cancel the order. Please try again.',
          }),
        ),
      );
  }

  Future<void> _reorder(Order order) async {
    final service = ReorderService(
      context.read<ProductRepository>(),
      context.read<CartProvider>(),
    );
    final navigator = Navigator.of(context);
    final tabs = context.read<ShellTabs>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    final summary = await service.run(order);
    if (mounted) setState(() => _busy = false);

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(summary.message()),
          duration: const Duration(seconds: 6),
          action: summary.nothingAdded
              ? null
              : SnackBarAction(
                  label: 'View cart',
                  onPressed: () {
                    navigator.popUntil((route) => route.isFirst);
                    tabs.go(ShellTab.cart);
                  },
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final order = context.watch<OrdersProvider>().byId(widget.orderId);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Order details',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: order == null
          ? const StateMessage(
              title: 'Order not found',
              body: 'It may belong to a different account.',
            )
          : TickBuilder(
              builder: (context, now) => _Body(
                order: order,
                now: now,
                busy: _busy,
                onCancel: () => _cancel(order),
                onReorder: () => _reorder(order),
              ),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  final Order order;
  final DateTime now;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onReorder;

  const _Body({
    required this.order,
    required this.now,
    required this.busy,
    required this.onCancel,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = OrderLifecycle.statusAt(order, now);

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

    final String subtitle;
    switch (status) {
      case OrderStatus.delivered:
        subtitle = 'Delivered';
      case OrderStatus.cancelled:
        subtitle = order.cancelledAt == null
            ? 'Cancelled'
            : 'Cancelled on ${formatDateTime(order.cancelledAt!)}';
      default:
        subtitle =
            'Estimated delivery '
            '${formatDateRange(order.deliveryMethod.earliest(order.placedAt), order.deliveryMethod.latest(order.placedAt))}';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
      children: [
        Text(order.orderNumber, style: TextStyle(fontSize: 13, color: c.muted)),
        const SizedBox(height: 4),
        Text(
          status.title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: status == OrderStatus.cancelled ? c.danger : c.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(fontSize: 14, color: c.muted)),
        const SizedBox(height: 4),
        Text(
          'Placed on ${formatDateTime(order.placedAt)}',
          style: TextStyle(fontSize: 13, color: c.faint),
        ),

        title('PROGRESS'),
        OrderTimeline(steps: OrderLifecycle.timeline(order, now)),
        Text(
          'Demo fulfilment: statuses move on a short timer so you can see the '
          'whole journey in a few minutes.',
          style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
        ),

        title('ITEMS'),
        for (final item in order.items) ...[
          LineItemRow(
            thumbnail: item.thumbnail,
            title: item.title,
            quantity: item.quantity,
            unitPrice: item.unitPrice,
            lineTotal: item.lineTotal,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ProductDetailScreen(product: item.toPlaceholderProduct()),
              ),
            ),
          ),
          Divider(height: 1, color: c.border),
        ],

        title('DELIVERY ADDRESS'),
        Text(
          order.address.fullName,
          style: TextStyle(fontSize: 15, color: c.ink),
        ),
        const SizedBox(height: 2),
        Text(
          order.address.phone,
          style: TextStyle(fontSize: 14, color: c.muted),
        ),
        const SizedBox(height: 6),
        Text(
          order.address.singleLine,
          style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
        ),
        if (order.address.note != null && order.address.note!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Note: ${order.address.note}',
            style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
          ),
        ],

        title('DELIVERY AND PAYMENT'),
        Text(
          '${order.deliveryMethod.title} delivery',
          style: TextStyle(fontSize: 15, color: c.ink),
        ),
        const SizedBox(height: 2),
        Text(
          '${order.paymentMethod.title}, ${order.paymentStatus.title}',
          style: TextStyle(fontSize: 14, color: c.muted),
        ),

        title('PAYMENT SUMMARY'),
        PriceBreakdown(
          listTotal: order.listTotal,
          itemDiscount: order.itemDiscount,
          couponCode: order.couponCode,
          couponDiscount: order.couponDiscount,
          shipping: order.shipping,
          total: order.total,
        ),

        const SizedBox(height: 28),
        FilledButton(
          onPressed: busy ? null : onReorder,
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
          child: Text(busy ? 'Please wait...' : 'Order again'),
        ),
        if (OrderLifecycle.canCancel(order, now)) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: busy ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.danger,
              side: BorderSide(color: c.border),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            child: const Text('Cancel order'),
          ),
        ],
      ],
    );
  }
}
