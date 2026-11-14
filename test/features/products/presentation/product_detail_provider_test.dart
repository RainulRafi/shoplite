import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/products/data/product_repository.dart';
import 'package:shoplite/features/products/presentation/product_detail_provider.dart';

class MockProductRepository extends Mock implements ProductRepository {}

Product _product(String title) => Product(id: 1, title: title, price: 5);

void main() {
  late MockProductRepository repo;

  setUp(() => repo = MockProductRepository());

  test('shows the product it was given straight away', () {
    final provider = ProductDetailProvider(repo, _product('Old'));
    expect(provider.product.title, 'Old');
    expect(provider.refreshing, isFalse);
  });

  test('refresh replaces the product with the fresh copy', () async {
    when(() => repo.fetchProduct(1)).thenAnswer((_) async => _product('Fresh'));
    final provider = ProductDetailProvider(repo, _product('Old'));

    await provider.refresh();

    expect(provider.product.title, 'Fresh');
    expect(provider.refreshError, isNull);
    expect(provider.refreshing, isFalse);
  });

  test('a failed refresh keeps what was shown and records the error', () async {
    when(() => repo.fetchProduct(1)).thenAnswer(
      (_) => Future.error(
        const ApiException(
          type: ApiErrorType.noConnection,
          message: 'No internet',
        ),
      ),
    );
    final provider = ProductDetailProvider(repo, _product('Old'));

    await provider.refresh();

    expect(provider.product.title, 'Old');
    expect(provider.refreshError!.message, 'No internet');
  });

  test('finishing after the screen is gone does not throw', () async {
    final completer = Completer<Product>();
    when(() => repo.fetchProduct(1)).thenAnswer((_) => completer.future);
    final provider = ProductDetailProvider(repo, _product('Old'));

    final running = provider.refresh();
    provider.dispose();
    completer.complete(_product('Fresh'));

    await running;
  });
}
