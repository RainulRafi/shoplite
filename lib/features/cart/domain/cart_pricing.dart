import '../../../core/money/money.dart';
import 'cart_item.dart';
import 'coupon.dart';
import 'pricing_rules.dart';

class CartTotals {
  final Money listTotal;
  final Money itemDiscount;
  final Money subtotal; // listTotal - itemDiscount
  final Money couponDiscount;
  final Money shipping;
  final Money total;
  final Money freeShippingRemaining;
  final String? appliedCoupon;
  final String? couponNote;
  final bool freeShippingByCoupon;

  const CartTotals({
    required this.listTotal,
    required this.itemDiscount,
    required this.subtotal,
    required this.couponDiscount,
    required this.shipping,
    required this.total,
    required this.freeShippingRemaining,
    required this.appliedCoupon,
    required this.couponNote,
    required this.freeShippingByCoupon,
  });
}

class CartPricing {
  CartPricing._();

  static CartTotals compute(List<CartItem> items, {String? couponCode}) {
    var listTotal = Money.zero;
    var subtotal = Money.zero;
    for (final item in items) {
      listTotal += item.lineList;
      subtotal += item.lineTotal;
    }

    var couponDiscount = Money.zero;
    var freeByCoupon = false;
    String? applied;
    String? note;

    final coupon = couponCode == null ? null : Coupon.find(couponCode);
    if (coupon != null && items.isNotEmpty) {
      final check = coupon.check(subtotal);
      if (check.isUsable) {
        applied = coupon.code;
        couponDiscount = check.discount;
        freeByCoupon = check.freeShipping;
      } else {
        note = check.problem;
      }
    }

    final afterCoupon = subtotal - couponDiscount;
    var shipping = Money.zero;
    var remaining = Money.zero;
    if (items.isNotEmpty &&
        !freeByCoupon &&
        afterCoupon < PricingRules.freeShippingFrom) {
      shipping = PricingRules.standardShipping;
      remaining = PricingRules.freeShippingFrom - afterCoupon;
    }

    return CartTotals(
      listTotal: listTotal,
      itemDiscount: listTotal - subtotal,
      subtotal: subtotal,
      couponDiscount: couponDiscount,
      shipping: shipping,
      total: afterCoupon + shipping,
      freeShippingRemaining: remaining,
      appliedCoupon: applied,
      couponNote: note,
      freeShippingByCoupon: freeByCoupon,
    );
  }
}
