import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../data/product.dart';
import '../data/product_repository.dart';
import '../domain/product_filtering.dart';
import '../domain/product_query.dart';

enum LoadStatus { loading, success, error }

class ProductListProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final Duration _debounceDelay;

  ProductListProvider(
    this._repository, {
    Duration debounce = const Duration(milliseconds: 400),
  }) : _debounceDelay = debounce;

  static const int pageSize = 20;

  ProductQuery _query = const ProductQuery();
  LoadStatus _status = LoadStatus.loading;
  ApiException? _error;

  List<Product> _products = const [];
  int _total = 0;

  List<Product> _filtered = const [];
  int _shown = 0;

  final Map<String, List<Product>> _sources = {};

  bool _loadingMore = false;
  ApiException? _loadMoreError;

  int _generation = 0;
  bool _firstPageInFlight = false;

  int _searchSyncToken = 0;

  Timer? _debounce;

  LoadStatus get status => _status;
  List<Product> get products => _products;
  int get total => _total;
  ApiException? get error => _error;
  ProductQuery get query => _query;
  bool get isLoadingMore => _loadingMore;
  ApiException? get loadMoreError => _loadMoreError;
  int get searchSyncToken => _searchSyncToken;

  bool get hasMore => _query.isPagedOnServer
      ? _products.length < _total
      : _shown < _filtered.length;

  Future<void> load() async {
    if (_firstPageInFlight) return;
    await _loadFirstPage(dropCache: true);
  }

  void onQueryChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () => search(text));
  }

  Future<void> search(String raw) {
    _debounce?.cancel();
    return _changeQuery(_query.copyWith(search: raw.trim()));
  }

  Future<void> setSort(ProductSort sort) =>
      _changeQuery(_query.copyWith(sort: sort));

  Future<void> setCategory(String? slug) => _changeQuery(
    slug == null
        ? _query.copyWith(clearCategory: true)
        : _query.copyWith(category: slug),
  );

  Future<void> setFilters(ProductFilters filters) =>
      _changeQuery(_query.copyWith(filters: filters));

  Future<void> applyRefinements({
    String? category,
    required ProductFilters filters,
  }) => _changeQuery(
    _query.copyWith(
      category: category,
      clearCategory: category == null,
      filters: filters,
    ),
  );

  Future<void> clearRefinements() =>
      _changeQuery(ProductQuery(search: _query.search));

  Future<void> applyPreset(ProductQuery preset) {
    _debounce?.cancel();
    _searchSyncToken++;
    notifyListeners();
    return _changeQuery(preset);
  }

  Future<void> _changeQuery(ProductQuery next) {
    if (next == _query) return Future<void>.value();
    _query = next;
    return _loadFirstPage();
  }

  Future<void> _loadFirstPage({bool dropCache = false}) async {
    final generation = ++_generation;
    _firstPageInFlight = true;
    _loadingMore = false;
    _loadMoreError = null;

    final query = _query;
    if (dropCache) _sources.clear();

    if (!query.isPagedOnServer) {
      final cached = _sources[query.sourceKey];
      if (cached != null) {
        _applyLocal(cached, query);
        _status = LoadStatus.success;
        _error = null;
        _firstPageInFlight = false;
        notifyListeners();
        return;
      }
    }

    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();

    try {
      if (query.isPagedOnServer) {
        final page = await _repository.fetchProducts(
          limit: pageSize,
          skip: 0,
          query: query.search.isEmpty ? null : query.search,
        );
        if (generation != _generation) return;
        _products = page.products;
        _total = page.total;
      } else {
        final source = await _fetchSource(query);
        if (generation != _generation) return;
        _sources[query.sourceKey] = source;
        _applyLocal(source, query);
      }
      _status = LoadStatus.success;
    } on ApiException catch (e) {
      if (generation != _generation) return;
      _error = e;
      _status = LoadStatus.error;
    } finally {
      if (generation == _generation) _firstPageInFlight = false;
    }

    notifyListeners();
  }

  Future<List<Product>> _fetchSource(ProductQuery q) async {
    if (q.search.isNotEmpty) {
      final page = await _repository.fetchProducts(
        limit: 0,
        skip: 0,
        query: q.search,
      );
      return page.products;
    }
    if (q.category != null) {
      final page = await _repository.fetchByCategory(q.category!);
      return page.products;
    }
    final page = await _repository.fetchProducts(limit: 0, skip: 0);
    return page.products;
  }

  void _applyLocal(List<Product> source, ProductQuery query) {
    _filtered = applyQuery(source, query);
    _shown = math.min(pageSize, _filtered.length);
    _products = _filtered.take(_shown).toList();
    _total = _filtered.length;
  }

  Future<ApiException?> refresh() async {
    final generation = ++_generation;
    _firstPageInFlight = true;

    if (_loadingMore || _loadMoreError != null) {
      _loadingMore = false;
      _loadMoreError = null;
      notifyListeners();
    }

    final query = _query;
    try {
      if (query.isPagedOnServer) {
        final page = await _repository.fetchProducts(
          limit: pageSize,
          skip: 0,
          query: query.search.isEmpty ? null : query.search,
        );
        if (generation != _generation) return null;
        _products = page.products;
        _total = page.total;
      } else {
        final source = await _fetchSource(query);
        if (generation != _generation) return null;
        _sources
          ..clear()
          ..[query.sourceKey] = source;
        _applyLocal(source, query);
      }
      _status = LoadStatus.success;
      _error = null;
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (generation != _generation) return null;
      return e;
    } finally {
      if (generation == _generation) _firstPageInFlight = false;
    }
  }

  Future<void> loadMore() async {
    if (_status != LoadStatus.success) return;
    if (_loadingMore || _firstPageInFlight) return;
    if (!hasMore) return;

    if (!_query.isPagedOnServer) {
      _shown = math.min(_shown + pageSize, _filtered.length);
      _products = _filtered.take(_shown).toList();
      notifyListeners();
      return;
    }

    if (_loadMoreError != null) return;

    final generation = _generation;
    final search = _query.search.isEmpty ? null : _query.search;
    _loadingMore = true;
    notifyListeners();

    try {
      final page = await _repository.fetchProducts(
        limit: pageSize,
        skip: _products.length,
        query: search,
      );
      if (generation != _generation) return;

      final known = _products.map((p) => p.id).toSet();
      final fresh = page.products.where((p) => !known.contains(p.id)).toList();

      if (fresh.isEmpty) {
        _total = _products.length;
      } else {
        _products = [..._products, ...fresh];
        _total = page.total;
      }
    } on ApiException catch (e) {
      if (generation != _generation) return;
      _loadMoreError = e;
    } finally {
      if (generation == _generation) _loadingMore = false;
    }

    notifyListeners();
  }

  Future<void> retryLoadMore() async {
    _loadMoreError = null;
    await loadMore();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
