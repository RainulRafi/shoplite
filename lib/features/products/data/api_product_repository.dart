import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'product.dart';
import 'product_category.dart';
import 'product_page.dart';
import 'product_repository.dart';
import 'product_review.dart';

class ApiProductRepository implements ProductRepository {
  final ApiClient _api;
  ApiProductRepository(this._api);

  @override
  Future<ProductPage> fetchProducts({
    int limit = 20,
    int skip = 0,
    String? query,
  }) async {
    final text = query?.trim() ?? '';
    final searching = text.isNotEmpty;

    final json = await _api.get(
      searching ? '/products/search' : '/products',
      queryParameters: {if (searching) 'q': text, 'limit': limit, 'skip': skip},
    );
    return _parse(() => ProductPage.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<Product> fetchProduct(int id) async {
    final json = await _api.get('/products/$id');
    return _parse(() => Product.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<List<ProductCategory>> fetchCategories() async {
    final json = await _api.get('/products/categories');
    return _parse(
      () => (json as List<dynamic>).map(ProductCategory.fromJson).toList(),
    );
  }

  @override
  Future<ProductPage> fetchByCategory(String slug) async {
    final json = await _api.get(
      '/products/category/${Uri.encodeComponent(slug)}',
      queryParameters: {'limit': 0},
    );
    return _parse(() => ProductPage.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<ProductPage> fetchTop(HomeRank rank, {int limit = 10}) async {
    final sortBy = switch (rank) {
      HomeRank.deals => 'discountPercentage',
      HomeRank.topRated => 'rating',
    };
    final json = await _api.get(
      '/products',
      queryParameters: {
        'sortBy': sortBy,
        'order': 'desc',
        'limit': limit,
        'skip': 0,
      },
    );
    return _parse(() => ProductPage.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<List<ProductReview>> fetchReviews(int productId) async {
    final json = await _api.get(
      '/products/$productId',
      queryParameters: {'select': 'reviews'},
    );
    return _parse(() {
      final raw =
          (json as Map<String, dynamic>)['reviews'] as List<dynamic>? ??
          const [];
      return raw
          .map((e) => ProductReview.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError catch (e) {
      if (kDebugMode) debugPrint('Could not parse response: $e');
      throw const ApiException.parsing();
    } on FormatException catch (e) {
      if (kDebugMode) debugPrint('Could not parse response: $e');
      throw const ApiException.parsing();
    }
  }
}
