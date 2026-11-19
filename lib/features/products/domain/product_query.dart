import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';

enum ProductSort {
  relevance('Relevance'),
  priceLowHigh('Price: low to high'),
  priceHighLow('Price: high to low'),
  topRated('Top rated'),
  biggestDiscount('Biggest discount');

  const ProductSort(this.title);
  final String title;
}

@immutable
class ProductFilters {
  final Money? minPrice;
  final Money? maxPrice;
  final bool inStockOnly;
  final double minRating;

  const ProductFilters({
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.minRating = 0,
  });

  bool get hasPrice => minPrice != null || maxPrice != null;
  bool get isActive => hasPrice || inStockOnly || minRating > 0;

  int get activeCount =>
      (hasPrice ? 1 : 0) + (inStockOnly ? 1 : 0) + (minRating > 0 ? 1 : 0);

  ProductFilters copyWith({
    Money? minPrice,
    Money? maxPrice,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool? inStockOnly,
    double? minRating,
  }) {
    return ProductFilters(
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      minRating: minRating ?? this.minRating,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductFilters &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.inStockOnly == inStockOnly &&
      other.minRating == minRating;

  @override
  int get hashCode => Object.hash(minPrice, maxPrice, inStockOnly, minRating);
}

@immutable
class ProductQuery {
  final String search;
  final String? category;
  final ProductSort sort;
  final ProductFilters filters;

  const ProductQuery({
    this.search = '',
    this.category,
    this.sort = ProductSort.relevance,
    this.filters = const ProductFilters(),
  });

  bool get isPagedOnServer =>
      category == null && sort == ProductSort.relevance && !filters.isActive;

  String get sourceKey {
    if (search.isNotEmpty) return 's:${search.toLowerCase()}';
    if (category != null) return 'c:$category';
    return 'all';
  }

  ProductQuery copyWith({
    String? search,
    String? category,
    bool clearCategory = false,
    ProductSort? sort,
    ProductFilters? filters,
  }) {
    return ProductQuery(
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
      filters: filters ?? this.filters,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductQuery &&
      other.search == search &&
      other.category == category &&
      other.sort == sort &&
      other.filters == filters;

  @override
  int get hashCode => Object.hash(search, category, sort, filters);
}
