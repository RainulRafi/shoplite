import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/price_format.dart';
import '../../../../core/utils/text_format.dart';
import '../../data/product.dart';
import 'product_image.dart';
import 'stock_note.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductTile({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final subtitle = product.brand ?? prettyCategory(product.category);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(url: product.thumbnail, label: product.title),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: c.ink,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: c.muted),
                    ),
                  ],
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        formatPrice(
                          product.hasDiscount
                              ? product.discountedPrice
                              : product.price,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        ),
                      ),
                      if (product.hasDiscount) ...[
                        Text(
                          formatPrice(product.price),
                          style: TextStyle(
                            fontSize: 13,
                            color: c.faint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '${product.discountPercentage.round()}% off',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: c.highlight,
                          ),
                        ),
                      ],
                    ],
                  ),

                  StockNote(product: product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
