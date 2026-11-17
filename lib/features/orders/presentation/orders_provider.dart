import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/data_status.dart';
import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/order_repository.dart';
import '../domain/order.dart';

enum CancelResult { cancelled, notAllowed, failed }

class OrdersProvider extends ChangeNotifier {
  final OrderRepository _repository;
  final AuthProvider _auth;

  OrdersProvider(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  String? _owner;
  int _generation = 0;
  DataStatus _status = DataStatus.ready;
  List<Order> _orders = const [];
  bool _disposed = false;

  DataStatus get status => _status;
  List<Order> get orders => _orders;

  Order? byId(int id) {
    for (final order in _orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  void _onAuthChanged() {
    final next = _auth.userOwner;
    if (next == _owner) return;
    _owner = next;
    unawaited(_loadFor(next));
  }

  Future<void> _loadFor(String? owner) async {
    final generation = ++_generation;

    _orders = const [];
    _status = owner == null ? DataStatus.ready : DataStatus.loading;
    _notify();
    if (owner == null) return;

    try {
      final list = await _repository.loadAll(owner);
      if (generation != _generation) return;
      _orders = list;
      _status = DataStatus.ready;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load orders: $e');
      _status = DataStatus.error;
    }
    _notify();
  }

  void retry() {
    if (_status != DataStatus.error) return;
    unawaited(_loadFor(_owner));
  }

  void addPlaced(Order order) {
    _orders = [order, ..._orders.where((o) => o.id != order.id)];
    _notify();
  }

  Future<CancelResult> cancel(Order order, {DateTime? now}) async {
    final owner = _owner;
    if (owner == null) return CancelResult.failed;

    try {
      final ok = await _repository.cancel(
        owner,
        order.id,
        now ?? DateTime.now(),
      );
      if (!ok) return CancelResult.notAllowed;

      final fresh = await _repository.load(owner, order.id);
      if (fresh != null && owner == _owner) {
        _orders = [for (final o in _orders) o.id == fresh.id ? fresh : o];
        _notify();
      }
      return CancelResult.cancelled;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not cancel the order: $e');
      return CancelResult.failed;
    }
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
