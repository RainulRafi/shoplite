import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/core/state/data_status.dart';
import 'package:shoplite/features/products/data/product_repository.dart';
import 'package:shoplite/features/products/data/product_review.dart';
import 'package:shoplite/features/reviews/data/sqlite_reviews_repository.dart';
import 'package:shoplite/features/reviews/domain/my_review.dart';
import 'package:shoplite/features/reviews/presentation/my_reviews_provider.dart';
import 'package:shoplite/features/reviews/presentation/product_reviews_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/auth_rig.dart';
import '../../helpers/test_support.dart';

class MockProductRepository extends Mock implements ProductRepository {}

MyReview _review(
  int productId, {
  int rating = 4,
  String comment = 'Works well for me',
  int at = 1000,
}) => MyReview(
  productId: productId,
  productTitle: 'P$productId',
  thumbnail: 'https://x.test/$productId.png',
  rating: rating,
  comment: comment,
  createdAt: DateTime.fromMillisecondsSinceEpoch(at),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(at),
);

void main() {
  group('my reviews in the database', () {
    late Database db;
    late SqliteReviewsRepository repo;

    setUp(() async {
      db = await openTestDatabase();
      repo = SqliteReviewsRepository(() async => db);
    });

    tearDown(() => db.close());

    test('a saved review comes back with every field', () async {
      await repo.save(
        'user:1',
        _review(7, rating: 5, comment: 'Loved it, would buy again'),
      );

      final r = (await repo.loadMine('user:1')).single;
      expect(r.productId, 7);
      expect(r.productTitle, 'P7');
      expect(r.thumbnail, 'https://x.test/7.png');
      expect(r.rating, 5);
      expect(r.comment, 'Loved it, would buy again');
    });

    test(
      'editing replaces the review and keeps the first written time',
      () async {
        await repo.save('user:1', _review(7, rating: 3, at: 1000));
        await repo.save(
          'user:1',
          _review(7, rating: 5, comment: 'Changed my mind a lot', at: 9000),
        );

        final all = await repo.loadMine('user:1');
        expect(all, hasLength(1));
        expect(all.single.rating, 5);
        expect(all.single.createdAt.millisecondsSinceEpoch, 1000);
        expect(all.single.updatedAt.millisecondsSinceEpoch, 9000);
      },
    );

    test('the most recently edited comes first', () async {
      await repo.save('user:1', _review(1, at: 1000));
      await repo.save('user:1', _review(2, at: 3000));
      await repo.save('user:1', _review(3, at: 2000));

      expect((await repo.loadMine('user:1')).map((r) => r.productId), [
        2,
        3,
        1,
      ]);
    });

    test(
      'each person has their own reviews and deleting touches only one',
      () async {
        await repo.save('user:1', _review(7));
        await repo.save(
          'user:2',
          _review(7, rating: 1, comment: 'Did not like it at all'),
        );

        await repo.delete('user:1', 7);

        expect(await repo.loadMine('user:1'), isEmpty);
        expect((await repo.loadMine('user:2')).single.rating, 1);
      },
    );

    test('the database refuses a rating outside one to five', () async {
      await expectLater(
        repo.save('user:1', _review(7, rating: 6)),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('my reviews provider', () {
    late Database db;
    late AuthRig rig;
    late MyReviewsProvider provider;

    setUp(() async {
      db = await openTestDatabase();
      rig = AuthRig();
      await rig.auth.restore();
      provider = MyReviewsProvider(
        SqliteReviewsRepository(() async => db),
        rig.auth,
      );
    });

    tearDown(() async {
      provider.dispose();
      rig.dispose();
      await db.close();
    });

    Future<ReviewResult> save({
      int productId = 7,
      int? rating = 4,
      String comment = 'Works well for me',
    }) => provider.save(
      productId: productId,
      productTitle: 'P$productId',
      thumbnail: 'https://x.test/$productId.png',
      rating: rating,
      comment: comment,
    );

    Future<void> signIn([dynamic user]) async {
      await rig.signIn(user ?? testUser);
      await waitUntil(() => provider.status == DataStatus.ready);
    }

    test('a guest cannot write a review', () async {
      expect(await save(), ReviewResult.notSignedIn);
      expect(provider.reviews, isEmpty);
    });

    test('invalid input is refused and nothing is saved', () async {
      await signIn();

      expect(await save(rating: null), ReviewResult.invalid);
      expect(await save(rating: 6), ReviewResult.invalid);
      expect(await save(comment: 'short'), ReviewResult.invalid);
      expect(provider.reviews, isEmpty);
    });

    test('saving, editing and deleting work through the provider', () async {
      await signIn();

      expect(await save(rating: 3), ReviewResult.saved);
      expect(provider.forProduct(7)!.rating, 3);
      final firstTime = provider.forProduct(7)!.createdAt;

      expect(
        await save(rating: 5, comment: '  Even better after a week  '),
        ReviewResult.saved,
      );
      expect(provider.reviews, hasLength(1));
      expect(provider.forProduct(7)!.rating, 5);
      expect(
        provider.forProduct(7)!.comment,
        'Even better after a week',
      ); // ছাঁটা
      expect(provider.forProduct(7)!.createdAt, firstTime);

      expect(await provider.delete(7), isTrue);
      expect(provider.forProduct(7), isNull);
    });

    test('each person sees only their own reviews on a shared phone', () async {
      await signIn();
      await save();

      await rig.auth.signOut();
      expect(provider.reviews, isEmpty);

      await signIn(testUser2);
      expect(provider.reviews, isEmpty);

      await rig.auth.signOut();
      await signIn();
      await waitUntil(() => provider.reviews.isNotEmpty);
      expect(provider.forProduct(7), isNotNull);
    });
  });

  group('server reviews provider', () {
    late MockProductRepository products;

    setUp(() => products = MockProductRepository());

    test('loads and summarises the reviews', () async {
      when(() => products.fetchReviews(1)).thenAnswer(
        (_) async => const [
          ProductReview(rating: 5, comment: 'a', reviewerName: 'A'),
          ProductReview(rating: 4, comment: 'b', reviewerName: 'B'),
        ],
      );
      final provider = ProductReviewsProvider(products, 1);
      expect(provider.status, DataStatus.loading);

      await provider.load();

      expect(provider.status, DataStatus.ready);
      expect(provider.reviews, hasLength(2));
      expect(provider.summary.averageText, '4.5');
      provider.dispose();
    });

    test('a failure is kept and a retry recovers', () async {
      when(() => products.fetchReviews(1)).thenAnswer(
        (_) => Future.error(
          const ApiException(
            type: ApiErrorType.noConnection,
            message: 'No internet',
          ),
        ),
      );
      final provider = ProductReviewsProvider(products, 1);

      await provider.load();
      expect(provider.status, DataStatus.error);
      expect(provider.error!.message, 'No internet');

      when(() => products.fetchReviews(1)).thenAnswer((_) async => const []);
      await provider.load();
      expect(provider.status, DataStatus.ready);
      expect(provider.reviews, isEmpty);
      expect(provider.summary.count, 0);
      provider.dispose();
    });
  });
}
