import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/products/data/product_category.dart';

void main() {
  test('reads the object form the server sends today', () {
    final c = ProductCategory.fromJson({
      'slug': 'mens-shirts',
      'name': 'Mens Shirts',
      'url': 'https://x.test',
    });
    expect(c.slug, 'mens-shirts');
    expect(c.name, 'Mens Shirts');
  });

  test('reads a plain string, the older form', () {
    final c = ProductCategory.fromJson('mens-shirts');
    expect(c.slug, 'mens-shirts');
    expect(c.name, 'Mens shirts');
  });

  test('a missing name falls back to a readable one', () {
    expect(ProductCategory.fromJson({'slug': 'beauty'}).name, 'Beauty');
    expect(
      ProductCategory.fromJson({'slug': 'beauty', 'name': ''}).name,
      'Beauty',
    );
  });

  test('an entry without a slug is a parsing problem, not a silent blank', () {
    expect(
      () => ProductCategory.fromJson({'name': 'x'}),
      throwsA(isA<TypeError>()),
    );
  });
}
