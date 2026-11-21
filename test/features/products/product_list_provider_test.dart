import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/products/data/product_page.dart';
import 'package:shoplite/features/products/data/product_repository.dart';
import 'package:shoplite/features/products/domain/product_query.dart';
import 'package:shoplite/features/products/presentation/product_list_provider.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const _noInternet = ApiException(
  type: ApiErrorType.noConnection,
  message: 'No internet',
);

Product _p(
  int id, {
  String? title,
  double price = 10,
  double rating = 0,
  int stock = 5,
  double discount = 0,
  String category = 'a',
}) => Product(
  id: id,
  title: title ?? 'P$id',
  price: price,
  rating: rating,
  stock: stock,
  discountPercentage: discount,
  category: category,
);

List<Product> _numbered(int count) => [for (var i = 1; i <= count; i++) _p(i)];

ProductPage _page(List<Product> all, {required int skip, required int limit}) {
  final end = limit == 0 ? all.length : math.min(all.length, skip + limit);
  final slice = skip >= all.length ? <Product>[] : all.sublist(skip, end);
  return ProductPage(
    products: slice,
    total: all.length,
    skip: skip,
    limit: limit,
  );
}

final List<Product> _catalog = [
  _p(1, price: 50, rating: 4.8, stock: 5, category: 'beauty'),
  _p(2, price: 10, rating: 3.0, stock: 0, category: 'beauty'),
  _p(3, price: 30, rating: 4.0, stock: 3, category: 'furniture', discount: 20),
  _p(4, price: 20, rating: 4.5, stock: 9, category: 'furniture'),
];

void main() {
  late MockProductRepository repo;
  late ProductListProvider provider;

  setUp(() {
    repo = MockProductRepository();
    provider = ProductListProvider(repo);
  });

  tearDown(() => provider.dispose());

  void stubServer({
    List<Product>? all,
    Map<String, List<Product>> bySearch = const {},
    Map<String, List<Product>> byCategory = const {},
  }) {
    final everything = all ?? _numbered(50);

    when(
      () => repo.fetchProducts(
        limit: any(named: 'limit'),
        skip: any(named: 'skip'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((invocation) async {
      final limit = invocation.namedArguments[#limit] as int;
      final skip = invocation.namedArguments[#skip] as int;
      final query = invocation.namedArguments[#query] as String?;
      final source = query == null
          ? everything
          : (bySearch[query] ?? const <Product>[]);
      return _page(source, skip: skip, limit: limit);
    });

    when(() => repo.fetchByCategory(any())).thenAnswer((invocation) async {
      final slug = invocation.positionalArguments.first as String;
      return _page(byCategory[slug] ?? const <Product>[], skip: 0, limit: 0);
    });
  }

  List<int> ids() => provider.products.map((p) => p.id).toList();

  void expectEverythingFetched(int times) {
    verify(() => repo.fetchProducts(limit: 0, skip: 0, query: null))
        .called(times);
  }

  group('first page, served by the server', () {
    test('starts in the loading state', () {
      expect(provider.status, LoadStatus.loading);
    });

    test('loading goes to success and keeps the page data', () async {
      stubServer();

      final seen = <LoadStatus>[];
      provider.addListener(() => seen.add(provider.status));

      await provider.load();

      expect(seen, [LoadStatus.loading, LoadStatus.success]);
      expect(provider.products.length, 20);
      expect(provider.total, 50);
      expect(provider.hasMore, isTrue);
      expect(provider.error, isNull);
    });

    test('a failure is kept as the error and retry can recover', () async {
      when(
        () => repo.fetchProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) => Future.error(_noInternet));

      await provider.load();
      expect(provider.status, LoadStatus.error);
      expect(provider.error!.isRetryable, isTrue);

      stubServer();
      await provider.load();
      expect(provider.status, LoadStatus.success);
      expect(provider.error, isNull);
    });

    test(
      'a second load while one is running does not send another request',
      () async {
        final completer = Completer<ProductPage>();
        when(
          () => repo.fetchProducts(
            limit: any(named: 'limit'),
            skip: any(named: 'skip'),
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) => completer.future);

        final first = provider.load();
        final second = provider.load();

        completer.complete(_page(_numbered(1), skip: 0, limit: 20));
        await first;
        await second;

        verify(
          () => repo.fetchProducts(
            limit: any(named: 'limit'),
            skip: any(named: 'skip'),
            query: any(named: 'query'),
          ),
        ).called(1);
      },
    );
  });

  group('infinite scroll from the server', () {
    test(
      'loadMore asks for the next page using the current length as skip',
      () async {
        stubServer();
        await provider.load();

        await provider.loadMore();
        expect(provider.products.length, 40);
        verify(() => repo.fetchProducts(limit: 20, skip: 20, query: null))
            .called(1);

        await provider.loadMore();
        expect(provider.products.length, 50);
        expect(provider.hasMore, isFalse);

        await provider.loadMore();
        verifyNever(() => repo.fetchProducts(limit: 20, skip: 50, query: null));
      },
    );

    test('loadMore is ignored while one is already running', () async {
      stubServer();
      await provider.load();

      final completer = Completer<ProductPage>();
      when(() => repo.fetchProducts(limit: 20, skip: 20, query: null))
          .thenAnswer((_) => completer.future);

      final a = provider.loadMore();
      final b = provider.loadMore();
      expect(provider.isLoadingMore, isTrue);

      completer.complete(_page(_numbered(50), skip: 20, limit: 20));
      await a;
      await b;

      verify(() => repo.fetchProducts(limit: 20, skip: 20, query: null))
          .called(1);
      expect(provider.isLoadingMore, isFalse);
    });

    test(
      'a failed loadMore keeps the list, and only retry continues',
      () async {
        stubServer();
        await provider.load();

        when(() => repo.fetchProducts(limit: 20, skip: 20, query: null))
            .thenAnswer((_) => Future.error(_noInternet));

        await provider.loadMore();
        expect(provider.loadMoreError!.message, 'No internet');
        expect(provider.products.length, 20);
        expect(provider.status, LoadStatus.success);

        await provider.loadMore();
        verify(() => repo.fetchProducts(limit: 20, skip: 20, query: null))
            .called(1);

        stubServer();
        await provider.retryLoadMore();
        expect(provider.loadMoreError, isNull);
        expect(provider.products.length, 40);
      },
    );

    test('a product that shows up twice is kept only once', () async {
      when(
        () => repo.fetchProducts(
          limit: any(named: 'limit'),
          skip: 0,
          query: null,
        ),
      ).thenAnswer(
        (_) async =>
            ProductPage(products: _numbered(20), total: 40, skip: 0, limit: 20),
      );

      when(
        () => repo.fetchProducts(
          limit: any(named: 'limit'),
          skip: 20,
          query: null,
        ),
      ).thenAnswer(
        (_) async => ProductPage(
          products: [for (var i = 19; i <= 38; i++) _p(i)],
          total: 40,
          skip: 20,
          limit: 20,
        ),
      );

      await provider.load();
      await provider.loadMore();

      expect(ids().toSet().length, ids().length);
      expect(provider.products.length, 38);
    });

    test(
      'an empty next page stops further paging instead of looping',
      () async {
        when(
          () => repo.fetchProducts(
            limit: any(named: 'limit'),
            skip: 0,
            query: null,
          ),
        ).thenAnswer(
          (_) async => ProductPage(
            products: _numbered(20),
            total: 100,
            skip: 0,
            limit: 20,
          ),
        );
        when(
          () => repo.fetchProducts(
            limit: any(named: 'limit'),
            skip: 20,
            query: null,
          ),
        ).thenAnswer(
          (_) async =>
              const ProductPage(products: [], total: 100, skip: 20, limit: 20),
        );

        await provider.load();
        await provider.loadMore();

        expect(provider.hasMore, isFalse);
        await provider.loadMore();
        verify(() => repo.fetchProducts(limit: 20, skip: 20, query: null))
            .called(1);
      },
    );
  });

  group('search', () {
    test(
      'a search replaces the list and clearing it brings the normal list back',
      () async {
        stubServer(
          bySearch: {
            'phone': [_p(101), _p(102), _p(103)],
          },
        );
        await provider.load();

        await provider.search('phone');
        expect(provider.query.search, 'phone');
        expect(ids(), [101, 102, 103]);
        expect(provider.hasMore, isFalse);

        await provider.search('');
        expect(provider.query.search, '');
        expect(provider.products.length, 20);
      },
    );

    test('searching with the same word again does nothing', () async {
      stubServer(
        bySearch: {
          'phone': [_p(101)],
        },
      );
      await provider.search('phone');
      await provider.search('  phone ');

      verify(() => repo.fetchProducts(limit: 20, skip: 0, query: 'phone'))
          .called(1);
    });

    test(
      'an empty search result is a normal success with an empty list',
      () async {
        stubServer();
        await provider.search('zzzzzz');

        expect(provider.status, LoadStatus.success);
        expect(provider.products, isEmpty);
        expect(provider.hasMore, isFalse);
      },
    );

    test('typing quickly sends one request, for the final word only', () async {
      final fast = ProductListProvider(
        repo,
        debounce: const Duration(milliseconds: 20),
      );
      stubServer(
        bySearch: {
          'abc': [_p(101), _p(102)],
        },
      );

      fast.onQueryChanged('a');
      fast.onQueryChanged('ab');
      fast.onQueryChanged('abc');
      await Future<void>.delayed(const Duration(milliseconds: 150));

      verify(() => repo.fetchProducts(limit: 20, skip: 0, query: 'abc'))
          .called(1);
      verifyNever(() => repo.fetchProducts(limit: 20, skip: 0, query: 'a'));
      verifyNever(() => repo.fetchProducts(limit: 20, skip: 0, query: 'ab'));
      expect(fast.products.length, 2);

      fast.dispose();
    });
  });

  group('sorting and filtering on the phone', () {
    test(
      'sorting loads everything once and then re-sorts without the network',
      () async {
        stubServer(all: _catalog);
        await provider.load();

        await provider.setSort(ProductSort.priceLowHigh);
        expect(ids(), [2, 4, 3, 1]);

        await provider.setSort(ProductSort.topRated);
        expect(ids(), [1, 4, 3, 2]);

        await provider.setFilters(const ProductFilters(inStockOnly: true));
        expect(ids(), [1, 4, 3]);

        expectEverythingFetched(1);
      },
    );

    test('a price filter works on the price after discounts', () async {
      stubServer(all: _catalog);

      await provider.setFilters(
        const ProductFilters(minPrice: Money(1500), maxPrice: Money(3000)),
      );

      expect(ids(), [3, 4]);
      expect(provider.total, 2);
    });

    test(
      'filters that match nothing give an empty success, not an error',
      () async {
        stubServer(all: _catalog);

        await provider.setFilters(
          const ProductFilters(minPrice: Money(100000)),
        );

        expect(provider.status, LoadStatus.success);
        expect(provider.products, isEmpty);
        expect(provider.hasMore, isFalse);
      },
    );

    test('a category fetches that category once, then sorts locally', () async {
      stubServer(
        byCategory: {
          'furniture': [_catalog[2], _catalog[3]],
        },
      );

      await provider.setCategory('furniture');
      expect(ids(), [3, 4]);

      await provider.setSort(ProductSort.priceLowHigh);
      expect(ids(), [4, 3]);

      verify(() => repo.fetchByCategory('furniture')).called(1);
    });

    test(
      'a search and a category together filter the search results by category',
      () async {
        stubServer(
          bySearch: {
            'chair': [_catalog[0], _catalog[2]],
          },
        );
        await provider.search('chair');

        await provider.setCategory('furniture');

        expect(ids(), [3]);
        verifyNever(() => repo.fetchByCategory(any()));
        verify(() => repo.fetchProducts(limit: 0, skip: 0, query: 'chair'))
            .called(1);
      },
    );

    test(
      'local results show twenty at a time and more appear without the network',
      () async {
        stubServer(all: _numbered(50));
        await provider.setSort(ProductSort.priceLowHigh);

        expect(provider.products.length, 20);
        expect(provider.hasMore, isTrue);

        await provider.loadMore();
        expect(provider.products.length, 40);
        await provider.loadMore();
        expect(provider.products.length, 50);
        expect(provider.hasMore, isFalse);

        expectEverythingFetched(1);
      },
    );

    test('clearing the refinements goes back to server paging and keeps the search', () async {
      stubServer(
        all: _catalog,
        bySearch: {
          'x': [_p(101)],
        },
      );
      await provider.search('x');
      await provider.applyRefinements(
        category: 'beauty',
        filters: const ProductFilters(inStockOnly: true),
      );
      await provider.setSort(ProductSort.topRated);
      expect(provider.query.isPagedOnServer, isFalse);

      await provider.clearRefinements();

      expect(provider.query, const ProductQuery(search: 'x'));
      expect(provider.query.isPagedOnServer, isTrue);
      expect(ids(), [101]);
    });

    test(
      'pull to refresh forgets the remembered data and fetches again',
      () async {
        stubServer(all: _catalog);
        await provider.setSort(ProductSort.priceLowHigh);
        expect(ids(), [2, 4, 3, 1]);

        stubServer(all: [_p(7, price: 5), ..._catalog]);
        final failure = await provider.refresh();

        expect(failure, isNull);
        expect(ids().first, 7);
        expect(provider.status, LoadStatus.success);
      },
    );

    test(
      'a failed everything-fetch shows the error and retry recovers',
      () async {
        when(
          () => repo.fetchProducts(
            limit: any(named: 'limit'),
            skip: any(named: 'skip'),
            query: any(named: 'query'),
          ),
        ).thenAnswer((_) => Future.error(_noInternet));

        await provider.setSort(ProductSort.topRated);
        expect(provider.status, LoadStatus.error);

        stubServer(all: _catalog);
        await provider.load();
        expect(provider.status, LoadStatus.success);
        expect(ids(), [1, 4, 3, 2]);
      },
    );
  });

  group('race conditions', () {
    test(
      'a slow reply for an old search never overwrites a newer one',
      () async {
        final slowA = Completer<ProductPage>();
        final fastAb = Completer<ProductPage>();
        when(
          () => repo.fetchProducts(
            limit: any(named: 'limit'),
            skip: any(named: 'skip'),
            query: 'a',
          ),
        ).thenAnswer((_) => slowA.future);
        when(
          () => repo.fetchProducts(
            limit: any(named: 'limit'),
            skip: any(named: 'skip'),
            query: 'ab',
          ),
        ).thenAnswer((_) => fastAb.future);

        final first = provider.search('a');
        final second = provider.search('ab');

        fastAb.complete(
          _page(
            [_p(1, title: 'ab-0'), _p(2, title: 'ab-1')],
            skip: 0,
            limit: 20,
          ),
        );
        await second;
        expect(provider.products.map((p) => p.title), ['ab-0', 'ab-1']);

        slowA.complete(_page(_numbered(5), skip: 0, limit: 20));
        await first;

        expect(provider.products.map((p) => p.title), ['ab-0', 'ab-1']);
        expect(provider.query.search, 'ab');
      },
    );

    test('a slow category does not overwrite a newer one', () async {
      final slowA = Completer<ProductPage>();
      when(() => repo.fetchByCategory('a')).thenAnswer((_) => slowA.future);
      when(() => repo.fetchByCategory('b')).thenAnswer(
        (_) async => _page([_p(9, category: 'b')], skip: 0, limit: 0),
      );

      final first = provider.setCategory('a');
      final second = provider.setCategory('b');
      await second;

      slowA.complete(_page([_p(1, category: 'a')], skip: 0, limit: 0));
      await first;

      expect(ids(), [9]);
      expect(provider.query.category, 'b');
    });

    test(
      'a late "load more" reply is dropped once a new search has started',
      () async {
        stubServer(
          bySearch: {
            'phone': [_p(101), _p(102), _p(103)],
          },
        );
        await provider.load();

        final slowMore = Completer<ProductPage>();
        when(() => repo.fetchProducts(limit: 20, skip: 20, query: null))
            .thenAnswer((_) => slowMore.future);

        final more = provider.loadMore();
        await provider.search('phone');

        slowMore.complete(_page(_numbered(50), skip: 20, limit: 20));
        await more;

        expect(ids(), [101, 102, 103]);
        expect(provider.isLoadingMore, isFalse);
      },
    );
  });

  group('presets from outside', () {
    test('applyPreset replaces the whole query, clears the search and asks the screen to sync', () async {
      stubServer(
        all: _catalog,
        bySearch: {
          'phone': [_p(101)],
        },
      );
      await provider.search('phone');
      final token = provider.searchSyncToken;

      await provider.applyPreset(
        const ProductQuery(sort: ProductSort.biggestDiscount),
      );

      expect(provider.query.search, '');
      expect(provider.query.sort, ProductSort.biggestDiscount);
      expect(provider.searchSyncToken, token + 1);
      expect(ids().first, 3);
    });

    test('typing never bumps the sync token', () async {
      stubServer(
        bySearch: {
          'phone': [_p(101)],
        },
      );
      final token = provider.searchSyncToken;

      await provider.search('phone');

      expect(provider.searchSyncToken, token);
    });
  });

  group('pull to refresh', () {
    test(
      'refresh swaps in the new list without showing the loading state',
      () async {
        stubServer(all: _numbered(50));
        await provider.load();

        stubServer(all: _numbered(60));
        final seen = <LoadStatus>[];
        provider.addListener(() => seen.add(provider.status));

        final failure = await provider.refresh();

        expect(failure, isNull);
        expect(seen, [LoadStatus.success]);
        expect(provider.total, 60);
      },
    );

    test('a failed refresh keeps the list and hands back the error', () async {
      stubServer(all: _numbered(50));
      await provider.load();

      when(
        () => repo.fetchProducts(
          limit: any(named: 'limit'),
          skip: any(named: 'skip'),
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) => Future.error(
          const ApiException(type: ApiErrorType.timeout, message: 'Too slow'),
        ),
      );

      final failure = await provider.refresh();

      expect(failure!.message, 'Too slow');
      expect(provider.status, LoadStatus.success);
      expect(provider.products.length, 20);
    });
  });
}
