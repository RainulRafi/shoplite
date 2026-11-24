import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/features/auth/presentation/account_screen.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/settings/presentation/settings_provider.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/widget_harness.dart';

Future<void> _pumpAccount(WidgetTester tester) async {
  useTallScreen(tester);
  final rig = AuthRig();
  await rig.auth.restore();

  await pumpScreen(
    tester,
    const AccountScreen(),
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: rig.auth),
      ChangeNotifierProvider<SettingsProvider>.value(
        value: SettingsProvider(FakeSettingsRepository()),
      ),
    ],
  );
  await tester.pump();
}

void main() {
  testWidgets('the Settings row opens the real settings screen', (
    tester,
  ) async {
    await _pumpAccount(tester);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('APPEARANCE'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
  });

  testWidgets('the Help row opens the FAQ', (tester) async {
    await _pumpAccount(tester);

    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();

    expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
  });

  testWidgets('the About row opens the about and legal screen', (tester) async {
    await _pumpAccount(tester);

    await tester.tap(find.text('About and legal'));
    await tester.pumpAndSettle();

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
  });
}
