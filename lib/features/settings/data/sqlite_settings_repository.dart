import 'package:sqflite/sqflite.dart';

import 'settings_repository.dart';

class SqliteSettingsRepository implements SettingsRepository {
  final Future<Database> Function() _openDb;

  SqliteSettingsRepository(this._openDb);

  @override
  Future<String?> read(String key) async {
    final db = await _openDb();
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  @override
  Future<void> write(String key, String value) async {
    final db = await _openDb();
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
