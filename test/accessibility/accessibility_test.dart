import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/help/presentation/about_screen.dart';
import 'package:shoplite/features/help/presentation/help_screen.dart';

import '../helpers/widget_harness.dart';

void main() {
  for (final entry in {
    'help': const HelpScreen(),
    'about': const AboutScreen(),
  }.entries) {
    testWidgets('the ${entry.key} screen meets the accessibility guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, entry.value);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });
  }
}
