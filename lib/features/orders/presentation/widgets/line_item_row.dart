import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../products/presentation/widgets/product_image.dart';

class LineItemRow extends StatelessWidget {
  final String thumbnail;
  final String title;
  final int quantity;
  final Money unitPrice;
  final Money lineTotal;
  final VoidCallback? onTap;

  const LineItemRow({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(url: thumbnail, label: title, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$quantity x ${unitPrice.format()}',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              lineTotal.format(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
