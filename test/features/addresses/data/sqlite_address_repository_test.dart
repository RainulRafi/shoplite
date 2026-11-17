import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/addresses/data/sqlite_address_repository.dart';
import 'package:shoplite/features/addresses/domain/address.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/test_support.dart';

Address _address(
  String name, {
  bool isDefault = false,
  int updatedAt = 1000,
  String? postal,
  String? note,
}) {
  return Address(
    label: AddressLabel.home,
    fullName: name,
    phone: '01712345678',
    division: 'Dhaka',
    district: 'Dhaka',
    area: 'Mirpur',
    line1: 'House 12, Road 4',
    postalCode: postal,
    note: note,
    isDefault: isDefault,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
  );
}

void main() {
  late Database db;
  late SqliteAddressRepository repo;
  const owner = 'user:1';

  setUp(() async {
    db = await openTestDatabase();
    repo = SqliteAddressRepository(() async => db);
  });

  tearDown(() => db.close());

  Future<List<String>> names([String who = owner]) async =>
      (await repo.loadAll(who)).map((a) => a.fullName).toList();

  Future<List<String>> defaults([String who = owner]) async =>
      (await repo.loadAll(who))
          .where((a) => a.isDefault)
          .map((a) => a.fullName)
          .toList();

  test(
    'every field survives a round trip, including empty optional ones',
    () async {
      await repo.insert(
        owner,
        _address('Full', postal: '1216', note: 'Call first'),
      );
      await repo.insert(owner, _address('Bare'));

      final all = await repo.loadAll(owner);
      final full = all.firstWhere((a) => a.fullName == 'Full');
      final bare = all.firstWhere((a) => a.fullName == 'Bare');

      expect(full.postalCode, '1216');
      expect(full.note, 'Call first');
      expect(full.division, 'Dhaka');
      expect(bare.postalCode, isNull);
      expect(bare.note, isNull);
    },
  );

  group('the default address', () {
    test('the first address becomes the default by itself', () async {
      await repo.insert(owner, _address('A'));
      expect(await defaults(), ['A']);
    });

    test('a second address is not a default unless asked', () async {
      await repo.insert(owner, _address('A'));
      await repo.insert(owner, _address('B'));
      expect(await defaults(), ['A']);
    });

    test(
      'adding a default takes the mark from the old one, and it lists first',
      () async {
        await repo.insert(owner, _address('A'));
        await repo.insert(owner, _address('B', isDefault: true));

        expect(await defaults(), ['B']);
        expect(await names(), ['B', 'A']);
      },
    );

    test('setDefault moves the mark', () async {
      final a = await repo.insert(owner, _address('A'));
      final b = await repo.insert(owner, _address('B'));

      await repo.setDefault(owner, b);
      expect(await defaults(), ['B']);

      await repo.setDefault(owner, a);
      expect(await defaults(), ['A']);
    });

    test('setDefault on an unknown id fails and changes nothing', () async {
      await repo.insert(owner, _address('A'));

      await expectLater(repo.setDefault(owner, 999), throwsA(isA<Exception>()));

      expect(await defaults(), ['A']);
    });

    test(
      'deleting the default promotes the most recently edited address',
      () async {
        final a = await repo.insert(owner, _address('A', updatedAt: 1000));
        await repo.insert(owner, _address('B', updatedAt: 2000));
        await repo.insert(owner, _address('C', updatedAt: 3000));

        await repo.delete(owner, a);

        expect(await defaults(), ['C']);
      },
    );

    test('deleting a non-default leaves the default alone', () async {
      await repo.insert(owner, _address('A'));
      final b = await repo.insert(owner, _address('B'));

      await repo.delete(owner, b);

      expect(await defaults(), ['A']);
    });

    test(
      'deleting the last address leaves an empty list without an error',
      () async {
        final a = await repo.insert(owner, _address('A'));

        await repo.delete(owner, a);

        expect(await repo.loadAll(owner), isEmpty);
      },
    );

    test(
      'unticking the default on the default address keeps one default',
      () async {
        final a = await repo.insert(owner, _address('A'));
        final loaded = (await repo.loadAll(owner)).single;
        expect(loaded.id, a);

        await repo.update(owner, loaded.copyWith(isDefault: false));

        expect(await defaults(), ['A']);
      },
    );

    test('the database itself refuses two defaults for one owner', () async {
      await repo.insert(owner, _address('A'));

      await expectLater(
        db.insert('addresses', {
          'owner_id': owner,
          'label': 'home',
          'full_name': 'Sneaky',
          'phone': '01712345678',
          'division': 'Dhaka',
          'district': 'Dhaka',
          'area': 'Mirpur',
          'line1': 'House 12, Road 4',
          'is_default': 1,
          'updated_at': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  test('editing changes only that address', () async {
    final a = await repo.insert(owner, _address('A'));
    await repo.insert(owner, _address('B'));

    final original = (await repo.loadAll(owner)).firstWhere((x) => x.id == a);
    await repo.update(
      owner,
      Address(
        id: a,
        label: AddressLabel.work,
        fullName: 'A renamed',
        phone: original.phone,
        division: 'Sylhet',
        district: 'Sylhet',
        area: 'Zindabazar',
        line1: 'Shop 3, Main road',
        isDefault: original.isDefault,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(5000),
      ),
    );

    final all = await repo.loadAll(owner);
    final edited = all.firstWhere((x) => x.id == a);
    expect(edited.fullName, 'A renamed');
    expect(edited.division, 'Sylhet');
    expect(edited.label, AddressLabel.work);
    expect(all.any((x) => x.fullName == 'B'), isTrue);
  });

  test('updating an address that does not exist fails', () async {
    await expectLater(
      repo.update(owner, _address('Ghost').copyWith(id: 999)),
      throwsA(isA<Exception>()),
    );
  });

  test('two owners never see or affect each other', () async {
    await repo.insert('user:1', _address('Mine'));
    await repo.insert('user:2', _address('Theirs'));

    expect(await names('user:1'), ['Mine']);
    expect(await names('user:2'), ['Theirs']);
    expect(await defaults('user:1'), ['Mine']);
    expect(await defaults('user:2'), ['Theirs']);
  });
}
