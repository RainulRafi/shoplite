import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool canDecrease;
  final bool canIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.canDecrease,
    required this.canIncrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) {
      return IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: Icon(icon, size: 20, color: onPressed == null ? c.subtle : c.ink),
      );
    }

    return Semantics(
      label: 'Quantity',
      value: '$quantity',
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(
              Icons.remove,
              'Decrease quantity',
              canDecrease ? onDecrease : null,
            ),
            SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
            ),
            button(
              Icons.add,
              'Increase quantity',
              canIncrease ? onIncrease : null,
            ),
          ],
        ),
      ),
    );
  }
}
