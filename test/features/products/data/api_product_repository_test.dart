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
}
