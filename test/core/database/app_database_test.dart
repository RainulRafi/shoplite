import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shoplite/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_support.dart';

void main() {
  test('a fresh database has every table', () async {
    final db = await openTestDatabase();
    addTearDown(db.close);

    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = rows.map((r) => r['name']).toSet();

    expect(
      names,
      containsAll([
        'cart_items',
        'cart_meta',
        'addresses',
        'wishlist_items',
        'profile_overrides',
        'app_settings',
      ]),
    );
  });

  test(
    'upgrading from version 1 keeps the cart and adds the new tables',
    () async {
      sqfliteFfiInit();
      final dir = await Directory.systemTemp.createTemp('shoplite_migration');
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'old.db');

      var db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: AppDatabase.onCreate,
        ),
      );
      await db.insert('cart_items', {
        'owner_id': 'user:1',
        'product_id': 7,
        'title': 'Old item',
        'thumbnail': 'https://x.test/7.png',
        'list_price_cents': 1000,
        'unit_price_cents': 900,
        'discount_percent': 10.0,
        'quantity': 2,
        'max_quantity': 5,
        'added_at': 1000,
      });
      await db.close();

      db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: AppDatabase.schemaVersion,
          onUpgrade: AppDatabase.onUpgrade,
        ),
      );
      addTearDown(db.close);

      final cart = await db.query('cart_items');
      expect(cart.single['title'], 'Old item');
      expect(cart.single['quantity'], 2);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      expect(
        tables.map((t) => t['name']),
        containsAll([
          'addresses',
          'wishlist_items',
          'profile_overrides',
          'app_settings',
        ]),
      );
    },
  );
}
