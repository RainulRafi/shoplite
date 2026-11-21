import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/addresses/data/sqlite_address_repository.dart';
import 'package:shoplite/features/cart/data/sqlite_cart_repository.dart';
import 'package:shoplite/features/orders/data/sqlite_order_repository.dart';
import 'package:shoplite/features/orders/domain/delivery_method.dart';
import 'package:shoplite/features/orders/domain/payment.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/order_fixtures.dart';
import '../../../helpers/test_support.dart';

void main() {
  late Database db;
  late SqliteOrderRepository orders;
  late SqliteCartRepository carts;

  setUp(() async {
    db = await openTestDatabase();
    orders = SqliteOrderRepository(() async => db);
    carts = SqliteCartRepository(() async => db);
  });

  tearDown(() => db.close());

  Future<int> scalarInt(String sql) async {
    final result = await db.rawQuery(sql);
    return (result.single.values.single as num).toInt();
  }

  Future<int> orderCount() => scalarInt('SELECT COUNT(*) FROM orders');

  test('placing saves the order, its items and the totals', () async {
    final request = testRequest(
      items: [
        testCartItem(1, qty: 2, unit: 900, list: 1000),
        testCartItem(2, qty: 1, unit: 500, list: 500),
      ],
      delivery: DeliveryMethod.express,
      payment: PaymentMethod.onlineDemo,
      status: PaymentStatus.paidDemo,
    );

    final placed = await orders.place(request);
    final order = placed.order;

    expect(placed.alreadyExisted, isFalse);
    expect(order.orderNumber, 'SL-20261117-0001');
    expect(order.placedAt, t0);
    expect(order.itemCount, 3);
    expect(order.items.map((i) => i.title), ['P1', 'P2']);
    expect(order.items.first.unitPrice.cents, 900);
    expect(order.deliveryMethod, DeliveryMethod.express);
    expect(order.paymentMethod, PaymentMethod.onlineDemo);
    expect(order.paymentStatus, PaymentStatus.paidDemo);
    expect(order.address.fullName, 'Rahim Uddin');

    expect(order.subtotal.cents, 2300);
    expect(order.shipping.cents, 1200);
    expect(order.total.cents, request.totals.total.cents);
    expect(order.total.cents, 3500);
  });

  test('placing empties the buyer cart and coupon, and nobody else', () async {
    await carts.saveItem('user:1', testCartItem(1));
    await carts.saveCoupon('user:1', 'SAVE10');
    await carts.saveItem('user:2', testCartItem(9));

    await orders.place(testRequest());

    expect(await carts.loadItems('user:1'), isEmpty);
    expect(await carts.loadCoupon('user:1'), isNull);
    expect((await carts.loadItems('user:2')).single.productId, 9);
  });

  test(
    'the same key returns the same order and leaves the cart alone',
    () async {
      final first = await orders.place(testRequest(key: 'same'));

      await carts.saveItem('user:1', testCartItem(7));

      final second = await orders.place(testRequest(key: 'same'));

      expect(second.alreadyExisted, isTrue);
      expect(second.order.id, first.order.id);
      expect(second.order.orderNumber, first.order.orderNumber);
      expect(await orderCount(), 1);
      expect((await carts.loadItems('user:1')).single.productId, 7);
    },
  );

  test(
    'order numbers count up within a day and restart the next day',
    () async {
      final a = await orders.place(testRequest(key: 'a'));
      final b = await orders.place(testRequest(key: 'b'));
      final c = await orders.place(
        testRequest(key: 'c', placedAt: t0.add(const Duration(days: 1))),
      );

      expect(a.order.orderNumber, 'SL-20261117-0001');
      expect(b.order.orderNumber, 'SL-20261117-0002');
      expect(c.order.orderNumber, 'SL-20261118-0001');
    },
  );

  test('a failure in the middle saves nothing and keeps the cart', () async {
    await carts.saveItem('user:1', testCartItem(1));
    await carts.saveCoupon('user:1', 'SAVE10');

    final bad = testRequest(items: [testCartItem(1), testCartItem(5, qty: 0)]);

    await expectLater(orders.place(bad), throwsA(isA<DatabaseException>()));

    expect(await orderCount(), 0);
    expect(
      await scalarInt('SELECT COUNT(*) FROM order_items'),
      0,
    );
    expect((await carts.loadItems('user:1')).single.productId, 1);
    expect(await carts.loadCoupon('user:1'), 'SAVE10');
  });

  test('an order with no items is refused', () async {
    await expectLater(
      orders.place(testRequest(items: [])),
      throwsA(isA<ArgumentError>()),
    );
  });

  test(
    'the address on an order does not change when the saved one is edited',
    () async {
      final addressRepo = SqliteAddressRepository(() async => db);
      final id = await addressRepo.insert(
        'user:1',
        testAddress(line1: 'House 12, Road 4'),
      );
      final saved = (await addressRepo.loadAll('user:1')).single;

      final placed = await orders.place(testRequest(address: saved));

     
      await db.update(
        'addresses',
        {'line1': 'Shop 9, Main road'},
        where: 'id = ?',
        whereArgs: [id],
      );
      expect(
        (await addressRepo.loadAll('user:1')).single.line1,
        'Shop 9, Main road',
      );

      final reloaded = await orders.load('user:1', placed.order.id);
      expect(reloaded!.address.line1, 'House 12, Road 4'); 
    },
  );

  test('orders list newest first and belong to their owner', () async {
    await orders.place(testRequest(key: 'a', placedAt: t0));
    await orders.place(
      testRequest(key: 'b', placedAt: t0.add(const Duration(hours: 1))),
    );
    await orders.place(testRequest(key: 'c', ownerId: 'user:2'));

    final mine = await orders.loadAll('user:1');
    expect(mine.map((o) => o.placedAt), [t0.add(const Duration(hours: 1)), t0]);
    expect(await orders.loadAll('user:2'), hasLength(1));
    expect(await orders.loadAll('user:3'), isEmpty);
  });

  test('another person cannot load an order by its id', () async {
    final placed = await orders.place(testRequest(ownerId: 'user:1'));

    expect(await orders.load('user:2', placed.order.id), isNull);
    expect(await orders.load('user:1', placed.order.id), isNotNull);
  });

  group('cancelling', () {
    test('works early and records when', () async {
      final placed = await orders.place(testRequest());
      final when = t0.add(const Duration(minutes: 2));

      expect(await orders.cancel('user:1', placed.order.id, when), isTrue);

      final order = await orders.load('user:1', placed.order.id);
      expect(order!.cancelledAt, when);
    });

    test('is refused once the order has shipped', () async {
      final placed = await orders.place(testRequest());

      final late = t0.add(const Duration(minutes: 7));
      expect(await orders.cancel('user:1', placed.order.id, late), isFalse);

      final order = await orders.load('user:1', placed.order.id);
      expect(order!.cancelledAt, isNull);
    });

    test('is refused for someone else and the second time', () async {
      final placed = await orders.place(testRequest());
      final early = t0.add(const Duration(minutes: 1));

      expect(await orders.cancel('user:2', placed.order.id, early), isFalse);
      expect(await orders.cancel('user:1', placed.order.id, early), isTrue);
      expect(await orders.cancel('user:1', placed.order.id, early), isFalse);
    });

    test('an unknown order id is refused', () async {
      expect(await orders.cancel('user:1', 999, t0), isFalse);
    });
  });
}


