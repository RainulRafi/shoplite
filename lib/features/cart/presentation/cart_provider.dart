import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../products/data/product.dart';
import '../data/cart_repository.dart';
import '../domain/cart_item.dart';
import '../domain/cart_pricing.dart';
import '../domain/cart_reconcile.dart';
import '../domain/coupon.dart';

enum CartStatus { loading, ready, error }

enum AddToCartResult { added, increased, limitReached, outOfStock, notReady }

enum CouponOutcome { applied, unknown, notEligible, emptyInput, notReady }

class CartProvider extends ChangeNotifier {
  final CartRepository _repository;
  final AuthProvider _auth;

  CartProvider(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  String? _owner;

  int _generation = 0;

  CartStatus _status = CartStatus.loading;
  List<CartItem> _items = const [];
  String? _couponCode;
  String? _couponMessage;
  bool _disposed = false;

  Future<void> _writes = Future<void>.value();

  CartStatus get status => _status;
  List<CartItem> get items => _items;
  bool get isEmpty => _items.isEmpty;
  String? get couponCode => _couponCode;
  String? get couponMessage => _couponMessage;

  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  CartTotals get totals => CartPricing.compute(_items, couponCode: _couponCode);

  int quantityOf(int productId) {
    for (final item in _items) {
      if (item.productId == productId) return item.quantity;
    }
    return 0;
  }

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
    final previous = _owner;
    _owner = next;
    unawaited(_loadFor(next, previous));
  }

  Future<void> _loadFor(String? owner, String? previous) async {
    final generation = ++_generation;

    _status = CartStatus.loading;
    _items = const [];
    _couponCode = null;
    _couponMessage = null;
    _notify();
    if (owner == null) return;

    try {
      await _writes;

      if (previous == guestOwner && owner != guestOwner) {
        await _repository.mergeGuestInto(owner);
      }

      final items = await _repository.loadItems(owner);
      final coupon = await _repository.loadCoupon(owner);
      if (generation != _generation) return;
      _items = items;
      _couponCode = coupon;
      _status = CartStatus.ready;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load the cart: $e');
      _status = CartStatus.error;
    }
    _notify();
  }

  void retry() {
    if (_status != CartStatus.error) return;
    unawaited(_loadFor(_owner, null));
  }

  Future<void> reload() async {
    await _writes;
    await _rereadStorage();
  }

  AddToCartResult addProduct(Product product, {int quantity = 1}) {
    final owner = _owner;
    if (owner == null || _status != CartStatus.ready) {
      return AddToCartResult.notReady;
    }
    if (!product.inStock) return AddToCartResult.outOfStock;

    final wanted = quantity < 1 ? 1 : quantity;
    final existing = _lineFor(product.id);

    if (existing == null) {
      final first = wanted > product.stock ? product.stock : wanted;
      final item = CartItem.fromProduct(
        product,
        quantity: first,
        addedAt: DateTime.now(),
      );
      _items = [item, ..._items];
      _persistItem(owner, item);
      _notify();
      return AddToCartResult.added;
    }

    if (existing.quantity >= product.stock) return AddToCartResult.limitReached;

    final total = existing.quantity + wanted;
    final updated = CartItem.fromProduct(
      product,
      quantity: total > product.stock ? product.stock : total,
      addedAt: existing.addedAt,
    );
    _replaceLine(updated);
    _persistItem(owner, updated);
    _notify();
    return AddToCartResult.increased;
  }

  void increment(int productId) {
    final owner = _owner;
    final item = _lineFor(productId);
    if (owner == null || item == null || _status != CartStatus.ready) return;
    if (item.atLimit) return;
    _setQuantity(owner, item, item.quantity + 1);
  }

  void decrement(int productId) {
    final owner = _owner;
    final item = _lineFor(productId);
    if (owner == null || item == null || _status != CartStatus.ready) return;
    if (item.quantity <= 1) return;
    _setQuantity(owner, item, item.quantity - 1);
  }

  CartItem? remove(int productId) {
    final owner = _owner;
    final item = _lineFor(productId);
    if (owner == null || item == null || _status != CartStatus.ready) {
      return null;
    }

    _items = _items.where((i) => i.productId != productId).toList();
    _persistRemoval(owner, productId);
    _notify();
    return item;
  }

  void restore(CartItem item) {
    final owner = _owner;
    if (owner == null || _status != CartStatus.ready) return;
    if (_lineFor(item.productId) != null) return;

    _items = [..._items, item]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    _persistItem(owner, item);
    _notify();
  }

  void applyReconcile(ReconcileResult result) {
    final owner = _owner;
    if (owner == null || _status != CartStatus.ready) return;

    final keptIds = {for (final item in result.items) item.productId};
    for (final old in _items) {
      if (!keptIds.contains(old.productId)) {
        _persistRemoval(owner, old.productId);
      }
    }
    for (final item in result.items) {
      _persistItem(owner, item);
    }
    _items = result.items;
    _notify();
  }

  // ---------------- Coupon ----------------

  CouponOutcome applyCoupon(String raw) {
    final owner = _owner;
    if (owner == null || _status != CartStatus.ready) {
      return CouponOutcome.notReady;
    }

    if (raw.trim().isEmpty) {
      _couponMessage = 'Enter a code.';
      _notify();
      return CouponOutcome.emptyInput;
    }

    final coupon = Coupon.find(raw);
    if (coupon == null) {
      _couponMessage = 'That code is not valid.';
      _notify();
      return CouponOutcome.unknown;
    }

    final check = coupon.check(CartPricing.compute(_items).subtotal);
    if (!check.isUsable) {
      _couponMessage = check.problem;
      _notify();
      return CouponOutcome.notEligible;
    }

    _couponCode = coupon.code;
    _couponMessage = null;
    _persistCoupon(owner, coupon.code);
    _notify();
    return CouponOutcome.applied;
  }

  void removeCoupon() {
    final owner = _owner;
    if (owner == null || _status != CartStatus.ready) return;
    _couponCode = null;
    _couponMessage = null;
    _persistCoupon(owner, null);
    _notify();
  }

  void clearCouponMessage() {
    if (_couponMessage == null) return;
    _couponMessage = null;
    _notify();
  }

  CartItem? _lineFor(int productId) {
    for (final item in _items) {
      if (item.productId == productId) return item;
    }
    return null;
  }

  void _replaceLine(CartItem updated) {
    _items = [
      for (final item in _items)
        item.productId == updated.productId ? updated : item,
    ];
  }

  void _setQuantity(String owner, CartItem item, int quantity) {
    final updated = item.copyWith(quantity: quantity);
    _replaceLine(updated);
    _persistItem(owner, updated);
    _notify();
  }

  void _persistItem(String owner, CartItem item) =>
      _enqueue(() => _repository.saveItem(owner, item));

  void _persistRemoval(String owner, int productId) =>
      _enqueue(() => _repository.removeItem(owner, productId));

  void _persistCoupon(String owner, String? code) =>
      _enqueue(() => _repository.saveCoupon(owner, code));

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) => write()).catchError((Object e) {
      if (kDebugMode) debugPrint('Cart write failed: $e');

      return _rereadStorage();
    });
  }

  Future<void> _rereadStorage() async {
    final owner = _owner;
    if (owner == null) return;
    try {
      final items = await _repository.loadItems(owner);
      final coupon = await _repository.loadCoupon(owner);
      if (owner != _owner) return;
      _items = items;
      _couponCode = coupon;
      _status = CartStatus.ready;
    } on Exception {
      _status = CartStatus.error;
    }
    _notify();
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
