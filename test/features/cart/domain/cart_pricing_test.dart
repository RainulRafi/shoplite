import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/features/cart/domain/cart_item.dart';
import 'package:shoplite/features/cart/domain/cart_pricing.dart';
import 'package:shoplite/features/cart/domain/coupon.dart';

CartItem _item({
  required int list,
  required int unit,
  int qty = 1,
  int id = 1,
}) {
  return CartItem(
    productId: id,
    title: 'P$id',
    thumbnail: '',
    listPrice: Money(list),
    unitPrice: Money(unit),
    discountPercent: 0,
    quantity: qty,
    maxQuantity: 99,
    addedAt: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

void main() {
  group('totals without a coupon', () {
    test('an empty cart is all zero', () {
      final t = CartPricing.compute([]);
      expect(t.total, Money.zero);
      expect(t.shipping, Money.zero);
      expect(t.freeShippingRemaining, Money.zero);
    });

    test('item discounts, shipping fee and the distance to free shipping', () {
      final t = CartPricing.compute([_item(list: 2000, unit: 1600, qty: 2)]);
      expect(t.listTotal.cents, 4000);
      expect(t.subtotal.cents, 3200);
      expect(t.itemDiscount.cents, 800);
      expect(t.shipping.cents, 500);
      expect(t.total.cents, 3700);
      expect(t.freeShippingRemaining.cents, 1800); // 5000 - 3200
    });

    test('shipping is free from \$50', () {
      final t = CartPricing.compute([_item(list: 3000, unit: 3000, qty: 2)]);
      expect(t.shipping, Money.zero);
      expect(t.total.cents, 6000);
      expect(t.freeShippingRemaining, Money.zero);
    });
  });

  group('coupons', () {
    final item = _item(list: 2000, unit: 1600, qty: 2); // subtotal 3200

    test('SAVE10 takes 10 percent', () {
      final t = CartPricing.compute([item], couponCode: 'SAVE10');
      expect(t.appliedCoupon, 'SAVE10');
      expect(t.couponDiscount.cents, 320);
      expect(t.shipping.cents, 500);
      expect(t.total.cents, 3380);
      expect(t.freeShippingRemaining.cents, 2120);
    });

    test('SAVE10 is capped at \$20', () {
      final big = _item(list: 15000, unit: 15000, qty: 2); // subtotal 300.00
      final t = CartPricing.compute([big], couponCode: 'SAVE10');
      expect(t.couponDiscount.cents, 2000);
      expect(t.total.cents, 28000);
    });

    test('the code is not case or space sensitive', () {
      final t = CartPricing.compute([item], couponCode: '  save10 ');
      expect(t.appliedCoupon, 'SAVE10');
    });

    test('WELCOME5 below its minimum does not apply and says why', () {
      final small = _item(list: 2500, unit: 2500);
      final t = CartPricing.compute([small], couponCode: 'WELCOME5');
      expect(t.appliedCoupon, isNull);
      expect(t.couponDiscount, Money.zero);
      expect(t.couponNote, 'Add \$5.00 more to use WELCOME5.');
      expect(t.total.cents, 3000);
    });

    test('WELCOME5 at its minimum takes \$5 off', () {
      final ok = _item(list: 3000, unit: 3000);
      final t = CartPricing.compute([ok], couponCode: 'WELCOME5');
      expect(t.couponDiscount.cents, 500);
      expect(t.total.cents, 3000);
    });

    test('FREESHIP removes the shipping fee', () {
      final small = _item(list: 2500, unit: 2500);
      final t = CartPricing.compute([small], couponCode: 'FREESHIP');
      expect(t.shipping, Money.zero);
      expect(t.freeShippingByCoupon, isTrue);
      expect(t.freeShippingRemaining, Money.zero);
      expect(t.total.cents, 2500);
    });

    test('a coupon on an empty cart is ignored', () {
      final t = CartPricing.compute([], couponCode: 'SAVE10');
      expect(t.appliedCoupon, isNull);
      expect(t.total, Money.zero);
    });

    test('an unknown code is ignored', () {
      expect(Coupon.find('NOPE'), isNull);
      final t = CartPricing.compute([item], couponCode: 'NOPE');
      expect(t.appliedCoupon, isNull);
      expect(t.total.cents, 3700);
    });
  });
}
