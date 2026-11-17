import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/orders/domain/delivery_method.dart';
import 'package:shoplite/features/orders/domain/order_lifecycle.dart';
import 'package:shoplite/features/orders/domain/order_status.dart';

import '../../../helpers/order_fixtures.dart';

DateTime _at(int minutes, [int seconds = 0]) =>
    t0.add(Duration(minutes: minutes, seconds: seconds));

void main() {
  group('standard delivery', () {
    final order = testOrder();

    test('the status follows the clock', () {
      expect(OrderLifecycle.statusAt(order, _at(0)), OrderStatus.placed);
      expect(OrderLifecycle.statusAt(order, _at(0, 59)), OrderStatus.placed);
      expect(OrderLifecycle.statusAt(order, _at(1)), OrderStatus.confirmed);
      expect(OrderLifecycle.statusAt(order, _at(3)), OrderStatus.packed);
      expect(OrderLifecycle.statusAt(order, _at(6)), OrderStatus.shipped);
      expect(
        OrderLifecycle.statusAt(order, _at(10)),
        OrderStatus.outForDelivery,
      );
      expect(OrderLifecycle.statusAt(order, _at(15)), OrderStatus.delivered);
      expect(
        OrderLifecycle.statusAt(order, t0.add(const Duration(days: 2))),
        OrderStatus.delivered,
      );
    });

    test('a clock set before the order is still placed', () {
      expect(OrderLifecycle.statusAt(order, _at(-5)), OrderStatus.placed);
    });

    test('it can be cancelled until it ships', () {
      expect(OrderLifecycle.canCancel(order, _at(0)), isTrue);
      expect(OrderLifecycle.canCancel(order, _at(5, 59)), isTrue);
      expect(OrderLifecycle.canCancel(order, _at(6)), isFalse);
      expect(OrderLifecycle.canCancel(order, _at(20)), isFalse);
    });
  });

  group('express delivery', () {
    final order = testOrder(delivery: DeliveryMethod.express);

    test('it moves faster', () {
      expect(OrderLifecycle.statusAt(order, _at(2)), OrderStatus.packed);
      expect(OrderLifecycle.statusAt(order, _at(3)), OrderStatus.shipped);
      expect(OrderLifecycle.statusAt(order, _at(8)), OrderStatus.delivered);
    });

    test('and its cancel window is shorter', () {
      expect(OrderLifecycle.canCancel(order, _at(2, 30)), isTrue);
      expect(OrderLifecycle.canCancel(order, _at(3)), isFalse);
    });
  });

  group('a cancelled order', () {
    final order = testOrder(cancelledAt: _at(2));

    test('stays cancelled and cannot be cancelled again', () {
      expect(OrderLifecycle.statusAt(order, _at(0)), OrderStatus.cancelled);
      expect(OrderLifecycle.statusAt(order, _at(60)), OrderStatus.cancelled);
      expect(OrderLifecycle.canCancel(order, _at(0)), isFalse);
    });

    test('its timeline stops where it was cancelled', () {
      final steps = OrderLifecycle.timeline(order, _at(60));

      expect(steps.map((s) => s.status), [
        OrderStatus.placed,
        OrderStatus.confirmed,
        OrderStatus.cancelled,
      ]);
      expect(steps.last.current, isTrue);
      expect(steps.last.at, _at(2));
    });
  });

  test('the timeline marks what is reached and what is current', () {
    final steps = OrderLifecycle.timeline(testOrder(), _at(4));

    expect(
      steps.where((s) => s.reached).length,
      3,
    ); // placed, confirmed, packed
    expect(steps.singleWhere((s) => s.current).status, OrderStatus.packed);
    expect(steps.first.at, _at(0));
    expect(steps.last.at, isNull);
  });

  test('only orders on their way count as active', () {
    expect(OrderLifecycle.isActive(OrderStatus.shipped), isTrue);
    expect(OrderLifecycle.isActive(OrderStatus.delivered), isFalse);
    expect(OrderLifecycle.isActive(OrderStatus.cancelled), isFalse);
  });
}
