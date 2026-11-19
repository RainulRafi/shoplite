import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/network/api_client.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/features/products/data/api_product_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient api;
  late ApiProductRepository repository;

  setUp(() {
    api = MockApiClient();
    repository = ApiProductRepository(api);
  });

  test('fetchProducts sends limit and skip, and returns a page', () async {
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer(
          (_) async => {
            'products': [
              {'id': 1, 'title': 'A', 'price': 1.5},
            ],
            'total': 194,
            'skip': 10,
            'limit': 5,
          },
        );

    final page = await repository.fetchProducts(limit: 5, skip: 10);

    expect(page.products.single.title, 'A');
    expect(page.hasMore, isTrue);

    final sent = verify(
      () => api.get(
        '/products',
        queryParameters: captureAny(named: 'queryParameters'),
      ),
    ).captured.single;
    expect(sent, {'limit': 5, 'skip': 10});
  });

  test(
    'a search uses the search path and sends the trimmed word as q',
    () async {
      when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {'products': <dynamic>[], 'total': 0});

      final page = await repository.fetchProducts(
        limit: 5,
        skip: 10,
        query: '  phone ',
      );

      final sent = verify(
        () => api.get(
          '/products/search',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single;
      expect(sent, {'q': 'phone', 'limit': 5, 'skip': 10});
      expect(page.products, isEmpty);
    },
  );

  test('a blank query is treated as no search at all', () async {
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => {'products': <dynamic>[], 'total': 0});

    await repository.fetchProducts(query: '   ');

    verify(
      () =>
          api.get('/products', queryParameters: any(named: 'queryParameters')),
    ).called(1);
  });

  test('fetchProduct reads one product by id', () async {
    when(() => api.get('/products/7'))
        .thenAnswer((_) async => {'id': 7, 'title': 'Seven', 'price': 2});

    final product = await repository.fetchProduct(7);
    expect(product.id, 7);
    expect(product.title, 'Seven');
  });

  test('an unexpected response shape becomes a parsing error', () async {
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => {'unexpected': true});

    await expectLater(
      repository.fetchProducts(),
      throwsA(
        isA<ApiException>().having((e) => e.type, 'type', ApiErrorType.parsing),
      ),
    );
  });

  test('network errors pass through unchanged', () async {
    when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenThrow(
          const ApiException(type: ApiErrorType.notFound, message: 'missing'),
        );

    await expectLater(
      repository.fetchProducts(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.type,
          'type',
          ApiErrorType.notFound,
        ),
      ),
    );
  });
  test('fetchCategories reads objects and plain strings', () async {
    when(() => api.get('/products/categories')).thenAnswer(
      (_) async => [
        {'slug': 'beauty', 'name': 'Beauty', 'url': 'x'},
        'mens-shirts',
      ],
    );

    final list = await repository.fetchCategories();

    expect(list.map((c) => c.slug), ['beauty', 'mens-shirts']);
    expect(list.last.name, 'Mens shirts');
  });

  test(
    'fetchByCategory asks for the whole category and encodes the slug',
    () async {
      when(() => api.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer(
            (_) async => {
              'products': [
                {'id': 1, 'title': 'A', 'price': 1},
              ],
              'total': 1,
            },
          );

      final page = await repository.fetchByCategory('mens-shirts');

      expect(page.products.single.title, 'A');
      final sent = verify(
        () => api.get(
          '/products/category/mens-shirts',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single;
      expect(sent, {'limit': 0});
    },
  );
}
