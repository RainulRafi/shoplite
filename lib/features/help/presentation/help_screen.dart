import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'faq_data.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Help',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(
              'FREQUENTLY ASKED QUESTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: c.faint,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in faqItems) ...[
              Divider(height: 1, color: c.border),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 16),
                expandedAlignment: Alignment.centerLeft,
                iconColor: c.accentFg,
                collapsedIconColor: c.subtle,
                shape: const Border(),
                collapsedShape: const Border(),
                title: Text(
                  item.$1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                children: [
                  Text(
                    item.$2,
                    style: TextStyle(fontSize: 14, height: 1.5, color: c.muted),
                  ),
                ],
              ),
            ],
            Divider(height: 1, color: c.border),
          ],
        ),
      ),
    );
  }
}
