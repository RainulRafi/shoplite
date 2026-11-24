import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/cart/presentation/cart_provider.dart';
import 'package:shoplite/features/cart/presentation/cart_screen.dart';
import 'package:shoplite/features/shell/shell_tabs.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/fake_cart_repository.dart';
import '../../../helpers/order_fixtures.dart';
import '../../../helpers/widget_harness.dart';

class _Env {
  final CartProvider cart;
  final ShellTabs tabs;

  _Env(this.cart, this.tabs);
}

Future<_Env> _pumpCart(WidgetTester tester) async {
  useTallScreen(tester);
  final rig = AuthRig();
  await rig.auth.restore();
  final cart = CartProvider(FakeCartRepository(), rig.auth);
  final tabs = ShellTabs();

  await pumpScreen(
    tester,
    const CartScreen(),
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: rig.auth),
      ChangeNotifierProvider<CartProvider>.value(value: cart),
      ChangeNotifierProvider<ShellTabs>.value(value: tabs),
    ],
  );
  await tester.pump();
  await tester.pump();
  return _Env(cart, tabs);
}

void main() {
  testWidgets('an empty cart explains itself and sends you shopping', (
    tester,
  ) async {
    final env = await _pumpCart(tester);

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Checkout'), findsNothing);

    await tester.tap(find.text('Browse products'));
    await tester.pump();

    expect(env.tabs.current, ShellTab.shop);
  });

  testWidgetsWithImages(
    'a cart with items shows the totals and the way to free shipping',
    (tester) async {
      final env = await _pumpCart(tester);

      env.cart.addProduct(
        testProduct(1, price: 20, stock: 5),
        quantity: 2,
      ); // $40
      await tester.pump();

      expect(find.text('P1'), findsOneWidget);
      expect(find.text('Add \$10.00 more for free shipping'), findsOneWidget);

      expect(find.text('\$45.00'), findsNWidgets(2));
      expect(find.text('Checkout'), findsOneWidget);
    },
  );

  testWidgetsWithImages('a coupon says why it failed and then applies', (
    tester,
  ) async {
    final env = await _pumpCart(tester);
    env.cart.addProduct(testProduct(1, price: 20, stock: 5), quantity: 2);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'nope');
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(find.text('That code is not valid.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'save10');
    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(find.text('SAVE10 applied'), findsOneWidget);
    expect(find.text('Coupon SAVE10'), findsOneWidget);
  });

  testWidgetsWithImages('removing an item can be undone', (tester) async {
    final env = await _pumpCart(tester);
    env.cart.addProduct(testProduct(1, price: 20, stock: 5));
    await tester.pump();

    await tester.tap(find.text('Remove'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();

    expect(find.text('P1'), findsOneWidget);
  });
}
