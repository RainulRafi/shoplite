import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/notifications/domain/notification_builder.dart';
import 'package:shoplite/features/orders/domain/delivery_method.dart';
import 'package:shoplite/features/orders/domain/order.dart';
import 'package:shoplite/features/orders/domain/order_status.dart';

import '../../helpers/order_fixtures.dart';

DateTime _at(int minutes) => t0.add(Duration(minutes: minutes));

Order _order(
  int id,
  DateTime placedAt, {
  DateTime? cancelledAt,
  DeliveryMethod delivery = DeliveryMethod.standard,
}) {
  final base = testOrder(
    placedAt: placedAt,
    delivery: delivery,
    cancelledAt: cancelledAt,
  );
  return Order(
    id: id,
    orderNumber: 'SL-0000$id',
    placedAt: base.placedAt,
    items: base.items,
    address: base.address,
    deliveryMethod: base.deliveryMethod,
    paymentMethod: base.paymentMethod,
    paymentStatus: base.paymentStatus,
    listTotal: base.listTotal,
    itemDiscount: base.itemDiscount,
    subtotal: base.subtotal,
    couponCode: null,
    couponDiscount: base.couponDiscount,
    shipping: base.shipping,
    total: base.total,
    cancelledAt: base.cancelledAt,
  );
}

void main() {
  test('a new order has one notification, "Order placed"', () {
    final list = buildNotifications([_order(1, t0)], _at(0), const {});

    expect(list, hasLength(1));
    expect(list.single.title, 'Order placed');
    expect(list.single.body, 'We received order SL-00001.');
    expect(list.single.key, '1:placed');
  });

  test('every reached step adds one, newest first', () {
    final list = buildNotifications([_order(1, t0)], _at(4), const {});

    expect(list.map((n) => n.status), [
      OrderStatus.packed,
      OrderStatus.confirmed,
      OrderStatus.placed,
    ]);
  });

  test('a delivered order has the whole journey', () {
    final list = buildNotifications([_order(1, t0)], _at(60), const {});

    expect(list, hasLength(6));
    expect(list.first.status, OrderStatus.delivered);
  });

  test('a cancelled order stops at the cancellation', () {
    final list = buildNotifications(
      [_order(1, t0, cancelledAt: _at(2))],
      _at(60),
      const {},
    );

    expect(list.map((n) => n.status), [
      OrderStatus.cancelled,
      OrderStatus.confirmed,
      OrderStatus.placed,
    ]);
    expect(list.first.title, 'Order cancelled');
  });

  test('read keys mark only those notifications', () {
    final list = buildNotifications(
      [_order(1, t0)],
      _at(4),
      {'1:placed', '1:confirmed'},
    );

    expect(list.where((n) => n.read).map((n) => n.status), [
      OrderStatus.confirmed,
      OrderStatus.placed,
    ]);
    expect(list.first.read, isFalse); // packed
  });

  test('two orders interleave by time, and a later step wins a tie', () {
    final list = buildNotifications(
      [_order(1, t0), _order(2, _at(2), delivery: DeliveryMethod.express)],
      _at(3),
      const {},
    );

    expect(list.map((n) => '${n.orderId}:${n.status.name}'), [
      '1:packed',
      '2:confirmed',
      '2:placed',
      '1:confirmed',
      '1:placed',
    ]);
  });

  test('only the newest few are kept', () {
    final list = buildNotifications(
      [_order(1, t0)],
      _at(60),
      const {},
      limit: 2,
    );

    expect(list, hasLength(2));
    expect(list.first.status, OrderStatus.delivered);
  });

  test('no orders gives no notifications', () {
    expect(buildNotifications(const [], _at(0), const {}), isEmpty);
  });
}
