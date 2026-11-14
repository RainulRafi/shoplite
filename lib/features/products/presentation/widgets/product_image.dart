import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProductImage extends StatelessWidget {
  final String url;
  final String label;
  final double size;

  const ProductImage({
    super.key,
    required this.url,
    required this.label,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(10),
      ),

      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.image_outlined, color: c.subtle)
          : Image.network(
              url,
              fit: BoxFit.contain,
              semanticLabel: label,

              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),

              loadingBuilder: (context, child, progress) {
                return progress == null ? child : const SizedBox.shrink();
              },
              errorBuilder: (_, _, _) =>
                  Icon(Icons.image_not_supported_outlined, color: c.subtle),
            ),
    );
  }
}
