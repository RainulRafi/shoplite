import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/core/storage/token_store.dart';
import 'package:shoplite/features/auth/data/auth_session.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/auth/presentation/login_screen.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/widget_harness.dart';

class _Outcome {
  bool? value;
  bool popped = false;
}

class _Opened {
  final AuthRig rig;
  final _Outcome outcome;

  _Opened(this.rig, this.outcome);
}

Future<_Opened> _open(WidgetTester tester) async {
  useTallScreen(tester);
  final rig = AuthRig();
  await rig.auth.restore();
  final outcome = _Outcome();

  await pumpScreen(
    tester,
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              outcome.value = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) =>
                      const LoginScreen(reason: 'Sign in to check out.'),
                ),
              );
              outcome.popped = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
    providers: [ChangeNotifierProvider<AuthProvider>.value(value: rig.auth)],
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return _Opened(rig, outcome);
}

String _fieldText(WidgetTester tester, int index) => tester
    .widget<TextFormField>(find.byType(TextFormField).at(index))
    .controller!
    .text;

void main() {
  testWidgets(
    'it says why you are being asked to sign in and offers the demo account',
    (tester) async {
      await _open(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in to check out.'), findsOneWidget);
      expect(find.text('Fill in demo account'), findsOneWidget);
      expect(find.text('Continue browsing'), findsOneWidget);
    },
  );

  testWidgets('submitting empty fields shows what is missing', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets(
    'the demo account button fills both fields and clears old errors',
    (tester) async {
      await _open(tester);
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(find.text('Enter your username'), findsOneWidget);

      await tester.tap(find.text('Fill in demo account'));
      await tester.pump();

      expect(_fieldText(tester, 0), 'emilys');
      expect(_fieldText(tester, 1), 'emilyspass');
      expect(find.text('Enter your username'), findsNothing);
    },
  );

  testWidgets('the password is hidden until you ask to see it', (tester) async {
    await _open(tester);

    bool obscured() => tester
        .widget<EditableText>(
          find.descendant(
            of: find.byType(TextFormField).at(1),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    expect(obscured(), isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(obscured(), isFalse);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(obscured(), isTrue);
  });

  testWidgets('a wrong password shows the message and keeps the screen open', (
    tester,
  ) async {
    final env = await _open(tester);
    when(
      () => env.rig.repo.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer(
      (_) => Future<AuthSession>.error(const ApiException.invalidCredentials()),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'emilys');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect username or password.'), findsOneWidget);
    expect(env.outcome.popped, isFalse);
    expect(env.rig.auth.isSignedIn, isFalse);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets(
    'a good sign in closes the screen with true and signs the person in',
    (tester) async {
      final env = await _open(tester);
      when(
        () => env.rig.repo.login(
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => AuthSession(
          tokens: const AuthTokens(accessToken: 'A', refreshToken: 'R'),
          user: testUser,
        ),
      );

      await tester.tap(find.text('Fill in demo account'));
      await tester.pump();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(env.outcome.popped, isTrue);
      expect(env.outcome.value, isTrue);
      expect(env.rig.auth.isSignedIn, isTrue);
    },
  );

  testWidgets('closing and "Continue browsing" both return false', (
    tester,
  ) async {
    final closed = await _open(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(closed.outcome.value, isFalse);

    final browsing = await _open(tester);
    await tester.tap(find.text('Continue browsing'));
    await tester.pumpAndSettle();
    expect(browsing.outcome.value, isFalse);
  });

  testWidgets('the login screen meets the accessibility guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _open(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    handle.dispose();
  });
}
