import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

class ProductDetailProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final void Function(Product product)? _onViewed;

  Product _product;
  bool _refreshing = false;
  ApiException? _refreshError;
  bool _disposed = false;

  ProductDetailProvider(
    this._repository,
    Product initial, {
    void Function(Product product)? onViewed,
  }) : _product = initial,
       _onViewed = onViewed {
    if (onViewed != null) {
      Future.microtask(() {
        if (!_disposed) onViewed(_product);
      });
    }
  }

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
      _onViewed?.call(_product);
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
