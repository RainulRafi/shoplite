import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shoplite/core/database/app_database.dart';
import 'package:shoplite/features/addresses/data/sqlite_address_repository.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/browsing/data/sqlite_browsing_repository.dart';
import 'package:shoplite/features/cart/data/sqlite_cart_repository.dart';
import 'package:shoplite/features/notifications/data/sqlite_notifications_repository.dart';
import 'package:shoplite/features/orders/data/sqlite_order_repository.dart';
import 'package:shoplite/features/profile/data/sqlite_profile_repository.dart';
import 'package:shoplite/features/reviews/data/sqlite_reviews_repository.dart';
import 'package:shoplite/features/settings/data/sqlite_account_data_repository.dart';
import 'package:shoplite/features/settings/data/sqlite_settings_repository.dart';
import 'package:shoplite/features/settings/presentation/settings_provider.dart';
import 'package:shoplite/features/wishlist/data/sqlite_wishlist_repository.dart';
import 'package:shoplite/main.dart';
import 'package:sqflite/sqflite.dart';

import '../test/helpers/fake_token_store.dart';
import '../test/helpers/order_fixtures.dart';
import 'fake_backend.dart';

Future<Database> _openMemoryDb() => openDatabase(
  inMemoryDatabasePath,
  version: AppDatabase.schemaVersion,
  onConfigure: AppDatabase.configure,
  onCreate: AppDatabase.onCreate,
  onUpgrade: AppDatabase.onUpgrade,
);

Future<AppDependencies> _buildDeps(Database db) async {
  Future<Database> open() async => db;

  final auth = AuthProvider(
    FakeAuthRepository(),
    FakeTokenStore(testTokens, 1),
  );
  await auth.restore();

  final settings = SettingsProvider(SqliteSettingsRepository(open));
  await settings.load();

  await SqliteAddressRepository(open)
      .insert('user:1', testAddress(isDefault: true));

  return AppDependencies(
    products: FakeBackend(),
    carts: SqliteCartRepository(open),
    addresses: SqliteAddressRepository(open),
    wishlist: SqliteWishlistRepository(open),
    profile: SqliteProfileRepository(open),
    orders: SqliteOrderRepository(open),
    browsing: SqliteBrowsingRepository(open),
    reviews: SqliteReviewsRepository(open),
    notifications: SqliteNotificationsRepository(open),
    accountData: SqliteAccountDataRepository(open),
    auth: auth,
    settings: settings,
  );
}

Finder _tab(String label) => find.descendant(
  of: find.byType(BottomNavigationBar),
  matching: find.text(label),
);

Future<void> _tap(WidgetTester tester, Finder finder, String what) async {
  expect(finder, findsOneWidget, reason: 'could not find exactly one: $what');
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'a shopper can browse, add to the cart, check out and find the order',
    (tester) async {
      await mockNetworkImagesFor(() async {
        final db = await _openMemoryDb();
        addTearDown(db.close);
        final deps = await _buildDeps(db);

        await tester.pumpWidget(ShopLiteApp(deps: deps));
        await tester.pumpAndSettle();

        expect(find.text('ShopLite'), findsOneWidget);

        await _tap(tester, _tab('Shop'), 'the Shop tab');
        await _tap(tester, find.text('Walnut Desk'), 'Walnut Desk in the list');

        await _tap(tester, find.text('Add to cart'), 'the Add to cart button');
        expect(find.text('Added to your cart.'), findsOneWidget);
        await _tap(tester, find.text('View cart'), 'the View cart action');

        expect(find.text('Walnut Desk'), findsOneWidget);
        await _tap(tester, find.text('Checkout'), 'the Checkout button');

        expect(find.text('Rahim Uddin'), findsOneWidget);
        await _tap(tester, find.text('Place order'), 'the Place order button');

        expect(find.text('Order placed'), findsOneWidget);
        expect(find.textContaining('SL-'), findsOneWidget);

        await _tap(tester, find.text('View order'), 'the View order button');
        expect(find.text('PROGRESS'), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        await _tap(tester, _tab('Cart'), 'the Cart tab');
        expect(find.text('Your cart is empty'), findsOneWidget);

        await _tap(tester, _tab('Account'), 'the Account tab');
        await _tap(tester, find.text('My orders'), 'the My orders row');
        expect(find.textContaining('SL-'), findsOneWidget);
      });
    },
  );
}
