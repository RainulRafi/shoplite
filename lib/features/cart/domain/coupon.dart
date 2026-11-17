import '../../../core/money/money.dart';

class CouponCheck {
  final Money discount;
  final bool freeShipping;
  final String? problem;

  const CouponCheck.ok({this.discount = Money.zero, this.freeShipping = false})
    : problem = null;

  const CouponCheck.rejected(String message)
    : problem = message,
      discount = Money.zero,
      freeShipping = false;

  bool get isUsable => problem == null;
}

class Coupon {
  final String code;
  final String description;
  final Money minSubtotal;
  final int percentOff;
  final Money? maxDiscount;
  final Money amountOff;
  final bool freeShipping;

  const Coupon({
    required this.code,
    required this.description,
    this.minSubtotal = Money.zero,
    this.percentOff = 0,
    this.maxDiscount,
    this.amountOff = Money.zero,
    this.freeShipping = false,
  });

  static const List<Coupon> all = [
    Coupon(
      code: 'SAVE10',
      description: '10% off, up to \$20',
      percentOff: 10,
      maxDiscount: Money(2000),
    ),
    Coupon(
      code: 'WELCOME5',
      description: '\$5 off orders over \$30',
      amountOff: Money(500),
      minSubtotal: Money(3000),
    ),
    Coupon(
      code: 'FREESHIP',
      description: 'Free shipping on orders over \$20',
      freeShipping: true,
      minSubtotal: Money(2000),
    ),
  ];

  static Coupon? find(String raw) {
    final code = raw.trim().toUpperCase();
    for (final coupon in all) {
      if (coupon.code == code) return coupon;
    }
    return null;
  }

  CouponCheck check(Money subtotal) {
    if (subtotal < minSubtotal) {
      return CouponCheck.rejected(
        'Add ${(minSubtotal - subtotal).format()} more to use $code.',
      );
    }

    var discount = amountOff;
    if (percentOff > 0) {
      discount = subtotal.percent(percentOff);
      final cap = maxDiscount;
      if (cap != null && discount > cap) discount = cap;
    }

    if (discount > subtotal) discount = subtotal;

    return CouponCheck.ok(discount: discount, freeShipping: freeShipping);
  }
}
