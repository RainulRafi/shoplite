import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/browsing/data/sqlite_browsing_repository.dart';
import 'package:shoplite/features/browsing/domain/viewed_product.dart';
import 'package:shoplite/features/browsing/presentation/browsing_provider.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/auth_rig.dart';
import '../../helpers/test_support.dart';

ViewedProduct _viewed(int id, int at) => ViewedProduct.fromProduct(
  Product(
    id: id,
    title: 'P$id',
    price: 10,
    thumbnail: 'https://x.test/$id.png',
  ),
  viewedAt: DateTime.fromMillisecondsSinceEpoch(at),
);

void main() {
  late Database db;
  late SqliteBrowsingRepository repo;

  setUp(() async {
    db = await openTestDatabase();
    repo = SqliteBrowsingRepository(() async => db);
  });

  tearDown(() => db.close());

  group('recently viewed in the database', () {
    test('the newest comes first and every field survives', () async {
      await repo.recordViewed('guest', _viewed(1, 1000), keep: 20);
      await repo.recordViewed('guest', _viewed(2, 2000), keep: 20);

      final list = await repo.loadViewed('guest');

      expect(list.map((v) => v.productId), [2, 1]);
      expect(list.first.title, 'P2');
      expect(list.first.unitPrice.cents, 1000);
      expect(list.first.thumbnail, 'https://x.test/2.png');
      expect(list.first.viewedAt.millisecondsSinceEpoch, 2000);
    });

    test('viewing the same product again moves it to the front without a duplicate', () async {
      await repo.recordViewed('guest', _viewed(1, 1000), keep: 20);
      await repo.recordViewed('guest', _viewed(2, 2000), keep: 20);
      await repo.recordViewed('guest', _viewed(1, 3000), keep: 20);

      final list = await repo.loadViewed('guest');

      expect(list.map((v) => v.productId), [1, 2]);
    });

    test('only the newest few are kept', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.recordViewed('guest', _viewed(i, i * 1000), keep: 3);
      }

      final list = await repo.loadViewed('guest');

      expect(list.map((v) => v.productId), [5, 4, 3]);
    });

    test(
      'each owner has a separate history, and clearing touches only one',
      () async {
        await repo.recordViewed('guest', _viewed(1, 1000), keep: 20);
        await repo.recordViewed('user:1', _viewed(2, 2000), keep: 20);

        expect((await repo.loadViewed('guest')).single.productId, 1);
        expect((await repo.loadViewed('user:1')).single.productId, 2);

        await repo.clearViewed('guest');
        expect(await repo.loadViewed('guest'), isEmpty);
        expect(await repo.loadViewed('user:1'), hasLength(1));
      },
    );
  });

  group('search history in the database', () {
    test('the newest search comes first', () async {
      await repo.recordSearch('guest', 'phone', keep: 8);
      await Future<void>.delayed(const Duration(milliseconds: 3));
      await repo.recordSearch('guest', 'laptop', keep: 8);

      expect(await repo.loadSearches('guest'), ['laptop', 'phone']);
    });

    test('the same word in a different case is one entry, with the latest spelling', () async {
      await repo.recordSearch('guest', 'phone', keep: 8);
      await Future<void>.delayed(const Duration(milliseconds: 3));
      await repo.recordSearch('guest', 'Phone', keep: 8);

      expect(await repo.loadSearches('guest'), ['Phone']);
    });

    test('only the newest few are kept', () async {
      for (var i = 1; i <= 5; i++) {
        await repo.recordSearch('guest', 'term $i', keep: 3);
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }

      expect(await repo.loadSearches('guest'), ['term 5', 'term 4', 'term 3']);
    });

    test(
      'removing is case-insensitive and clearing empties the owner list only',
      () async {
        await repo.recordSearch('guest', 'Phone', keep: 8);
        await repo.recordSearch('user:1', 'chair', keep: 8);

        await repo.removeSearch('guest', 'phone');
        expect(await repo.loadSearches('guest'), isEmpty);

        await repo.clearSearches('guest');
        expect(await repo.loadSearches('user:1'), ['chair']);
      },
    );
  });

  group('the provider', () {
    late AuthRig rig;
    late BrowsingProvider browsing;

    setUp(() async {
      rig = AuthRig();
      await rig.auth.restore();
      browsing = BrowsingProvider(repo, rig.auth);
      await waitUntil(() => browsing.searches.isEmpty);
    });

    tearDown(() {
      browsing.dispose();
      rig.dispose();
    });

    test('a view shows at once and is saved afterwards', () async {
      browsing.recordView(Product(id: 1, title: 'P1', price: 10));

      expect(browsing.viewed.single.productId, 1);

      await browsing.flush();
      expect((await repo.loadViewed('guest')).single.productId, 1);
    });

    test(
      'viewing again moves it to the front and the list is capped',
      () async {
        for (var i = 1; i <= BrowsingProvider.maxViewed + 3; i++) {
          browsing.recordView(Product(id: i, title: 'P$i', price: 10));
        }
        browsing.recordView(Product(id: 10, title: 'P10', price: 10));

        expect(browsing.viewed.first.productId, 10);
        expect(browsing.viewed.length, BrowsingProvider.maxViewed);
        expect(
          browsing.viewed.map((v) => v.productId).toSet().length,
          BrowsingProvider.maxViewed,
        );
      },
    );

    test('searches shorter than two characters are not kept', () async {
      browsing.recordSearch('a');
      browsing.recordSearch('   ');
      browsing.recordSearch(' phone ');

      expect(browsing.searches, ['phone']);
      await browsing.flush();
      expect(await repo.loadSearches('guest'), ['phone']);
    });

    test('a search can be removed or all cleared', () async {
      browsing.recordSearch('phone');
      browsing.recordSearch('laptop');

      browsing.removeSearch('phone');
      expect(browsing.searches, ['laptop']);

      browsing.clearSearches();
      expect(browsing.searches, isEmpty);
      await browsing.flush();
      expect(await repo.loadSearches('guest'), isEmpty);
    });

    test('a guest and a signed in person have separate histories', () async {
      browsing.recordView(Product(id: 1, title: 'Guest view', price: 10));
      browsing.recordSearch('guest search');
      await browsing.flush();

      await rig.signIn();
      await waitUntil(
        () => browsing.viewed.isEmpty && browsing.searches.isEmpty,
      );
      browsing.recordView(Product(id: 2, title: 'User view', price: 10));
      await browsing.flush();
      expect(browsing.viewed.map((v) => v.productId), [2]);

      await rig.auth.signOut();
      await waitUntil(() => browsing.viewed.isNotEmpty);
      expect(browsing.viewed.map((v) => v.productId), [1]);
      expect(browsing.searches, ['guest search']);
    });
  });
}
