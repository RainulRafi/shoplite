import '../../../core/money/money.dart';
import '../../cart/domain/cart_item.dart';
import '../../cart/domain/cart_pricing.dart';
import '../../cart/domain/pricing_rules.dart';
import 'delivery_method.dart';

class CheckoutTotals {
  final Money listTotal;
  final Money itemDiscount;
  final Money subtotal;
  final String? couponCode;
  final Money couponDiscount;
  final Money shipping;
  final Money total;

  const CheckoutTotals({
    required this.listTotal,
    required this.itemDiscount,
    required this.subtotal,
    required this.couponCode,
    required this.couponDiscount,
    required this.shipping,
    required this.total,
  });
}

class CheckoutPricing {
  CheckoutPricing._();

  static CheckoutTotals compute(
    List<CartItem> items, {
    String? couponCode,
    required DeliveryMethod method,
  }) {
    final base = CartPricing.compute(items, couponCode: couponCode);
    final afterCoupon = base.subtotal - base.couponDiscount;

    final shipping = switch (method) {
      DeliveryMethod.standard => base.shipping,
      DeliveryMethod.express =>
        items.isEmpty ? Money.zero : PricingRules.expressShipping,
    };

    return CheckoutTotals(
      listTotal: base.listTotal,
      itemDiscount: base.itemDiscount,
      subtotal: base.subtotal,
      couponCode: base.appliedCoupon,
      couponDiscount: base.couponDiscount,
      shipping: shipping,
      total: afterCoupon + shipping,
    );
  }
}
