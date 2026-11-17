import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/order_lifecycle.dart';
import '../../domain/order_status.dart';

class OrderTimeline extends StatelessWidget {
  final List<TimelineStep> steps;

  const OrderTimeline({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _StepRow(
            step: steps[i],
            isLast: i == steps.length - 1,
            nextReached: i + 1 < steps.length && steps[i + 1].reached,
            colors: c,
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final TimelineStep step;
  final bool isLast;
  final bool nextReached;
  final AppColors colors;

  const _StepRow({
    required this.step,
    required this.isLast,
    required this.nextReached,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final cancelled = step.status == OrderStatus.cancelled;
    final dotColor = cancelled
        ? c.danger
        : (step.reached ? c.accentFg : c.subtle);

    return Semantics(
      label:
          '${step.status.title}'
          '${step.at != null ? ', ${formatTime(step.at!)}' : ''}'
          '${step.current ? ', current step' : ''}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: step.reached ? dotColor : Colors.transparent,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: nextReached ? c.accentFg : c.border,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.status.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: step.current
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: cancelled
                            ? c.danger
                            : (step.reached ? c.ink : c.faint),
                      ),
                    ),
                    if (step.at != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        formatDateTime(step.at!),
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
