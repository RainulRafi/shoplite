import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ProductSkeletonTile extends StatelessWidget {
  const ProductSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.track,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: c.track,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(double.infinity, 14),
                const SizedBox(height: 8),
                block(140, 14),
                const SizedBox(height: 10),
                block(90, 12),
                const SizedBox(height: 14),
                block(70, 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
