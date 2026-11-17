import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/cart/domain/cart_item.dart';
import 'package:shoplite/features/cart/domain/cart_reconcile.dart';
import 'package:shoplite/features/products/data/product.dart';

import '../../../helpers/order_fixtures.dart';

CartItem _line(int id, {int qty = 2, double price = 10, int stock = 5}) =>
    CartItem.fromProduct(
      testProduct(id, price: price, stock: stock),
      quantity: qty,
      addedAt: DateTime.fromMillisecondsSinceEpoch(id * 1000),
    );

void main() {
  test('an unchanged product changes nothing', () {
    final result = reconcileCart([_line(1)], {1: testProduct(1)});

    expect(result.changes, isEmpty);
    expect(result.items.single.quantity, 2);
    expect(result.items.single.unitPrice.cents, 1000);
  });

  test('a new price is applied and reported', () {
    final result = reconcileCart([_line(1)], {1: testProduct(1, price: 12)});

    expect(result.items.single.unitPrice.cents, 1200);
    expect(result.items.single.quantity, 2);
    final change = result.changes.single;
    expect(change.type, CartChangeType.priceChanged);
    expect(change.oldUnitPrice!.cents, 1000);
    expect(change.newUnitPrice!.cents, 1200);
  });

  test('a new discount counts as a price change too', () {
    final result = reconcileCart([_line(1)], {1: testProduct(1, discount: 10)});

    expect(result.items.single.unitPrice.cents, 900);
    expect(result.changes.single.type, CartChangeType.priceChanged);
  });

  test('less stock than the quantity reduces it', () {
    final result = reconcileCart(
      [_line(1, qty: 4)],
      {1: testProduct(1, stock: 1)},
    );

    expect(result.items.single.quantity, 1);
    final change = result.changes.single;
    expect(change.type, CartChangeType.quantityReduced);
    expect(change.oldQuantity, 4);
    expect(change.newQuantity, 1);
  });

  test('a price change and a stock change are both reported', () {
    final result = reconcileCart(
      [_line(1, qty: 4)],
      {1: testProduct(1, price: 12, stock: 2)},
    );

    expect(result.changes.map((c) => c.type).toSet(), {
      CartChangeType.priceChanged,
      CartChangeType.quantityReduced,
    });
    expect(result.items.single.quantity, 2);
    expect(result.items.single.unitPrice.cents, 1200);
  });

  test('a product that is out of stock is removed', () {
    final result = reconcileCart([_line(1)], {1: testProduct(1, stock: 0)});

    expect(result.items, isEmpty);
    expect(result.changes.single.type, CartChangeType.removedOutOfStock);
  });

  test('a product that no longer exists is removed', () {
    final result = reconcileCart([_line(1)], {1: null});

    expect(result.items, isEmpty);
    expect(result.changes.single.type, CartChangeType.removedUnavailable);
  });

  test('a product that could not be checked is left alone', () {
    final item = _line(1);
    final result = reconcileCart([item], <int, Product?>{});

    expect(result.items.single, same(item));
    expect(result.changes, isEmpty);
  });

  test('the order of the lines is kept', () {
    final result = reconcileCart(
      [_line(3), _line(2), _line(1)],
      {1: testProduct(1), 2: null, 3: testProduct(3, price: 11)},
    );

    expect(result.items.map((i) => i.productId), [3, 1]);
  });

  test('each change describes itself in plain words', () {
    final price = reconcileCart(
      [_line(1)],
      {1: testProduct(1, price: 12)},
    ).changes.single;
    expect(price.describe(), 'P1: price changed from \$10.00 to \$12.00.');

    final qty = reconcileCart(
      [_line(1, qty: 4)],
      {1: testProduct(1, stock: 1)},
    ).changes.single;
    expect(
      qty.describe(),
      'P1: only 1 in stock, so we reduced your quantity from 4.',
    );

    final out = reconcileCart(
      [_line(1)],
      {1: testProduct(1, stock: 0)},
    ).changes.single;
    expect(out.describe(), 'P1: out of stock, removed from your cart.');

    final gone = reconcileCart([_line(1)], {1: null}).changes.single;
    expect(gone.describe(), 'P1: no longer available, removed from your cart.');
  });
}
