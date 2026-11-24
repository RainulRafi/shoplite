import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/reviews/presentation/my_reviews_provider.dart';
import 'package:shoplite/features/reviews/presentation/review_form_screen.dart';

import '../../helpers/auth_rig.dart';
import '../../helpers/widget_harness.dart';

Future<void> _pumpForm(WidgetTester tester) async {
  useTallScreen(tester);
  final rig = AuthRig();
  await rig.auth.restore();

  await pumpScreen(
    tester,
    const ReviewFormScreen(
      productId: 7,
      productTitle: 'Walnut Desk',
      thumbnail: '',
    ),
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: rig.auth),
      ChangeNotifierProvider<MyReviewsProvider>.value(
        value: MyReviewsProvider(MockReviewsRepository(), rig.auth),
      ),
    ],
  );
}

void main() {
  testWidgets('a review needs a star rating and a real comment', (
    tester,
  ) async {
    await _pumpForm(tester);

    await tester.tap(find.text('Save review'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a star rating'), findsOneWidget);
    expect(find.textContaining('Write at least'), findsOneWidget);
  });

  testWidgets(
    'choosing a rating clears its error but the comment error stays',
    (tester) async {
      await _pumpForm(tester);

      await tester.tap(find.text('Save review'));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.star_border).at(3));
      await tester.pump();
      expect(find.text('Choose a star rating'), findsNothing);
      expect(find.byIcon(Icons.star), findsNWidgets(4));

      await tester.tap(find.text('Save review'));
      await tester.pump();
      expect(find.text('Write at least 10 characters'), findsOneWidget);
    },
  );
}
