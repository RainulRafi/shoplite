import 'package:flutter/foundation.dart';

import '../../orders/domain/order_status.dart';

@immutable
class AppNotification {
  final String key;
  final int orderId;
  final String orderNumber;
  final OrderStatus status;
  final String title;
  final String body;
  final DateTime at;
  final bool read;

  const AppNotification({
    required this.key,
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.title,
    required this.body,
    required this.at,
    required this.read,
  });
}
