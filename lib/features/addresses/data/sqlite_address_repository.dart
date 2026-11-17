import 'package:sqflite/sqflite.dart';

import '../domain/address.dart';
import 'address_repository.dart';

class SqliteAddressRepository implements AddressRepository {
  final Future<Database> Function() _openDb;

  SqliteAddressRepository(this._openDb);

  @override
  Future<List<Address>> loadAll(String ownerId) async {
    final db = await _openDb();
    final rows = await db.query(
      'addresses',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'is_default DESC, updated_at DESC, id DESC',
    );
    return rows.map(_fromRow).toList();
  }

  @override
  Future<int> insert(String ownerId, Address address) async {
    final db = await _openDb();
    return db.transaction((txn) async {
      final existing = await _count(txn, ownerId);

      final makeDefault = address.isDefault || existing == 0;
      if (makeDefault) {
        await txn.update(
          'addresses',
          {'is_default': 0},
          where: 'owner_id = ?',
          whereArgs: [ownerId],
        );
      }
      return txn.insert(
        'addresses',
        _toRow(ownerId, address, isDefault: makeDefault),
      );
    });
  }

  @override
  Future<void> update(String ownerId, Address address) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      if (address.isDefault) {
        await txn.update(
          'addresses',
          {'is_default': 0},
          where: 'owner_id = ? AND id != ?',
          whereArgs: [ownerId, address.id],
        );
      }
      final changed = await txn.update(
        'addresses',
        _toRow(ownerId, address),
        where: 'id = ? AND owner_id = ?',
        whereArgs: [address.id, ownerId],
      );

      if (changed == 0) throw Exception('Address ${address.id} was not found');
      await _ensureDefault(txn, ownerId);
    });
  }

  @override
  Future<void> delete(String ownerId, int id) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete(
        'addresses',
        where: 'id = ? AND owner_id = ?',
        whereArgs: [id, ownerId],
      );
      await _ensureDefault(txn, ownerId);
    });
  }

  @override
  Future<void> setDefault(String ownerId, int id) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
        'SELECT COUNT(*) FROM addresses WHERE id = ? AND owner_id = ?',
        [id, ownerId],
      );
      if ((Sqflite.firstIntValue(rows) ?? 0) == 0) {
        throw Exception('Address $id was not found');
      }

      await txn.update(
        'addresses',
        {'is_default': 0},
        where: 'owner_id = ?',
        whereArgs: [ownerId],
      );
      await txn.update(
        'addresses',
        {'is_default': 1},
        where: 'id = ? AND owner_id = ?',
        whereArgs: [id, ownerId],
      );
    });
  }

  Future<int> _count(DatabaseExecutor db, String ownerId) async {
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM addresses WHERE owner_id = ?',
      [ownerId],
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> _ensureDefault(DatabaseExecutor db, String ownerId) async {
    if (await _count(db, ownerId) == 0) return;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM addresses WHERE owner_id = ? AND is_default = 1',
      [ownerId],
    );
    if ((Sqflite.firstIntValue(rows) ?? 0) > 0) return;

    await db.rawUpdate(
      'UPDATE addresses SET is_default = 1 WHERE id = ('
      'SELECT id FROM addresses WHERE owner_id = ? '
      'ORDER BY updated_at DESC, id DESC LIMIT 1)',
      [ownerId],
    );
  }

  Map<String, Object?> _toRow(String ownerId, Address a, {bool? isDefault}) => {
    'owner_id': ownerId,
    'label': a.label.name,
    'full_name': a.fullName,
    'phone': a.phone,
    'division': a.division,
    'district': a.district,
    'area': a.area,
    'line1': a.line1,
    'postal_code': a.postalCode,
    'note': a.note,
    'is_default': (isDefault ?? a.isDefault) ? 1 : 0,
    'updated_at': a.updatedAt.millisecondsSinceEpoch,
  };

  Address _fromRow(Map<String, Object?> row) {
    return Address(
      id: row['id'] as int,
      label: AddressLabel.fromName(row['label'] as String?),
      fullName: row['full_name'] as String,
      phone: row['phone'] as String,
      division: row['division'] as String,
      district: row['district'] as String,
      area: row['area'] as String,
      line1: row['line1'] as String,
      postalCode: row['postal_code'] as String?,
      note: row['note'] as String?,
      isDefault: (row['is_default'] as int) == 1,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}
