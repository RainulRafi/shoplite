import 'package:flutter/material.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';

enum PaymentOutcome { paid, failed, cancelled }

class DemoPaymentScreen extends StatelessWidget {
  final Money amount;

  const DemoPaymentScreen({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: Icon(Icons.close, color: c.ink),
          onPressed: () => Navigator.of(context).pop(PaymentOutcome.cancelled),
        ),
        centerTitle: false,
        title: Text(
          'Demo payment',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Amount', style: TextStyle(fontSize: 14, color: c.muted)),
            const SizedBox(height: 4),
            Text(
              amount.format(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'This is a practice screen standing in for a payment provider. '
                'It asks for no card details and nothing is charged. '
                'Choose how the payment should end.',
                style: TextStyle(fontSize: 14, height: 1.45, color: c.muted),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(PaymentOutcome.paid),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Pay (demo success)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(PaymentOutcome.failed),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.ink,
                side: BorderSide(color: c.border),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Simulate a failed payment'),
            ),
          ],
        ),
      ),
    );
  }
}
