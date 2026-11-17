import 'package:sqflite/sqflite.dart';

import '../domain/profile_data.dart';
import 'profile_repository.dart';

class SqliteProfileRepository implements ProfileRepository {
  final Future<Database> Function() _openDb;

  SqliteProfileRepository(this._openDb);

  @override
  Future<ProfileOverride?> load(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'profile_overrides',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ProfileOverride(
      firstName: row['first_name'] as String,
      lastName: row['last_name'] as String,
      phone: row['phone'] as String,
    );
  }

  @override
  Future<void> save(String ownerId, ProfileOverride override) async {
    final db = await _openDb();
    await db.insert('profile_overrides', {
      'owner_id': ownerId,
      'first_name': override.firstName,
      'last_name': override.lastName,
      'phone': override.phone,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
