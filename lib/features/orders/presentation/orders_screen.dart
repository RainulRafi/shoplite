import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/data_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/state_message.dart';
import '../../../core/widgets/tick_builder.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../../products/presentation/widgets/product_skeleton_tile.dart';
import '../domain/order.dart';
import '../domain/order_lifecycle.dart';
import '../domain/order_status.dart';
import 'order_detail_screen.dart';
import 'orders_provider.dart';

enum _OrderFilter { active, completed, cancelled }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _OrderFilter _filter = _OrderFilter.active;

  bool _matches(OrderStatus status) {
    switch (_filter) {
      case _OrderFilter.active:
        return OrderLifecycle.isActive(status);
      case _OrderFilter.completed:
        return status == OrderStatus.delivered;
      case _OrderFilter.cancelled:
        return status == OrderStatus.cancelled;
    }
  }

  Widget _tab(String label, _OrderFilter value, AppColors c) {
    final selected = _filter == value;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: GestureDetector(
          onTap: () => setState(() => _filter = value),
          child: Container(
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.accent : c.surface,
              border: Border.all(color: selected ? c.accent : c.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? c.onAccent : c.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _emptyTitle() {
    switch (_filter) {
      case _OrderFilter.active:
        return 'No orders on the way';
      case _OrderFilter.completed:
        return 'No delivered orders yet';
      case _OrderFilter.cancelled:
        return 'No cancelled orders';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<OrdersProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'My orders',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (provider.status) {
        DataStatus.loading => Semantics(
          label: 'Loading your orders',
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: const [ProductSkeletonTile(), ProductSkeletonTile()],
          ),
        ),
        DataStatus.error => StateMessage(
          title: 'Could not load your orders',
          body: 'Something went wrong reading them from this phone.',
          titleColor: c.danger,
          action: FilledButton(
            onPressed: provider.retry,
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

        DataStatus.ready => TickBuilder(
          builder: (context, now) {
            final shown = [
              for (final order in provider.orders)
                if (_matches(OrderLifecycle.statusAt(order, now))) order,
            ];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      _tab('Active', _OrderFilter.active, c),
                      const SizedBox(width: 8),
                      _tab('Completed', _OrderFilter.completed, c),
                      const SizedBox(width: 8),
                      _tab('Cancelled', _OrderFilter.cancelled, c),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? StateMessage(
                          title: _emptyTitle(),
                          body: provider.orders.isEmpty
                              ? 'Orders you place will show up here.'
                              : 'Try another tab.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: shown.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              _OrderCard(order: shown[index], now: now),
                        ),
                ),
              ],
            );
          },
        ),
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final DateTime now;

  const _OrderCard({required this.order, required this.now});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = OrderLifecycle.statusAt(order, now);

    final Color statusColor;
    switch (status) {
      case OrderStatus.delivered:
        statusColor = c.success;
      case OrderStatus.cancelled:
        statusColor = c.danger;
      default:
        statusColor = c.accentFg;
    }

    const maxThumbs = 4;
    final thumbs = order.items.take(maxThumbs).toList();
    final extra = order.items.length - thumbs.length;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                  Text(
                    status.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatDate(order.placedAt)}  ·  '
                '${order.itemCount} ${order.itemCount == 1 ? 'item' : 'items'}',
                style: TextStyle(fontSize: 13, color: c.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final item in thumbs) ...[
                    ProductImage(
                      url: item.thumbnail,
                      label: item.title,
                      size: 48,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (extra > 0)
                    Text(
                      '+$extra',
                      style: TextStyle(fontSize: 14, color: c.muted),
                    ),
                  const Spacer(),
                  Text(
                    order.total.format(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
