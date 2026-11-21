import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../orders/presentation/orders_provider.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';
import '../domain/notification_builder.dart';

class NotificationsProvider extends ChangeNotifier {
  final NotificationsRepository _repository;
  final OrdersProvider _orders;
  final AuthProvider _auth;
  final DateTime Function() _clock;
  Timer? _timer;

  NotificationsProvider(
    this._repository,
    this._orders,
    this._auth, {
    DateTime Function()? clock,
    Duration? tickEvery = const Duration(seconds: 20),
  }) : _clock = clock ?? DateTime.now {
    _auth.addListener(_onAuthChanged);
    _orders.addListener(_notify);
    if (tickEvery != null) {
      _timer = Timer.periodic(tickEvery, (_) => _notify());
    }
    _onAuthChanged();
  }

  String? _owner;
  int _generation = 0;
  Set<String> _read = const {};
  bool _loaded = false;
  bool _disposed = false;

  Future<void> _writes = Future<void>.value();

  bool get isReady => _loaded;

  Future<void> flush() => _writes;

  List<AppNotification> get items => _owner == null
      ? const []
      : buildNotifications(_orders.orders, _clock(), _read);

  int get unreadCount => _loaded ? items.where((n) => !n.read).length : 0;

  void _onAuthChanged() {
    final next = _auth.userOwner;
    if (next == _owner) return;
    _owner = next;
    unawaited(_loadFor(next));
  }

  Future<void> _loadFor(String? owner) async {
    final generation = ++_generation;

    _read = const {};
    _loaded = owner == null;
    _notify();
    if (owner == null) return;

    try {
      final read = await _repository.loadRead(owner);
      if (generation != _generation) return;
      _read = read;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load read marks: $e');
    }
    _loaded = true;
    _notify();
  }

  void markRead(String key) {
    final owner = _owner;
    if (owner == null || _read.contains(key)) return;
    _read = {..._read, key};
    _enqueue(() => _repository.markRead(owner, [key]));
    _notify();
  }

  void markAllRead() {
    final owner = _owner;
    if (owner == null) return;
    final keys = items.where((n) => !n.read).map((n) => n.key).toList();
    if (keys.isEmpty) return;
    _read = {..._read, ...keys};
    _enqueue(() => _repository.markRead(owner, keys));
    _notify();
  }

  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) => write()).catchError((Object e) {
      if (kDebugMode) debugPrint('Could not save read marks: $e');
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _auth.removeListener(_onAuthChanged);
    _orders.removeListener(_notify);
    super.dispose();
  }
}
