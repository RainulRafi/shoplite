import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/coupon.dart';
import '../cart_provider.dart';

class CouponSection extends StatefulWidget {
  const CouponSection({super.key});

  @override
  State<CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<CouponSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply(CartProvider cart) {
    final outcome = cart.applyCoupon(_controller.text);
    if (outcome == CouponOutcome.applied) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cart = context.watch<CartProvider>();
    final stored = cart.couponCode;
    final totals = cart.totals;

    if (stored != null) {
      final working = totals.appliedCoupon != null;
      final description = Coupon.find(stored)?.description ?? '';

      return Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    working ? '$stored applied' : '$stored is not active',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: working ? c.success : c.danger,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    working ? description : (totals.couponNote ?? ''),
                    style: TextStyle(fontSize: 13, height: 1.3, color: c.muted),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: cart.removeCoupon,
              style: TextButton.styleFrom(
                foregroundColor: c.accentFg,
                minimumSize: const Size(64, 48),
              ),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) => cart.clearCouponMessage(),
                onSubmitted: (_) => _apply(cart),
                style: TextStyle(color: c.ink, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Coupon code',
                  hintStyle: TextStyle(color: c.subtle),
                  filled: true,
                  fillColor: c.field,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: c.accentFg, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () => _apply(cart),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.ink,
                side: BorderSide(color: c.border),
                minimumSize: const Size(88, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
        if (cart.couponMessage != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              cart.couponMessage!,
              style: TextStyle(fontSize: 13, height: 1.3, color: c.danger),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),

          Text(
            'Practice app: try SAVE10, WELCOME5 or FREESHIP.',
            style: TextStyle(fontSize: 13, color: c.faint),
          ),
        ],
      ],
    );
  }
}
