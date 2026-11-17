import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/features/cart/domain/cart_item.dart';
import 'package:shoplite/features/cart/domain/cart_merge.dart';

CartItem _item(
  int id, {
  int qty = 1,
  int max = 5,
  int unit = 900,
  int addedAt = 1000,
}) {
  return CartItem(
    productId: id,
    title: 'P$id',
    thumbnail: '',
    listPrice: const Money(1000),
    unitPrice: Money(unit),
    discountPercent: 10,
    quantity: qty,
    maxQuantity: max,
    addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
  );
}

void main() {
  test('different products are all kept', () {
    final merged = mergeCartLines([_item(1)], [_item(2)]);
    expect(merged.map((i) => i.productId).toSet(), {1, 2});
  });

  test('an empty user cart simply receives the guest items', () {
    final merged = mergeCartLines([], [_item(1, qty: 2)]);
    expect(merged.single.quantity, 2);
  });

  test('the same product adds quantities', () {
    final merged = mergeCartLines([_item(1, qty: 1)], [_item(1, qty: 2)]);
    expect(merged.single.quantity, 3);
  });

  test('the total never goes above the stock limit', () {
    final merged = mergeCartLines(
      [_item(1, qty: 4, max: 5)],
      [_item(1, qty: 3, max: 5, addedAt: 2000)],
    );
    expect(merged.single.quantity, 5);
  });

  test('the newer snapshot wins for price and title', () {
    final merged = mergeCartLines(
      [_item(1, unit: 900, addedAt: 1000)],
      [_item(1, unit: 800, addedAt: 2000)],
    );
    expect(merged.single.unitPrice.cents, 800);

    final other = mergeCartLines(
      [_item(1, unit: 900, addedAt: 3000)],
      [_item(1, unit: 800, addedAt: 2000)],
    );
    expect(other.single.unitPrice.cents, 900);
  });
}
