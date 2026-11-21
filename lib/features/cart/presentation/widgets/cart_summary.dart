import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/cart_pricing.dart';
import '../../domain/pricing_rules.dart';

class CartSummary extends StatelessWidget {
  final CartTotals totals;

  const CartSummary({super.key, required this.totals});

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

    final progress =
        1 -
        totals.freeShippingRemaining.cents /
            PricingRules.freeShippingFrom.cents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totals.freeShippingRemaining.cents > 0) ...[
          Text(
            'Add ${totals.freeShippingRemaining.format()} more for free shipping',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              color: c.accentFg,
              backgroundColor: c.track,
            ),
          ),
          const SizedBox(height: 16),
        ],
        row('Items', totals.listTotal.format()),
        if (!totals.itemDiscount.isZero)
          row(
            'Discounts',
            (-totals.itemDiscount).format(),
            valueColor: c.success,
          ),
        if (totals.appliedCoupon != null && !totals.couponDiscount.isZero)
          row(
            'Coupon ${totals.appliedCoupon}',
            (-totals.couponDiscount).format(),
            valueColor: c.success,
          ),
        row(
          'Shipping',
          totals.shipping.isZero ? 'Free' : totals.shipping.format(),
          valueColor: totals.shipping.isZero ? c.success : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: c.border),
        ),
        row('Total', totals.total.format(), strong: true),
      ],
    );
  }
}
