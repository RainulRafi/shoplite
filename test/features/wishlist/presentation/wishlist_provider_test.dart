import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/state/data_status.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/wishlist/data/sqlite_wishlist_repository.dart';
import 'package:shoplite/features/wishlist/presentation/wishlist_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/test_support.dart';

Product _p(int id, {double price = 10, double discount = 0}) => Product(
  id: id,
  title: 'P$id',
  price: price,
  discountPercentage: discount,
  stock: 5,
);

void main() {
  late Database db;
  late AuthRig rig;
  late WishlistProvider wishlist;

  setUp(() async {
    db = await openTestDatabase();
    rig = AuthRig();
    await rig.auth.restore();
    wishlist = WishlistProvider(
      SqliteWishlistRepository(() async => db),
      rig.auth,
    );
  });

  tearDown(() async {
    wishlist.dispose();
    rig.dispose();
    await db.close();
  });

  test('a guest cannot save, and is told to sign in', () async {
    expect(await wishlist.toggle(_p(1)), WishlistResult.signInRequired);
    expect(wishlist.count, 0);
  });

  test('right after signing in, the first tap still works', () async {
    await rig.signIn();

    expect(await wishlist.toggle(_p(1)), WishlistResult.added);

    expect(wishlist.contains(1), isTrue);
    expect(wishlist.count, 1);
  });

  test('tapping again removes it', () async {
    await rig.signIn();
    await wishlist.toggle(_p(1));

    expect(await wishlist.toggle(_p(1)), WishlistResult.removed);

    expect(wishlist.contains(1), isFalse);
  });

  test(
    'the saved price and name are a snapshot with the sale applied',
    () async {
      await rig.signIn();
      await wishlist.toggle(_p(1, price: 20, discount: 25));

      final item = wishlist.items.single;
      expect(item.listPrice.cents, 2000);
      expect(item.unitPrice.cents, 1500);
      expect(item.hasDiscount, isTrue);
    },
  );

  test('the newest item comes first and a removed one can be restored with its time', () async {
    await rig.signIn();
    await wishlist.toggle(_p(1));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await wishlist.toggle(_p(2));
    expect(wishlist.items.map((i) => i.productId), [2, 1]);

    final removed = await wishlist.remove(2);
    expect(wishlist.items.map((i) => i.productId), [1]);

    expect(await wishlist.restore(removed!), isTrue);
    expect(wishlist.items.map((i) => i.productId), [2, 1]);
  });

  test('each person has their own wishlist, and it comes back after signing in again', () async {
    await rig.signIn();
    await wishlist.toggle(_p(1));

    await rig.auth.signOut();
    expect(wishlist.count, 0);
    expect(wishlist.contains(1), isFalse);

    await rig.signIn(testUser2);
    await waitUntil(() => wishlist.status == DataStatus.ready);
    expect(wishlist.count, 0);

    await rig.auth.signOut();
    await rig.signIn();
    await waitUntil(
      () => wishlist.status == DataStatus.ready && wishlist.count == 1,
    );
    expect(wishlist.contains(1), isTrue);
  });
}
