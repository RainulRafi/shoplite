import 'package:flutter/material.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../products/presentation/widgets/product_image.dart';

class ProductCard extends StatelessWidget {
  static const double width = 150;

  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context)
        .scale(1.0)
        .clamp(1.0, 1.6)
        .toDouble();
    return 172 + 84 * scale;
  }

  final String thumbnail;
  final String title;
  final Money price;
  final Money? listPrice;
  final String? badge;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.thumbnail,
    required this.title,
    required this.price,
    this.listPrice,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(url: thumbnail, label: title, size: width),
            const SizedBox(height: 10),
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
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                Text(
                  price.format(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
                if (listPrice != null)
                  Text(
                    listPrice!.format(),
                    style: TextStyle(
                      fontSize: 12,
                      color: c.faint,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
            if (badge != null) ...[
              const SizedBox(height: 2),
              Text(
                badge!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.highlight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
