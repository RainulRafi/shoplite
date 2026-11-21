import 'package:sqflite/sqflite.dart';

import 'account_data_repository.dart';

class SqliteAccountDataRepository implements AccountDataRepository {
  final Future<Database> Function() _openDb;

  SqliteAccountDataRepository(this._openDb);

  static const List<String> ownedTables = [
    'cart_items',
    'cart_meta',
    'addresses',
    'wishlist_items',
    'profile_overrides',
    'orders',
    'recently_viewed',
    'search_history',
    'my_reviews',
    'notification_reads',
  ];

  @override
  Future<void> eraseOwner(String ownerId) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      for (final table in ownedTables) {
        await txn.delete(table, where: 'owner_id = ?', whereArgs: [ownerId]);
      }
    });
  }
}
