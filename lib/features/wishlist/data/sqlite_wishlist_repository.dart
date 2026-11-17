import 'package:sqflite/sqflite.dart';

import '../../../core/money/money.dart';
import '../domain/wishlist_item.dart';
import 'wishlist_repository.dart';

class SqliteWishlistRepository implements WishlistRepository {
  final Future<Database> Function() _openDb;

  SqliteWishlistRepository(this._openDb);

  @override
  Future<List<WishlistItem>> loadAll(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'wishlist_items',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'added_at DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> add(String ownerId, WishlistItem item) async {
    final db = await _openDb();
    await db.insert('wishlist_items', {
      'owner_id': ownerId,
      'product_id': item.productId,
      'title': item.title,
      'brand': item.brand,
      'thumbnail': item.thumbnail,
      'list_price_cents': item.listPrice.cents,
      'unit_price_cents': item.unitPrice.cents,
      'discount_percent': item.discountPercent,
      'added_at': item.addedAt.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> remove(String ownerId, int productId) async {
    final db = await _openDb();
    await db.delete(
      'wishlist_items',
      where: 'owner_id = ? AND product_id = ?',
      whereArgs: [ownerId, productId],
    );
  }

  WishlistItem _fromRow(Map<String, Object?> row) {
    return WishlistItem(
      productId: row['product_id'] as int,
      title: row['title'] as String,
      brand: row['brand'] as String?,
      thumbnail: row['thumbnail'] as String,
      listPrice: Money(row['list_price_cents'] as int),
      unitPrice: Money(row['unit_price_cents'] as int),
      discountPercent: (row['discount_percent'] as num).toDouble(),
      addedAt: DateTime.fromMillisecondsSinceEpoch(row['added_at'] as int),
    );
  }
}
