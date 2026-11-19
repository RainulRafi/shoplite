import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../cart/data/cart_repository.dart';
import '../../products/data/product.dart';
import '../data/browsing_repository.dart';
import '../domain/viewed_product.dart';

class BrowsingProvider extends ChangeNotifier {
  static const int maxViewed = 20;
  static const int maxSearches = 8;

  final BrowsingRepository _repository;
  final AuthProvider _auth;

  BrowsingProvider(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  String? _owner;
  int _generation = 0;
  List<ViewedProduct> _viewed = const [];
  List<String> _searches = const [];
  bool _disposed = false;

  Future<void> _writes = Future<void>.value();

  List<ViewedProduct> get viewed => _viewed;
  List<String> get searches => _searches;

  Future<void> flush() => _writes;

  String? _ownerFromAuth() {
    switch (_auth.status) {
      case AuthStatus.unknown:
        return null;
      case AuthStatus.signedOut:
        return guestOwner;
      case AuthStatus.signedIn:
        final id = _auth.userId;
        return id == null ? null : 'user:$id';
    }
  }

  void _onAuthChanged() {
    final next = _ownerFromAuth();
    if (next == _owner) return;
    _owner = next;
    unawaited(_loadFor(next));
  }

  Future<void> _loadFor(String? owner) async {
    final generation = ++_generation;

    _viewed = const [];
    _searches = const [];
    _notify();
    if (owner == null) return;

    try {
      final viewed = await _repository.loadViewed(owner);
      final searches = await _repository.loadSearches(owner);
      if (generation != _generation) return;
      _viewed = viewed;
      _searches = searches;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load browsing history: $e');
    }
    _notify();
  }

  void recordView(Product product) {
    final owner = _owner;
    if (owner == null) return;

    final item = ViewedProduct.fromProduct(product, viewedAt: DateTime.now());
    _viewed = [
      item,
      ..._viewed.where((v) => v.productId != item.productId),
    ].take(maxViewed).toList();
    _enqueue(() => _repository.recordViewed(owner, item, keep: maxViewed));
    _notify();
  }

  void clearViewed() {
    final owner = _owner;
    if (owner == null || _viewed.isEmpty) return;
    _viewed = const [];
    _enqueue(() => _repository.clearViewed(owner));
    _notify();
  }

  void recordSearch(String raw) {
    final owner = _owner;
    final term = raw.trim();
    if (owner == null || term.length < 2) return;

    _searches = [
      term,
      ..._searches.where((s) => s.toLowerCase() != term.toLowerCase()),
    ].take(maxSearches).toList();
    _enqueue(() => _repository.recordSearch(owner, term, keep: maxSearches));
    _notify();
  }

  void removeSearch(String term) {
    final owner = _owner;
    if (owner == null) return;
    _searches = _searches.where((s) => s != term).toList();
    _enqueue(() => _repository.removeSearch(owner, term));
    _notify();
  }

  void clearSearches() {
    final owner = _owner;
    if (owner == null || _searches.isEmpty) return;
    _searches = const [];
    _enqueue(() => _repository.clearSearches(owner));
    _notify();
  }

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) => write()).catchError((Object e) {
      if (kDebugMode) debugPrint('Browsing history write failed: $e');
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
