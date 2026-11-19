import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/products/domain/product_filtering.dart';
import 'package:shoplite/features/products/domain/product_query.dart';

Product _p(
  int id, {
  double price = 10,
  double rating = 0,
  int stock = 5,
  double discount = 0,
  String category = 'a',
}) => Product(
  id: id,
  title: 'P$id',
  price: price,
  rating: rating,
  stock: stock,
  discountPercentage: discount,
  category: category,
);

final List<Product> _catalog = [
  _p(1, price: 50, rating: 4.8, stock: 5, category: 'beauty'),
  _p(2, price: 10, rating: 3.0, stock: 0, category: 'beauty'),
  _p(3, price: 30, rating: 4.0, stock: 3, category: 'furniture', discount: 20),
  _p(4, price: 20, rating: 4.5, stock: 9, category: 'furniture'),
];

List<int> _ids(ProductQuery q, [List<Product>? source]) =>
    applyQuery(source ?? _catalog, q).map((p) => p.id).toList();

void main() {
  group('sorting', () {
    test('relevance keeps the server order', () {
      expect(_ids(const ProductQuery()), [1, 2, 3, 4]);
    });

    test('price sorts use the price after discounts', () {
      expect(_ids(const ProductQuery(sort: ProductSort.priceLowHigh)), [
        2,
        4,
        3,
        1,
      ]);
      expect(_ids(const ProductQuery(sort: ProductSort.priceHighLow)), [
        1,
        3,
        4,
        2,
      ]);
    });

    test('top rated puts the best rating first', () {
      expect(_ids(const ProductQuery(sort: ProductSort.topRated)), [
        1,
        4,
        3,
        2,
      ]);
    });

    test('biggest discount puts discounted products first', () {
      expect(_ids(const ProductQuery(sort: ProductSort.biggestDiscount)), [
        3,
        1,
        2,
        4,
      ]);
    });

    test('ties are broken by id so the order never jumps around', () {
      final same = [_p(9), _p(3), _p(7)];
      expect(_ids(const ProductQuery(sort: ProductSort.priceLowHigh), same), [
        3,
        7,
        9,
      ]);
      expect(_ids(const ProductQuery(sort: ProductSort.priceHighLow), same), [
        3,
        7,
        9,
      ]);
    });

    test('the source list is never changed', () {
      final copy = List<Product>.of(_catalog);
      applyQuery(_catalog, const ProductQuery(sort: ProductSort.priceHighLow));
      expect(_catalog.map((p) => p.id), copy.map((p) => p.id));
    });
  });

  group('filtering', () {
    test('a category keeps only its products', () {
      expect(_ids(const ProductQuery(category: 'furniture')), [3, 4]);
      expect(_ids(const ProductQuery(category: 'nothing')), isEmpty);
    });

    test('a price range works on the price after discounts', () {
      final q = ProductQuery(
        filters: ProductFilters(
          minPrice: const Money(1500),
          maxPrice: const Money(3000),
        ),
      );
      expect(_ids(q), [3, 4]); // $24 আর $20। $50 আর $10 বাদ
    });

    test('only a minimum or only a maximum also works', () {
      expect(
        _ids(
          const ProductQuery(filters: ProductFilters(minPrice: Money(3000))),
        ),
        [1],
      );
      expect(
        _ids(
          const ProductQuery(filters: ProductFilters(maxPrice: Money(2000))),
        ),
        [2, 4],
      );
    });

    test('in stock only hides products with no stock', () {
      expect(
        _ids(const ProductQuery(filters: ProductFilters(inStockOnly: true))),
        [1, 3, 4],
      );
    });

    test('a minimum rating keeps that rating and above', () {
      expect(_ids(const ProductQuery(filters: ProductFilters(minRating: 4))), [
        1,
        3,
        4,
      ]);
      expect(
        _ids(const ProductQuery(filters: ProductFilters(minRating: 4.5))),
        [1, 4],
      );
    });

    test('filters and sorting combine', () {
      final q = ProductQuery(
        category: 'beauty',
        sort: ProductSort.priceLowHigh,
        filters: const ProductFilters(inStockOnly: true),
      );
      expect(_ids(q), [1]);

      final all = const ProductQuery(
        sort: ProductSort.topRated,
        filters: ProductFilters(inStockOnly: true, minRating: 4),
      );
      expect(_ids(all), [1, 4, 3]);
    });
  });

  group('the query itself', () {
    test(
      'only plain browsing and searching are served page by page by the server',
      () {
        expect(const ProductQuery().isPagedOnServer, isTrue);
        expect(const ProductQuery(search: 'phone').isPagedOnServer, isTrue);
        expect(
          const ProductQuery(sort: ProductSort.topRated).isPagedOnServer,
          isFalse,
        );
        expect(const ProductQuery(category: 'beauty').isPagedOnServer, isFalse);
        expect(
          const ProductQuery(filters: ProductFilters(inStockOnly: true))
              .isPagedOnServer,
          isFalse,
        );
      },
    );

    test(
      'the data source is the search when there is one, else the category',
      () {
        expect(const ProductQuery().sourceKey, 'all');
        expect(const ProductQuery(search: 'Phone').sourceKey, 's:phone');
        expect(const ProductQuery(category: 'beauty').sourceKey, 'c:beauty');
        expect(
          const ProductQuery(search: 'phone', category: 'beauty').sourceKey,
          's:phone',
        );
      },
    );

    test('queries and filters compare by value', () {
      expect(const ProductQuery(search: 'a'), const ProductQuery(search: 'a'));
      expect(
        const ProductQuery(search: 'a') == const ProductQuery(search: 'b'),
        isFalse,
      );
      expect(
        const ProductFilters(minPrice: Money(100)),
        const ProductFilters(minPrice: Money(100)),
      );
      expect(
        const ProductQuery(filters: ProductFilters(minRating: 3)).hashCode,
        const ProductQuery(filters: ProductFilters(minRating: 3)).hashCode,
      );
    });

    test(
      'copyWith can clear the category and filters report how many are on',
      () {
        const q = ProductQuery(category: 'beauty');
        expect(q.copyWith(clearCategory: true).category, isNull);
        expect(q.copyWith(sort: ProductSort.topRated).category, 'beauty');

        const f = ProductFilters(
          minPrice: Money(100),
          maxPrice: Money(500),
          minRating: 3,
        );
        expect(f.activeCount, 2);
        expect(
          f.copyWith(clearMinPrice: true, clearMaxPrice: true).hasPrice,
          isFalse,
        );
        expect(const ProductFilters().isActive, isFalse);
      },
    );
  });
}
