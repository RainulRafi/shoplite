import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/utils/text_format.dart';
import '../../products/data/product.dart';
import '../../products/data/product_category.dart';
import '../../products/data/product_repository.dart';

enum SectionStatus { loading, ready, error }

@immutable
class SectionState<T> {
  final SectionStatus status;
  final T? data;
  final ApiException? error;

  const SectionState.loading()
    : status = SectionStatus.loading,
      data = null,
      error = null;

  const SectionState.ready(T this.data)
    : status = SectionStatus.ready,
      error = null;

  const SectionState.failed(ApiException this.error)
    : status = SectionStatus.error,
      data = null;
}

class HomeProvider extends ChangeNotifier {
  final ProductRepository _repository;

  HomeProvider(this._repository);

  static const int railSize = 10;

  SectionState<List<ProductCategory>> _categories =
      const SectionState.loading();
  SectionState<List<Product>> _deals = const SectionState.loading();
  SectionState<List<Product>> _topRated = const SectionState.loading();

  int _run = 0;
  bool _disposed = false;

  SectionState<List<ProductCategory>> get categories => _categories;
  SectionState<List<Product>> get deals => _deals;
  SectionState<List<Product>> get topRated => _topRated;

  String categoryName(String slug) {
    for (final c in _categories.data ?? const <ProductCategory>[]) {
      if (c.slug == slug) return c.name;
    }
    return prettyCategory(slug);
  }

  Future<void> load() async {
    _categories = const SectionState.loading();
    _deals = const SectionState.loading();
    _topRated = const SectionState.loading();
    _notify();
    await _loadAll();
  }

  Future<ApiException?> refresh() => _loadAll();

  Future<ApiException?> _loadAll() async {
    final run = ++_run;
    final errors = await Future.wait([
      _loadCategories(run),
      _loadDeals(run),
      _loadTopRated(run),
    ]);
    for (final e in errors) {
      if (e != null) return e;
    }
    return null;
  }

  void retryCategories() {
    _categories = const SectionState.loading();
    _notify();
    unawaited(_loadCategories(_run));
  }

  void retryDeals() {
    _deals = const SectionState.loading();
    _notify();
    unawaited(_loadDeals(_run));
  }

  void retryTopRated() {
    _topRated = const SectionState.loading();
    _notify();
    unawaited(_loadTopRated(_run));
  }

  Future<ApiException?> _loadCategories(int run) async {
    try {
      final list = await _repository.fetchCategories();
      if (run != _run) return null;
      _categories = SectionState.ready(list);
      _notify();
      return null;
    } on ApiException catch (e) {
      if (run != _run) return null;

      if (_categories.status != SectionStatus.ready)
        _categories = SectionState.failed(e);
      _notify();
      return e;
    }
  }

  Future<ApiException?> _loadDeals(int run) async {
    try {
      final page = await _repository.fetchTop(HomeRank.deals, limit: railSize);
      if (run != _run) return null;
      _deals = SectionState.ready(page.products);
      _notify();
      return null;
    } on ApiException catch (e) {
      if (run != _run) return null;
      if (_deals.status != SectionStatus.ready) _deals = SectionState.failed(e);
      _notify();
      return e;
    }
  }

  Future<ApiException?> _loadTopRated(int run) async {
    try {
      final page = await _repository.fetchTop(
        HomeRank.topRated,
        limit: railSize,
      );
      if (run != _run) return null;
      _topRated = SectionState.ready(page.products);
      _notify();
      return null;
    } on ApiException catch (e) {
      if (run != _run) return null;
      if (_topRated.status != SectionStatus.ready)
        _topRated = SectionState.failed(e);
      _notify();
      return e;
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
