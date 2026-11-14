import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/product.dart';

class StockNote extends StatelessWidget {
  final Product product;
  final bool showInStock;

  const StockNote({super.key, required this.product, this.showInStock = false});

  (String, Color)? _note(AppColors c) {
    if (!product.inStock) return ('Out of stock', c.danger);
    if (product.stock <= 10) return ('Only ${product.stock} left', c.highlight);
    if (showInStock) return ('In stock', c.success);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final note = _note(c);
    if (note == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        note.$1,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: note.$2,
        ),
      ),
    );
  }
}
