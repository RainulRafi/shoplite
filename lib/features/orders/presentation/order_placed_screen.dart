import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../shell/shell_tabs.dart';
import '../domain/payment.dart';
import 'order_detail_screen.dart';
import 'orders_provider.dart';

class OrderPlacedScreen extends StatelessWidget {
  final int orderId;

  const OrderPlacedScreen({super.key, required this.orderId});

  void _continueShopping(BuildContext context) {
    final tabs = context.read<ShellTabs>();
    Navigator.of(context).popUntil((route) => route.isFirst);
    tabs.go(ShellTab.shop);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final order = context.watch<OrdersProvider>().byId(orderId);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _continueShopping(context);
      },
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          child: order == null
              ? Center(
                  child: TextButton(
                    onPressed: () => _continueShopping(context),
                    child: const Text('Continue shopping'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
                  children: [
                    Text(
                      'Order placed',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Thank you. Your order number is ${order.orderNumber}.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: c.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _Fact(
                      label: 'Estimated delivery',
                      value: formatDateRange(
                        order.deliveryMethod.earliest(order.placedAt),
                        order.deliveryMethod.latest(order.placedAt),
                      ),
                    ),
                    _Fact(label: 'Deliver to', value: order.address.singleLine),
                    _Fact(
                      label: 'Payment',
                      value: order.paymentStatus == PaymentStatus.payOnDelivery
                          ? 'Pay ${order.total.format()} in cash on delivery'
                          : '${order.total.format()}, ${order.paymentStatus.title}',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Practice app: this order is saved on your phone only.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: c.faint,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id),
                        ),
                      ),
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
                      child: const Text('View order'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _continueShopping(context),
                      style: TextButton.styleFrom(
                        foregroundColor: c.accentFg,
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      child: const Text('Continue shopping'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.muted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, height: 1.4, color: c.ink),
          ),
        ],
      ),
    );
  }
}
