import 'package:sqflite/sqflite.dart';

import '../../../core/money/money.dart';
import '../domain/viewed_product.dart';
import 'browsing_repository.dart';

class SqliteBrowsingRepository implements BrowsingRepository {
  final Future<Database> Function() _openDb;

  SqliteBrowsingRepository(this._openDb);

  @override
  Future<List<ViewedProduct>> loadViewed(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'recently_viewed',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'viewed_at DESC, rowid DESC',
    );
    return rows.map(_viewedFromRow).toList();
  }

  @override
  Future<void> recordViewed(
    String ownerId,
    ViewedProduct item, {
    required int keep,
  }) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.insert('recently_viewed', {
        'owner_id': ownerId,
        'product_id': item.productId,
        'title': item.title,
        'brand': item.brand,
        'thumbnail': item.thumbnail,
        'list_price_cents': item.listPrice.cents,
        'unit_price_cents': item.unitPrice.cents,
        'discount_percent': item.discountPercent,
        'viewed_at': item.viewedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.rawDelete(
        'DELETE FROM recently_viewed WHERE owner_id = ? AND product_id NOT IN ('
        'SELECT product_id FROM recently_viewed WHERE owner_id = ? '
        'ORDER BY viewed_at DESC, rowid DESC LIMIT ?)',
        [ownerId, ownerId, keep],
      );
    });
  }

  @override
  Future<void> clearViewed(String ownerId) async {
    final db = await _openDb();
    await db.delete(
      'recently_viewed',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
  }

  @override
  Future<List<String>> loadSearches(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'search_history',
      columns: ['term'],
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'searched_at DESC, rowid DESC',
    );
    return rows.map((r) => r['term'] as String).toList();
  }

  @override
  Future<void> recordSearch(
    String ownerId,
    String term, {
    required int keep,
  }) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.insert('search_history', {
        'owner_id': ownerId,
        'term_key': term.toLowerCase(),
        'term': term,
        'searched_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.rawDelete(
        'DELETE FROM search_history WHERE owner_id = ? AND term_key NOT IN ('
        'SELECT term_key FROM search_history WHERE owner_id = ? '
        'ORDER BY searched_at DESC, rowid DESC LIMIT ?)',
        [ownerId, ownerId, keep],
      );
    });
  }

  @override
  Future<void> removeSearch(String ownerId, String term) async {
    final db = await _openDb();
    await db.delete(
      'search_history',
      where: 'owner_id = ? AND term_key = ?',
      whereArgs: [ownerId, term.toLowerCase()],
    );
  }

  @override
  Future<void> clearSearches(String ownerId) async {
    final db = await _openDb();
    await db.delete(
      'search_history',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
  }

  ViewedProduct _viewedFromRow(Map<String, Object?> row) {
    return ViewedProduct(
      productId: row['product_id'] as int,
      title: row['title'] as String,
      brand: row['brand'] as String?,
      thumbnail: row['thumbnail'] as String,
      listPrice: Money(row['list_price_cents'] as int),
      unitPrice: Money(row['unit_price_cents'] as int),
      discountPercent: (row['discount_percent'] as num).toDouble(),
      viewedAt: DateTime.fromMillisecondsSinceEpoch(row['viewed_at'] as int),
    );
  }
}
