import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/products/data/product_page.dart';

const _realProductJson = '''
{
  "id": 1,
  "title": "Essence Mascara Lash Princess",
  "description": "A popular mascara.",
  "category": "beauty",
  "price": 9.99,
  "discountPercentage": 10.48,
  "rating": 2.56,
  "stock": 99,
  "tags": ["beauty", "mascara"],
  "brand": "Essence",
  "availabilityStatus": "In Stock",
  "shippingInformation": "Ships in 3-5 business days",
  "returnPolicy": "No return policy",
  "reviews": [{"rating": 3, "comment": "Would not recommend!"}],
  "meta": {"barcode": "5784719087687"},
  "images": ["https://cdn.dummyjson.com/a/1.webp"],
  "thumbnail": "https://cdn.dummyjson.com/a/thumbnail.webp"
}
''';

void main() {
  group('Product.fromJson', () {
    test('reads a real product and ignores fields it does not know', () {
      final product = Product.fromJson(
        jsonDecode(_realProductJson) as Map<String, dynamic>,
      );

      expect(product.id, 1);
      expect(product.title, 'Essence Mascara Lash Princess');
      expect(product.price, 9.99);
      expect(product.brand, 'Essence');
      expect(product.images.length, 1);
      expect(product.inStock, isTrue);
    });

    test('a missing brand becomes null instead of crashing', () {
      final product = Product.fromJson({
        'id': 2,
        'title': 'No brand',
        'price': 5.0,
      });
      expect(product.brand, isNull);
    });

    test('a price sent as a whole number still works', () {
      // JSON-এ 10 আর 10.0 একই, কিন্তু Dart-এ int আর double আলাদা
      final product = Product.fromJson({
        'id': 3,
        'title': 'Whole',
        'price': 10,
      });
      expect(product.price, 10.0);
    });

    test('missing optional fields fall back to safe defaults', () {
      final product = Product.fromJson({
        'id': 4,
        'title': 'Minimal',
        'price': 1,
      });
      expect(product.description, '');
      expect(product.rating, 0);
      expect(product.stock, 0);
      expect(product.inStock, isFalse);
      expect(product.images, isEmpty);
    });

    test(
      'a missing required field throws, so bad data is not shown silently',
      () {
        expect(
          () => Product.fromJson({'id': 5, 'price': 1}), // title নেই
          throwsA(isA<TypeError>()),
        );
      },
    );

    test('discounted price is calculated from the original price', () {
      final product = Product.fromJson({
        'id': 1,
        'title': 'x',
        'price': 9.99,
        'discountPercentage': 10.48,
      });
      expect(product.hasDiscount, isTrue);
      expect(product.discountedPrice, closeTo(8.94, 0.01));
    });
  });

  group('ProductPage', () {
    Map<String, dynamic> pageJson({required int skip, required int count}) => {
      'products': [
        for (var i = 0; i < count; i++)
          {'id': i + 1, 'title': 'P$i', 'price': 1},
      ],
      'total': 194,
      'skip': skip,
      'limit': 5,
    };

    test('has more when fewer than the total have been loaded', () {
      final page = ProductPage.fromJson(pageJson(skip: 0, count: 5));
      expect(page.hasMore, isTrue);
    });

    test('has no more on the last page', () {
      // 190 বাদ + এই পাতায় 4 = 194, মোটের সমান, আর নেই
      final page = ProductPage.fromJson(pageJson(skip: 190, count: 4));
      expect(page.hasMore, isFalse);
    });
  });
}
