import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'product.dart';
import 'product_page.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  final ApiClient _api;
  ApiProductRepository(this._api);

  @override
  Future<ProductPage> fetchProducts({int limit = 20, int skip = 0}) async {
    final json = await _api.get(
      '/products',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return _parse(() => ProductPage.fromJson(json as Map<String, dynamic>));
  }

  @override
  Future<Product> fetchProduct(int id) async {
    final json = await _api.get('/products/$id');
    return _parse(() => Product.fromJson(json as Map<String, dynamic>));
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
