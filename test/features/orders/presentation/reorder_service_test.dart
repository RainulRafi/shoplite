import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/features/cart/presentation/cart_provider.dart';
import 'package:shoplite/features/orders/domain/order.dart';
import 'package:shoplite/features/orders/presentation/reorder_service.dart';
import 'package:shoplite/features/products/data/product_repository.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/fake_cart_repository.dart';
import '../../../helpers/order_fixtures.dart';

class MockProductRepository extends Mock implements ProductRepository {}

Order _orderWith(List<OrderItem> items) {
  final base = testOrder();
  return Order(
    id: base.id,
    orderNumber: base.orderNumber,
    placedAt: base.placedAt,
    items: items,
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
  );
}

OrderItem _item(int id, {int qty = 1}) =>
    OrderItem.fromCartItem(testCartItem(id, qty: qty));

Future<void> _waitForCartReady(CartProvider cart) async {
  while (cart.status != CartStatus.ready) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  late MockProductRepository products;
  late AuthRig rig;
  late CartProvider cart;
  late ReorderService service;

  setUp(() async {
    products = MockProductRepository();
    rig = AuthRig();
    await rig.auth.restore();
    cart = CartProvider(FakeCartRepository(), rig.auth);
    await _waitForCartReady(cart);
    service = ReorderService(products, cart);
  });

  tearDown(() {
    cart.dispose();
    rig.dispose();
  });

  void serverHas(int id, {double price = 10, int stock = 5}) {
    when(() => products.fetchProduct(id))
        .thenAnswer((_) async => testProduct(id, price: price, stock: stock));
  }

  test(
    'available items go back into the cart with their old quantities',
    () async {
      serverHas(1);
      serverHas(2);

      final summary = await service.run(
        _orderWith([_item(1, qty: 2), _item(2, qty: 1)]),
      );

      expect(summary.linesAdded, 2);
      expect(summary.outOfStock, isEmpty);
      expect(cart.quantityOf(1), 2);
      expect(cart.quantityOf(2), 1);
      expect(summary.message(), 'Added 2 items to your cart.');
    },
  );

  test('the current price is used, not the old order price', () async {
    serverHas(1, price: 15); // Order-এর সময় $10 ছিল

    await service.run(_orderWith([_item(1)]));

    expect(cart.items.single.unitPrice.cents, 1500);
  });

  test('an out of stock item is skipped and named', () async {
    serverHas(1);
    serverHas(2, stock: 0);

    final summary = await service.run(_orderWith([_item(1), _item(2)]));

    expect(summary.linesAdded, 1);
    expect(summary.outOfStock, ['P2']);
    expect(cart.quantityOf(2), 0);
    expect(summary.message(), contains('Out of stock: P2.'));
  });

  test('less stock than before reduces the quantity and says so', () async {
    serverHas(1, stock: 2);

    final summary = await service.run(_orderWith([_item(1, qty: 4)]));

    expect(cart.quantityOf(1), 2);
    expect(summary.reduced, ['P1']);
    expect(summary.linesAdded, 1);
  });

  test(
    'an item that could not be checked is named, the rest still go in',
    () async {
      serverHas(1);
      when(() => products.fetchProduct(2)).thenAnswer(
        (_) => Future.error(
          const ApiException(
            type: ApiErrorType.noConnection,
            message: 'No internet',
          ),
        ),
      );

      final summary = await service.run(_orderWith([_item(1), _item(2)]));

      expect(summary.linesAdded, 1);
      expect(summary.unavailable, ['P2']);
      expect(summary.message(), contains('Could not check: P2.'));
    },
  );

  test('items already in the cart add up, within stock', () async {
    serverHas(1, stock: 5);
    cart.addProduct(testProduct(1, stock: 5), quantity: 3);

    await service.run(_orderWith([_item(1, qty: 4)]));

    expect(cart.quantityOf(1), 5); // 3 + 4 = 7, স্টকে ৫
  });

  test('when nothing can be added the message says so', () async {
    serverHas(1, stock: 0);

    final summary = await service.run(_orderWith([_item(1)]));

    expect(summary.nothingAdded, isTrue);
    expect(
      summary.message(),
      startsWith('Nothing could be added to your cart.'),
    );
  });
}
