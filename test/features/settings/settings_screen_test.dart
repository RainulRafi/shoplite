import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/settings/data/account_data_repository.dart';
import 'package:shoplite/features/settings/presentation/settings_provider.dart';
import 'package:shoplite/features/settings/presentation/settings_screen.dart';
import 'package:provider/single_child_widget.dart';

import '../../helpers/auth_rig.dart';
import '../../helpers/widget_harness.dart';

class _Env {
  final AuthRig rig;
  final FakeSettingsRepository settingsRepo;
  final SettingsProvider settings;
  final MockAccountDataRepository accountData;

  _Env(this.rig, this.settingsRepo, this.settings, this.accountData);

  List<SingleChildWidget> get providers => [
    ChangeNotifierProvider<AuthProvider>.value(value: rig.auth),
    ChangeNotifierProvider<SettingsProvider>.value(value: settings),
    Provider<AccountDataRepository>.value(value: accountData),
  ];
}

Future<_Env> _env({required bool signedIn}) async {
  final rig = AuthRig();
  await rig.auth.restore();
  if (signedIn) await rig.signIn();
  final repo = FakeSettingsRepository();
  return _Env(rig, repo, SettingsProvider(repo), MockAccountDataRepository());
}

void main() {
  testWidgets('choosing Dark switches the theme and remembers it', (
    tester,
  ) async {
    final env = await _env(signedIn: false);
    await pumpScreen(tester, const SettingsScreen(), providers: env.providers);

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(env.settings.themeMode, ThemeMode.dark);
    expect(env.settingsRepo.values['theme_mode'], 'dark');
  });

  testWidgets(
    'a guest has no "Delete my data" option, a signed in person does',
    (tester) async {
      final guest = await _env(signedIn: false);
      await pumpScreen(
        tester,
        const SettingsScreen(),
        providers: guest.providers,
      );
      expect(find.text('Delete my data'), findsNothing);

      final signedIn = await _env(signedIn: true);
      await pumpScreen(
        tester,
        const SettingsScreen(),
        providers: signedIn.providers,
      );
      await tester.pump();
      expect(find.text('Delete my data'), findsOneWidget);
    },
  );

  testWidgets('deleting my data erases the account data and signs out', (
    tester,
  ) async {
    final env = await _env(signedIn: true);
    when(() => env.accountData.eraseOwner(any())).thenAnswer((_) async {});
    await pumpPushed(tester, const SettingsScreen(), providers: env.providers);

    await tester.tap(find.text('Delete my data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Delete my data?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete my data'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => env.accountData.eraseOwner('user:1')).called(1);
    expect(env.rig.auth.isSignedIn, isFalse);
    expect(
      find.text(
        'Your data was deleted from this phone and you were signed out.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('if erasing fails, nothing changes and you stay signed in', (
    tester,
  ) async {
    final env = await _env(signedIn: true);
    when(() => env.accountData.eraseOwner(any()))
        .thenAnswer((_) => Future.error(Exception('disk error')));
    await pumpPushed(tester, const SettingsScreen(), providers: env.providers);

    await tester.tap(find.text('Delete my data'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete my data'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(env.rig.auth.isSignedIn, isTrue);
    expect(
      find.text('Could not delete your data. Nothing was changed.'),
      findsOneWidget,
    );
  });
}
