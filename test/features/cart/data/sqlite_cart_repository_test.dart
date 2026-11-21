import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/database/app_database.dart';
import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/features/cart/data/cart_repository.dart';
import 'package:shoplite/features/cart/data/sqlite_cart_repository.dart';
import 'package:shoplite/features/cart/domain/cart_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

CartItem _item(
  int id, {
  int qty = 1,
  int max = 5,
  int unit = 900,
  int addedAt = 1000,
}) {
  return CartItem(
    productId: id,
    title: 'P$id',
    brand: 'B',
    thumbnail: 'https://x.test/$id.png',
    listPrice: const Money(1000),
    unitPrice: Money(unit),
    discountPercent: 10,
    quantity: qty,
    maxQuantity: max,
    addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
  );
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late SqliteCartRepository repo;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.schemaVersion,
        onConfigure: AppDatabase.configure,
        onCreate: AppDatabase.onCreate,
        onUpgrade: AppDatabase.onUpgrade,
      ),
    );
    repo = SqliteCartRepository(() async => db);
  });

  tearDown(() => db.close());

  test('the migration creates the cart tables', () async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((t) => t['name']).toSet();
    expect(names, containsAll(['cart_items', 'cart_meta']));
  });

  test('a saved item comes back with every field intact', () async {
    await repo.saveItem('guest', _item(1, qty: 2));

    final loaded = (await repo.loadItems('guest')).single;
    expect(loaded.productId, 1);
    expect(loaded.title, 'P1');
    expect(loaded.brand, 'B');
    expect(loaded.unitPrice.cents, 900);
    expect(loaded.listPrice.cents, 1000);
    expect(loaded.quantity, 2);
    expect(loaded.maxQuantity, 5);
    expect(loaded.addedAt.millisecondsSinceEpoch, 1000);
  });

  test(
    'saving the same product again replaces the line instead of adding one',
    () async {
      await repo.saveItem('guest', _item(1, qty: 1));
      await repo.saveItem('guest', _item(1, qty: 3));

      final items = await repo.loadItems('guest');
      expect(items.length, 1);
      expect(items.single.quantity, 3);
    },
  );

  test('the newest item comes first', () async {
    await repo.saveItem('guest', _item(1, addedAt: 1000));
    await repo.saveItem('guest', _item(2, addedAt: 3000));
    await repo.saveItem('guest', _item(3, addedAt: 2000));

    final ids = (await repo.loadItems('guest'))
        .map((i) => i.productId)
        .toList();
    expect(ids, [2, 3, 1]);
  });

  test('carts of different owners never mix', () async {
    await repo.saveItem('guest', _item(1));
    await repo.saveItem('user:1', _item(2));

    expect((await repo.loadItems('guest')).single.productId, 1);
    expect((await repo.loadItems('user:1')).single.productId, 2);
  });

  test('removing deletes only that line', () async {
    await repo.saveItem('guest', _item(1));
    await repo.saveItem('guest', _item(2));

    await repo.removeItem('guest', 1);

    expect((await repo.loadItems('guest')).single.productId, 2);
  });

  test('the database refuses a quantity below one', () async {
    await expectLater(
      repo.saveItem('guest', _item(1, qty: 0)),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('a coupon can be saved, replaced and cleared', () async {
    expect(await repo.loadCoupon('guest'), isNull);

    await repo.saveCoupon('guest', 'SAVE10');
    expect(await repo.loadCoupon('guest'), 'SAVE10');

    await repo.saveCoupon('guest', 'FREESHIP');
    expect(await repo.loadCoupon('guest'), 'FREESHIP');

    await repo.saveCoupon('guest', null);
    expect(await repo.loadCoupon('guest'), isNull);
  });

  group('merging the guest cart', () {
    test('moves guest lines to the user, adds quantities and empties the guest cart', () async {
      await repo.saveItem('user:1', _item(1, qty: 1, addedAt: 1000));
      await repo.saveItem(guestOwner, _item(1, qty: 2, addedAt: 2000));
      await repo.saveItem(guestOwner, _item(2, qty: 1, addedAt: 2500));

      await repo.mergeGuestInto('user:1');

      final user = {
        for (final i in await repo.loadItems('user:1')) i.productId: i.quantity,
      };
      expect(user, {1: 3, 2: 1});
      expect(await repo.loadItems(guestOwner), isEmpty);
    });

    test(
      'the guest coupon moves over, unless the user already has one',
      () async {
        await repo.saveItem(guestOwner, _item(1));
        await repo.saveCoupon(guestOwner, 'SAVE10');
        await repo.mergeGuestInto('user:1');
        expect(await repo.loadCoupon('user:1'), 'SAVE10');
        expect(await repo.loadCoupon(guestOwner), isNull);

        await repo.saveItem(guestOwner, _item(2));
        await repo.saveCoupon(guestOwner, 'FREESHIP');
        await repo.mergeGuestInto('user:1');
        expect(await repo.loadCoupon('user:1'), 'SAVE10');
      },
    );

    test('with nothing to merge, the user cart is left alone', () async {
      await repo.saveItem('user:1', _item(1, qty: 2));

      await repo.mergeGuestInto('user:1');

      expect((await repo.loadItems('user:1')).single.quantity, 2);
    });
  });
}
