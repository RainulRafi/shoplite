import 'delivery_method.dart';
import 'order.dart';
import 'order_status.dart';

class TimelineStep {
  final OrderStatus status;
  final DateTime? at;
  final bool reached;
  final bool current;

  const TimelineStep({
    required this.status,
    required this.at,
    required this.reached,
    required this.current,
  });
}

class OrderLifecycle {
  OrderLifecycle._();

  static const List<OrderStatus> stages = [
    OrderStatus.placed,
    OrderStatus.confirmed,
    OrderStatus.packed,
    OrderStatus.shipped,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
  ];

  static const Map<DeliveryMethod, List<int>> _startMinutes = {
    DeliveryMethod.standard: [0, 1, 3, 6, 10, 15],
    DeliveryMethod.express: [0, 1, 2, 3, 5, 8],
  };

  static DateTime stageStart(Order order, OrderStatus stage) {
    final minutes = _startMinutes[order.deliveryMethod]![stages.indexOf(stage)];
    return order.placedAt.add(Duration(minutes: minutes));
  }

  static OrderStatus statusAt(Order order, DateTime now) {
    if (order.cancelledAt != null) return OrderStatus.cancelled;

    var current = OrderStatus.placed;
    for (final stage in stages) {
      if (!now.isBefore(stageStart(order, stage))) current = stage;
    }
    return current;
  }

  static bool canCancel(Order order, DateTime now) {
    final status = statusAt(order, now);
    return status == OrderStatus.placed ||
        status == OrderStatus.confirmed ||
        status == OrderStatus.packed;
  }

  static bool isActive(OrderStatus status) =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  static List<TimelineStep> timeline(Order order, DateTime now) {
    final cancelledAt = order.cancelledAt;

    if (cancelledAt != null) {
      return [
        for (final stage in stages)
          if (!stageStart(order, stage).isAfter(cancelledAt))
            TimelineStep(
              status: stage,
              at: stageStart(order, stage),
              reached: true,
              current: false,
            ),
        TimelineStep(
          status: OrderStatus.cancelled,
          at: cancelledAt,
          reached: true,
          current: true,
        ),
      ];
    }

    final current = statusAt(order, now);
    return [
      for (final stage in stages)
        TimelineStep(
          status: stage,
          at: now.isBefore(stageStart(order, stage))
              ? null
              : stageStart(order, stage),
          reached: !now.isBefore(stageStart(order, stage)),
          current: stage == current,
        ),
    ];
  }
}
