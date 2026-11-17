import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/data_status.dart';
import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../products/data/product.dart';
import '../data/wishlist_repository.dart';
import '../domain/wishlist_item.dart';

enum WishlistResult { added, removed, signInRequired, failed }

class WishlistProvider extends ChangeNotifier {
  final WishlistRepository _repository;
  final AuthProvider _auth;

  WishlistProvider(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  String? _owner;
  int _generation = 0;
  DataStatus _status = DataStatus.ready;
  List<WishlistItem> _items = const [];
  Set<int> _ids = const {};
  bool _disposed = false;

  Future<void> _loading = Future<void>.value();

  DataStatus get status => _status;
  List<WishlistItem> get items => _items;
  int get count => _items.length;

  bool contains(int productId) => _ids.contains(productId);

  void _onAuthChanged() {
    final next = _auth.userOwner;
    if (next == _owner) return;
    _owner = next;
    _loading = _loadFor(next);
  }

  Future<void> _loadFor(String? owner) async {
    final generation = ++_generation;

    _setItems(const []);
    _status = owner == null ? DataStatus.ready : DataStatus.loading;
    _notify();
    if (owner == null) return;

    try {
      final list = await _repository.loadAll(owner);
      if (generation != _generation) return;
      _setItems(list);
      _status = DataStatus.ready;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load the wishlist: $e');
      _status = DataStatus.error;
    }
    _notify();
  }

  void retry() {
    if (_status != DataStatus.error) return;
    _loading = _loadFor(_owner);
  }

  Future<WishlistResult> toggle(Product product) async {
    await _loading;

    final owner = _owner;
    if (owner == null) return WishlistResult.signInRequired;
    if (_status != DataStatus.ready) return WishlistResult.failed;

    try {
      if (contains(product.id)) {
        await _repository.remove(owner, product.id);
        if (owner == _owner) {
          _setItems(_items.where((i) => i.productId != product.id).toList());
          _notify();
        }
        return WishlistResult.removed;
      }

      final item = WishlistItem.fromProduct(product, addedAt: DateTime.now());
      await _repository.add(owner, item);
      if (owner == _owner) {
        _setItems([item, ..._items]);
        _notify();
      }
      return WishlistResult.added;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not update the wishlist: $e');
      return WishlistResult.failed;
    }
  }

  Future<WishlistItem?> remove(int productId) async {
    final owner = _owner;
    if (owner == null) return null;

    WishlistItem? removed;
    for (final item in _items) {
      if (item.productId == productId) removed = item;
    }
    if (removed == null) return null;

    try {
      await _repository.remove(owner, productId);
      if (owner == _owner) {
        _setItems(_items.where((i) => i.productId != productId).toList());
        _notify();
      }
      return removed;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not remove from the wishlist: $e');
      return null;
    }
  }

  Future<bool> restore(WishlistItem item) async {
    final owner = _owner;
    if (owner == null || contains(item.productId)) return false;

    try {
      await _repository.add(owner, item);
      if (owner == _owner) {
        final list = [..._items, item]
          ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
        _setItems(list);
        _notify();
      }
      return true;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not restore the wishlist item: $e');
      return false;
    }
  }

  void _setItems(List<WishlistItem> items) {
    _items = items;
    _ids = {for (final item in items) item.productId};
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
