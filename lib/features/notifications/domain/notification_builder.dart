import '../../orders/domain/order.dart';
import '../../orders/domain/order_lifecycle.dart';
import '../../orders/domain/order_status.dart';
import 'app_notification.dart';

String _title(OrderStatus s) => switch (s) {
  OrderStatus.placed => 'Order placed',
  OrderStatus.confirmed => 'Order confirmed',
  OrderStatus.packed => 'Order packed',
  OrderStatus.shipped => 'Order shipped',
  OrderStatus.outForDelivery => 'Out for delivery',
  OrderStatus.delivered => 'Order delivered',
  OrderStatus.cancelled => 'Order cancelled',
};

String _body(OrderStatus s, String number) => switch (s) {
  OrderStatus.placed => 'We received order $number.',
  OrderStatus.confirmed => 'Order $number is confirmed.',
  OrderStatus.packed => 'Order $number is packed and ready to ship.',
  OrderStatus.shipped => 'Order $number is on its way.',
  OrderStatus.outForDelivery => 'Order $number is out for delivery.',
  OrderStatus.delivered => 'Order $number was delivered.',
  OrderStatus.cancelled => 'Order $number was cancelled.',
};

List<AppNotification> buildNotifications(
  List<Order> orders,
  DateTime now,
  Set<String> readKeys, {
  int limit = 50,
}) {
  final all = <AppNotification>[];

  for (final order in orders) {
    for (final step in OrderLifecycle.timeline(order, now)) {
      final at = step.at;
      if (!step.reached || at == null) continue;

      final key = '${order.id}:${step.status.name}';
      all.add(
        AppNotification(
          key: key,
          orderId: order.id,
          orderNumber: order.orderNumber,
          status: step.status,
          title: _title(step.status),
          body: _body(step.status, order.orderNumber),
          at: at,
          read: readKeys.contains(key),
        ),
      );
    }
  }

  all.sort((a, b) {
    final byTime = b.at.compareTo(a.at);
    if (byTime != 0) return byTime;
    final byStage = b.status.index.compareTo(a.status.index);
    return byStage != 0 ? byStage : b.orderId.compareTo(a.orderId);
  });
  return all.take(limit).toList();
}
