import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/addresses/data/sqlite_address_repository.dart';
import 'package:shoplite/features/browsing/data/sqlite_browsing_repository.dart';
import 'package:shoplite/features/browsing/domain/viewed_product.dart';
import 'package:shoplite/features/cart/data/sqlite_cart_repository.dart';
import 'package:shoplite/features/notifications/data/sqlite_notifications_repository.dart';
import 'package:shoplite/features/orders/data/sqlite_order_repository.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/profile/data/sqlite_profile_repository.dart';
import 'package:shoplite/features/profile/domain/profile_data.dart';
import 'package:shoplite/features/reviews/data/sqlite_reviews_repository.dart';
import 'package:shoplite/features/reviews/domain/my_review.dart';
import 'package:shoplite/features/settings/data/sqlite_account_data_repository.dart';
import 'package:shoplite/features/wishlist/data/sqlite_wishlist_repository.dart';
import 'package:shoplite/features/wishlist/domain/wishlist_item.dart';
import 'package:sqflite/sqflite.dart';

import '../../helpers/order_fixtures.dart';
import '../../helpers/test_support.dart';

void main() {
  late Database db;
  late SqliteAccountDataRepository erase;

  setUp(() async {
    db = await openTestDatabase();
    erase = SqliteAccountDataRepository(() async => db);
  });

  tearDown(() => db.close());

  Future<int> count(String table, String owner) async => Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM $table WHERE owner_id = ?', [
      owner,
    ]),
  )!;

  Future<int> orderItemCount() async => Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM order_items'),
  )!;

  Future<void> seed(String owner) async {
    final product = Product(
      id: 1,
      title: 'P1',
      price: 10,
      thumbnail: 'https://x.test/1.png',
    );

    final carts = SqliteCartRepository(() async => db);
    await carts.saveItem(owner, testCartItem(1));
    await carts.saveCoupon(owner, 'SAVE10');

    await SqliteAddressRepository(() async => db).insert(owner, testAddress());
    await SqliteWishlistRepository(() async => db)
        .add(owner, WishlistItem.fromProduct(product, addedAt: t0));
    await SqliteProfileRepository(() async => db).save(
      owner,
      const ProfileOverride(firstName: 'A', lastName: 'B', phone: ''),
    );

    final browsing = SqliteBrowsingRepository(() async => db);
    await browsing.recordViewed(
      owner,
      ViewedProduct.fromProduct(product, viewedAt: t0),
      keep: 20,
    );
    await browsing.recordSearch(owner, 'phone', keep: 8);

    await SqliteReviewsRepository(() async => db).save(
      owner,
      MyReview(
        productId: 1,
        productTitle: 'P1',
        thumbnail: 'x',
        rating: 4,
        comment: 'Works well for me',
        createdAt: t0,
        updatedAt: t0,
      ),
    );
    await SqliteNotificationsRepository(() async => db)
        .markRead(owner, ['1:placed']);

    await SqliteOrderRepository(() async => db)
        .place(testRequest(ownerId: owner, key: 'key-$owner'));
    // place() Cart মুছে দেয়, তাই Cart আবার ভরি
    await carts.saveItem(owner, testCartItem(1));
    await carts.saveCoupon(owner, 'SAVE10');
  }

  test(
    'erasing one person removes every table of theirs, and nobody else',
    () async {
      await seed('user:1');
      await seed('user:2');

      // আগে নিশ্চিত হই: সব Table-এই দুজনেরই সারি আছে (নাহলে Test কিছুই প্রমাণ করে না)
      for (final table in SqliteAccountDataRepository.ownedTables) {
        expect(
          await count(table, 'user:1'),
          greaterThan(0),
          reason: 'seed missed $table',
        );
        expect(
          await count(table, 'user:2'),
          greaterThan(0),
          reason: 'seed missed $table',
        );
      }
      expect(await orderItemCount(), 2);

      await erase.eraseOwner('user:1');

      for (final table in SqliteAccountDataRepository.ownedTables) {
        expect(
          await count(table, 'user:1'),
          0,
          reason: '$table still has data',
        );
        expect(
          await count(table, 'user:2'),
          greaterThan(0),
          reason: '$table lost another person',
        );
      }
      expect(
        await orderItemCount(),
        1,
      ); // একজনের Order-এর পণ্যও গেছে, অন্যজনেরটা আছে
    },
  );

  test('the app theme setting is not personal data and stays', () async {
    await db.insert('app_settings', {'key': 'theme_mode', 'value': 'dark'});
    await seed('user:1');

    await erase.eraseOwner('user:1');

    expect(await db.query('app_settings'), hasLength(1));
  });

  test('erasing someone with no data does nothing and does not fail', () async {
    await seed('user:2');

    await erase.eraseOwner('user:9');

    expect(await count('cart_items', 'user:2'), 1);
  });

  test(
    'every table that stores a person\'s data is on the erase list',
    () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      );

      final withOwner = <String>[];
      for (final row in tables) {
        final name = row['name'] as String;
        final columns = await db.rawQuery('PRAGMA table_info($name)');
        if (columns.any((c) => c['name'] == 'owner_id')) withOwner.add(name);
      }

      expect(withOwner, isNotEmpty);
      expect(
        SqliteAccountDataRepository.ownedTables.toSet(),
        withOwner.toSet(),
        reason: 'A table with owner_id is missing from ownedTables, or the list has a stale name',
      );
    },
  );
}
