import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/features/orders/domain/checkout_pricing.dart';
import 'package:shoplite/features/orders/domain/delivery_method.dart';

import '../../../helpers/order_fixtures.dart';

void main() {
  final small = [testCartItem(1, qty: 2, unit: 1600, list: 2000)];

  final big = [testCartItem(1, qty: 2, unit: 3000, list: 3000)];

  test('standard delivery follows the cart rule', () {
    final t = CheckoutPricing.compute(small, method: DeliveryMethod.standard);
    expect(t.subtotal.cents, 3200);
    expect(t.shipping.cents, 500);
    expect(t.total.cents, 3700);
  });

  test('standard delivery is free from fifty dollars', () {
    final t = CheckoutPricing.compute(big, method: DeliveryMethod.standard);
    expect(t.shipping, Money.zero);
    expect(t.total.cents, 6000);
  });

  test('express always costs twelve dollars, even over fifty', () {
    expect(
      CheckoutPricing.compute(
        small,
        method: DeliveryMethod.express,
      ).shipping.cents,
      1200,
    );
    expect(
      CheckoutPricing.compute(
        big,
        method: DeliveryMethod.express,
      ).shipping.cents,
      1200,
    );
    expect(
      CheckoutPricing.compute(big, method: DeliveryMethod.express).total.cents,
      7200,
    );
  });

  test('a free shipping coupon waives standard but not express', () {
    final cheap = [testCartItem(1, qty: 1, unit: 2500, list: 2500)];

    final standard = CheckoutPricing.compute(
      cheap,
      couponCode: 'FREESHIP',
      method: DeliveryMethod.standard,
    );
    expect(standard.shipping, Money.zero);
    expect(standard.total.cents, 2500);

    final express = CheckoutPricing.compute(
      cheap,
      couponCode: 'FREESHIP',
      method: DeliveryMethod.express,
    );
    expect(express.shipping.cents, 1200);
    expect(express.total.cents, 3700);
  });

  test('a percent coupon lowers the total and is reported', () {
    final t = CheckoutPricing.compute(
      small,
      couponCode: 'SAVE10',
      method: DeliveryMethod.standard,
    );
    expect(t.couponCode, 'SAVE10');
    expect(t.couponDiscount.cents, 320);
    expect(t.total.cents, 3380); // 3200 - 320 + 500
  });

  test('an empty cart costs nothing for either method', () {
    for (final method in DeliveryMethod.values) {
      final t = CheckoutPricing.compute([], method: method);
      expect(t.total, Money.zero);
      expect(t.shipping, Money.zero);
    }
  });
}
