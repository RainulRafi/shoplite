import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/features/home/presentation/home_provider.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/products/data/product_category.dart';
import 'package:shoplite/features/products/data/product_page.dart';
import 'package:shoplite/features/products/data/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const _noInternet = ApiException(
  type: ApiErrorType.noConnection,
  message: 'No internet',
);

ProductPage _top(String title) => ProductPage(
  products: [Product(id: 1, title: title, price: 10)],
  total: 1,
  skip: 0,
  limit: 10,
);

void main() {
  late MockProductRepository repo;
  late HomeProvider home;

  setUp(() {
    repo = MockProductRepository();
    home = HomeProvider(repo);
  });

  tearDown(() => home.dispose());

  void stubAllOk() {
    when(() => repo.fetchCategories()).thenAnswer(
      (_) async => const [ProductCategory(slug: 'beauty', name: 'Beauty')],
    );
    when(() => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')))
        .thenAnswer((_) async => _top('Deal'));
    when(() => repo.fetchTop(HomeRank.topRated, limit: any(named: 'limit')))
        .thenAnswer((_) async => _top('Top'));
  }

  test('everything starts loading', () {
    expect(home.categories.status, SectionStatus.loading);
    expect(home.deals.status, SectionStatus.loading);
    expect(home.topRated.status, SectionStatus.loading);
  });

  test('all three sections load', () async {
    stubAllOk();

    await home.load();

    expect(home.categories.data!.single.name, 'Beauty');
    expect(home.deals.data!.single.title, 'Deal');
    expect(home.topRated.data!.single.title, 'Top');
  });

  test('one failing section does not break the others', () async {
    stubAllOk();
    when(() => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')))
        .thenAnswer((_) => Future.error(_noInternet));

    await home.load();

    expect(home.deals.status, SectionStatus.error);
    expect(home.deals.error!.isRetryable, isTrue);
    expect(home.categories.status, SectionStatus.ready);
    expect(home.topRated.status, SectionStatus.ready);
  });

  test('retrying reloads only that section', () async {
    stubAllOk();
    when(() => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')))
        .thenAnswer((_) => Future.error(_noInternet));
    await home.load();

    when(() => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')))
        .thenAnswer((_) async => _top('Deal again'));
    home.retryDeals();
    expect(home.deals.status, SectionStatus.loading);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(home.deals.data!.single.title, 'Deal again');
    verify(() => repo.fetchCategories()).called(1);
  });

  test(
    'a failed refresh keeps what was shown and reports the problem',
    () async {
      stubAllOk();
      await home.load();

      when(() => repo.fetchTop(HomeRank.topRated, limit: any(named: 'limit')))
          .thenAnswer((_) => Future.error(_noInternet));
      final failure = await home.refresh();

      expect(failure!.message, 'No internet');
      expect(home.topRated.status, SectionStatus.ready);
      expect(home.topRated.data!.single.title, 'Top');
    },
  );

  test('a successful refresh shows the new data', () async {
    stubAllOk();
    await home.load();

    when(() => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')))
        .thenAnswer((_) async => _top('Fresh deal'));
    expect(await home.refresh(), isNull);

    expect(home.deals.data!.single.title, 'Fresh deal');
  });

  test('an old slow reply never overwrites a newer refresh', () async {
    stubAllOk();
    final slow = Completer<ProductPage>();
    when(() => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')))
        .thenAnswer((_) => slow.future);

    final first = home.load();

    when(() => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')))
        .thenAnswer((_) async => _top('Newer'));
    await home.refresh();

    slow.complete(_top('Older'));
    await first;

    expect(home.deals.data!.single.title, 'Newer');
  });

  test(
    'the category name comes from the list, and falls back to a readable one',
    () async {
      stubAllOk();
      await home.load();

      expect(home.categoryName('beauty'), 'Beauty');
      expect(home.categoryName('mens-shirts'), 'Mens shirts');
    },
  );
}
