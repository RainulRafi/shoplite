import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/checkout_pricing.dart';

class PriceBreakdown extends StatelessWidget {
  final Money listTotal;
  final Money itemDiscount;
  final String? couponCode;
  final Money couponDiscount;
  final Money shipping;
  final Money total;

  const PriceBreakdown({
    super.key,
    required this.listTotal,
    required this.itemDiscount,
    required this.couponCode,
    required this.couponDiscount,
    required this.shipping,
    required this.total,
  });

  factory PriceBreakdown.fromTotals(CheckoutTotals t) => PriceBreakdown(
    listTotal: t.listTotal,
    itemDiscount: t.itemDiscount,
    couponCode: t.couponCode,
    couponDiscount: t.couponDiscount,
    shipping: t.shipping,
    total: t.total,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget row(
      String label,
      String value, {
      bool strong = false,
      Color? valueColor,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: strong ? 16 : 14,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                color: strong ? c.ink : c.muted,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: strong ? 18 : 14,
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? c.ink,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row('Items', listTotal.format()),
        if (!itemDiscount.isZero)
          row('Discounts', (-itemDiscount).format(), valueColor: c.success),
        if (couponCode != null && !couponDiscount.isZero)
          row(
            'Coupon $couponCode',
            (-couponDiscount).format(),
            valueColor: c.success,
          ),
        row(
          'Shipping',
          shipping.isZero ? 'Free' : shipping.format(),
          valueColor: shipping.isZero ? c.success : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: c.border),
        ),
        row('Total', total.format(), strong: true),
      ],
    );
  }
}
