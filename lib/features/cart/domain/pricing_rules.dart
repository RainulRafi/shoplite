import '../../../core/money/money.dart';

class PricingRules {
  PricingRules._();

  static const Money standardShipping = Money(500); // $5.00
  static const Money expressShipping = Money(1200); // $12.00, কখনো ফ্রি না
  static const Money freeShippingFrom = Money(5000);
}
