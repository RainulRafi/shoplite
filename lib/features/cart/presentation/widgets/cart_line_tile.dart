import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../products/presentation/widgets/product_image.dart';
import '../../domain/cart_item.dart';
import 'quantity_stepper.dart';

class CartLineTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onOpen;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const CartLineTile({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(url: item.thumbnail, label: item.title, size: 80),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: c.ink,
                    ),
                  ),
                  if (item.brand != null && item.brand!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.brand!,
                      style: TextStyle(fontSize: 13, color: c.muted),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        item.unitPrice.format(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                      if (item.hasDiscount)
                        Text(
                          item.listPrice.format(),
                          style: TextStyle(
                            fontSize: 13,
                            color: c.faint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      QuantityStepper(
                        quantity: item.quantity,
                        canDecrease: item.quantity > 1,
                        canIncrease: !item.atLimit,
                        onDecrease: onDecrement,
                        onIncrease: onIncrement,
                      ),
                      Text(
                        item.lineTotal.format(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                  if (item.atLimit) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Only ${item.maxQuantity} available',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.highlight,
                      ),
                    ),
                  ],
                  TextButton(
                    onPressed: onRemove,
                    style: TextButton.styleFrom(
                      foregroundColor: c.muted,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                      alignment: Alignment.centerLeft,
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
