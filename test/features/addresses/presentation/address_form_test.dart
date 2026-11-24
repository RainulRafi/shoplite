import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/core/validation/bd_phone.dart';
import 'package:shoplite/features/addresses/presentation/address_form_screen.dart';
import 'package:shoplite/features/addresses/presentation/address_provider.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/profile/presentation/profile_provider.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/widget_harness.dart';

Future<void> _pumpForm(WidgetTester tester) async {
  useTallScreen(tester);
  final rig = AuthRig();
  await rig.auth.restore();

  await pumpScreen(
    tester,
    const AddressFormScreen(),
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: rig.auth),
      ChangeNotifierProvider<ProfileProvider>.value(
        value: ProfileProvider(MockProfileRepository(), rig.auth),
      ),
      ChangeNotifierProvider<AddressProvider>.value(
        value: AddressProvider(MockAddressRepository(), rig.auth),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'submitting an empty form shows what is missing, field by field',
    (tester) async {
      await _pumpForm(tester);

      await tester.tap(find.text('Save address'));
      await tester.pump();

      expect(find.text('Enter the recipient name'), findsOneWidget);
      expect(find.text(bdPhoneHint), findsOneWidget);
      expect(find.text('Choose a division'), findsWidgets);
      expect(find.text('Enter the district'), findsOneWidget);
      expect(find.text('Enter the area or thana'), findsOneWidget);
      expect(find.text('Enter the house, road or village'), findsOneWidget);
    },
  );

  testWidgets(
    'a phone number written with +880 is accepted, the other errors stay',
    (tester) async {
      await _pumpForm(tester);

      await tester.enterText(
        find.byType(TextFormField).at(1),
        '+880 1712-345678',
      );
      await tester.tap(find.text('Save address'));
      await tester.pump();

      expect(find.text(bdPhoneHint), findsNothing);
      expect(find.text('Enter the recipient name'), findsOneWidget);
    },
  );

  testWidgets('a wrong phone number is refused', (tester) async {
    await _pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    await tester.tap(find.text('Save address'));
    await tester.pump();

    expect(find.text(bdPhoneHint), findsOneWidget);
  });
}
