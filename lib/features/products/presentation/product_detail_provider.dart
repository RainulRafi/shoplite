import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

class ProductDetailProvider extends ChangeNotifier {
  final ProductRepository _repository;

  Product _product;
  bool _refreshing = false;
  ApiException? _refreshError;

  bool _disposed = false;

  ProductDetailProvider(this._repository, Product initial) : _product = initial;

  Product get product => _product;
  bool get refreshing => _refreshing;
  ApiException? get refreshError => _refreshError;

  Future<void> refresh() async {
    if (_refreshing) return;

    _refreshing = true;
    _refreshError = null;
    notifyListeners();

    try {
      _product = await _repository.fetchProduct(_product.id);
    } on ApiException catch (e) {
      _refreshError = e;
    } finally {
      _refreshing = false;
    }

    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
