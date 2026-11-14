import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/product.dart';
import '../data/product_repository.dart';

enum LoadStatus { loading, success, error }

class ProductListProvider extends ChangeNotifier {
  final ProductRepository _repository;
  ProductListProvider(this._repository);

  static const int pageSize = 20;

  LoadStatus _status = LoadStatus.loading;
  List<Product> _products = const [];
  int _total = 0;
  ApiException? _error;

  bool _requestInFlight = false;

  LoadStatus get status => _status;
  List<Product> get products => _products;
  int get total => _total;
  ApiException? get error => _error;

  Future<void> load() async {
    if (_requestInFlight) return;
    _requestInFlight = true;

    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final page = await _repository.fetchProducts(limit: pageSize, skip: 0);
      _products = page.products;
      _total = page.total;
      _status = LoadStatus.success;
    } on ApiException catch (e) {
      _error = e;
      _status = LoadStatus.error;
    } finally {
      _requestInFlight = false;
    }

    notifyListeners();
  }
}
