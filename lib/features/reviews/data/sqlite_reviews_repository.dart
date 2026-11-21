import 'package:sqflite/sqflite.dart';

import '../domain/my_review.dart';
import 'reviews_repository.dart';

class SqliteReviewsRepository implements ReviewsRepository {
  final Future<Database> Function() _openDb;

  SqliteReviewsRepository(this._openDb);

  @override
  Future<List<MyReview>> loadMine(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'my_reviews',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'updated_at DESC, rowid DESC',
    );
    return rows
        .map(
          (r) => MyReview(
            productId: r['product_id'] as int,
            productTitle: r['product_title'] as String,
            thumbnail: r['thumbnail'] as String,
            rating: r['rating'] as int,
            comment: r['comment'] as String,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              r['created_at'] as int,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              r['updated_at'] as int,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(String ownerId, MyReview review) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      final existing = await txn.query(
        'my_reviews',
        columns: ['created_at'],
        where: 'owner_id = ? AND product_id = ?',
        whereArgs: [ownerId, review.productId],
      );
      final createdAt = existing.isEmpty
          ? review.createdAt.millisecondsSinceEpoch
          : existing.first['created_at'] as int;

      await txn.insert('my_reviews', {
        'owner_id': ownerId,
        'product_id': review.productId,
        'product_title': review.productTitle,
        'thumbnail': review.thumbnail,
        'rating': review.rating,
        'comment': review.comment,
        'created_at': createdAt,
        'updated_at': review.updatedAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> delete(String ownerId, int productId) async {
    final db = await _openDb();
    await db.delete(
      'my_reviews',
      where: 'owner_id = ? AND product_id = ?',
      whereArgs: [ownerId, productId],
    );
  }
}
