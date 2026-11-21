import 'package:sqflite/sqflite.dart';

import 'notifications_repository.dart';

class SqliteNotificationsRepository implements NotificationsRepository {
  final Future<Database> Function() _openDb;

  SqliteNotificationsRepository(this._openDb);

  @override
  Future<Set<String>> loadRead(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'notification_reads',
      columns: ['notification_key'],
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
    return rows.map((r) => r['notification_key'] as String).toSet();
  }

  @override
  Future<void> markRead(String ownerId, Iterable<String> keys) async {
    final db = await _openDb();
    final batch = db.batch();
    for (final key in keys) {
      batch.insert('notification_reads', {
        'owner_id': ownerId,
        'notification_key': key,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }
}
