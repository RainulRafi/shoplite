import 'package:sqflite/sqflite.dart';

import '../domain/cart_merge.dart';
import 'cart_item_mapping.dart';
import 'cart_repository.dart';
import '../domain/cart_item.dart';

class SqliteCartRepository implements CartRepository {
  final Future<Database> Function() _openDb;

  SqliteCartRepository(this._openDb);

  @override
  Future<List<CartItem>> loadItems(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'cart_items',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'added_at DESC',
    );
    return rows.map(cartItemFromRow).toList();
  }

  @override
  Future<void> saveItem(String ownerId, CartItem item) async {
    final db = await _openDb();

    await db.insert(
      'cart_items',
      item.toRow(ownerId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeItem(String ownerId, int productId) async {
    final db = await _openDb();
    await db.delete(
      'cart_items',
      where: 'owner_id = ? AND product_id = ?',
      whereArgs: [ownerId, productId],
    );
  }

  @override
  Future<String?> loadCoupon(String ownerId) async {
    final db = await _openDb();
    return _couponIn(db, ownerId);
  }

  @override
  Future<void> saveCoupon(String ownerId, String? code) async {
    final db = await _openDb();
    if (code == null) {
      await db.delete('cart_meta', where: 'owner_id = ?', whereArgs: [ownerId]);
      return;
    }
    await db.insert('cart_meta', {
      'owner_id': ownerId,
      'coupon_code': code,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> mergeGuestInto(String userOwnerId) async {
    final db = await _openDb();

    await db.transaction((txn) async {
      final guestRows = await txn.query(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [guestOwner],
      );
      final guestCoupon = await _couponIn(txn, guestOwner);
      if (guestRows.isEmpty && guestCoupon == null) return;

      final userRows = await txn.query(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [userOwnerId],
      );

      final merged = mergeCartLines(
        userRows.map(cartItemFromRow).toList(),
        guestRows.map(cartItemFromRow).toList(),
      );

      await txn.delete(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [userOwnerId],
      );
      for (final item in merged) {
        await txn.insert('cart_items', item.toRow(userOwnerId));
      }
      await txn.delete(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [guestOwner],
      );

      final userCoupon = await _couponIn(txn, userOwnerId);
      if (userCoupon == null && guestCoupon != null) {
        await txn.insert('cart_meta', {
          'owner_id': userOwnerId,
          'coupon_code': guestCoupon,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await txn.delete(
        'cart_meta',
        where: 'owner_id = ?',
        whereArgs: [guestOwner],
      );
    });
  }

  Future<String?> _couponIn(DatabaseExecutor executor, String ownerId) async {
    final rows = await executor.query(
      'cart_meta',
      columns: ['coupon_code'],
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
    if (rows.isEmpty) return null;
    return rows.first['coupon_code'] as String?;
  }
}
