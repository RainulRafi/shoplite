import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../addresses/domain/address.dart';
import '../../addresses/presentation/address_provider.dart';
import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../cart/domain/cart_item.dart';
import '../../cart/domain/cart_reconcile.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../products/data/product.dart';
import '../../products/data/product_repository.dart';
import '../data/order_repository.dart';
import '../domain/checkout_pricing.dart';
import '../domain/delivery_method.dart';
import '../domain/order.dart';
import '../domain/payment.dart';

enum CheckoutStatus { verifying, ready, verifyFailed, empty }

enum PlaceResult {
  placed,
  notSignedIn,
  notReady,
  emptyCart,
  noAddress,
  paymentRequired,
  alreadyPlacing,
  failed,
}

class CheckoutProvider extends ChangeNotifier {
  final ProductRepository _products;
  final OrderRepository _orders;
  final CartProvider _cart;
  final AddressProvider _addresses;
  final AuthProvider _auth;
  final String _idempotencyKey;
  final void Function(Order order)? _onPlaced;
  final DateTime Function() _clock;

  CheckoutProvider({
    required this._products,
    required this._orders,
    required this._cart,
    required this._addresses,
    required this._auth,
    required this._idempotencyKey,
    this._onPlaced,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _cart.addListener(notifyListeners);
    _addresses.addListener(notifyListeners);
  }

  CheckoutStatus _status = CheckoutStatus.verifying;
  String? _verifyMessage;
  List<CartChange> _changes = const [];

  DeliveryMethod _delivery = DeliveryMethod.standard;
  PaymentMethod _payment = PaymentMethod.cashOnDelivery;
  int? _selectedAddressId;

  bool _placing = false;
  Order? _placed;
  String? _placeError;

  int _verifyRun = 0;
  bool _disposed = false;

  CheckoutStatus get status => _status;
  String? get verifyMessage => _verifyMessage;
  List<CartChange> get changes => _changes;
  DeliveryMethod get delivery => _delivery;
  PaymentMethod get payment => _payment;
  bool get placing => _placing;
  Order? get placedOrder => _placed;
  String? get placeError => _placeError;

  List<CartItem> get items => _cart.items;
  String? get couponCode => _cart.couponCode;
  List<Address> get addresses => _addresses.addresses;

  CheckoutTotals get totals =>
      CheckoutPricing.compute(items, couponCode: couponCode, method: _delivery);

  Address? get selectedAddress {
    final list = _addresses.addresses;
    if (list.isEmpty) return null;
    if (_selectedAddressId != null) {
      for (final a in list) {
        if (a.id == _selectedAddressId) return a;
      }
    }
    return _addresses.defaultAddress ?? list.first;
  }

  bool get canPlace =>
      _status == CheckoutStatus.ready &&
      !_placing &&
      items.isNotEmpty &&
      selectedAddress != null;

  Future<void> verify() async {
    final run = ++_verifyRun;
    _status = CheckoutStatus.verifying;
    _verifyMessage = null;
    _notify();

    await _cart.flush();
    await _waitForCart();
    if (run != _verifyRun) return;

    if (_cart.status == CartStatus.error) {
      _verifyMessage = 'Could not read your cart from this phone.';
      _status = CheckoutStatus.verifyFailed;
      _notify();
      return;
    }

    final current = List<CartItem>.of(_cart.items);
    if (current.isEmpty) {
      _changes = const [];
      _status = CheckoutStatus.empty;
      _notify();
      return;
    }

    final fresh = <int, Product?>{};
    try {
      await Future.wait(
        current.map((item) async {
          try {
            fresh[item.productId] = await _products.fetchProduct(
              item.productId,
            );
          } on ApiException catch (e) {
            if (e.type != ApiErrorType.notFound) rethrow;
            fresh[item.productId] = null;
          }
        }),
      );
    } on ApiException catch (e) {
      if (run != _verifyRun) return;
      _verifyMessage = e.message;
      _status = CheckoutStatus.verifyFailed;
      _notify();
      return;
    }
    if (run != _verifyRun) return;

    final result = reconcileCart(current, fresh);
    _cart.applyReconcile(result);
    _changes = result.changes;
    _status = result.items.isEmpty
        ? CheckoutStatus.empty
        : CheckoutStatus.ready;
    _notify();
  }

  Future<void> _waitForCart() async {
    if (_cart.status != CartStatus.loading) return;

    final done = Completer<void>();
    void check() {
      if (_cart.status != CartStatus.loading && !done.isCompleted) {
        done.complete();
      }
    }

    _cart.addListener(check);
    try {
      await done.future.timeout(const Duration(seconds: 10));
      // ignore: empty_catches
    } on TimeoutException {
    } finally {
      _cart.removeListener(check);
    }
  }

  void dismissChanges() {
    if (_changes.isEmpty) return;
    _changes = const [];
    _notify();
  }

  void selectAddress(int id) {
    _selectedAddressId = id;
    _notify();
  }

  void selectNewestAddress() {
    final list = _addresses.addresses;
    if (list.isEmpty) return;
    var newest = list.first;
    for (final a in list) {
      final isNewer =
          a.updatedAt.isAfter(newest.updatedAt) ||
          (a.updatedAt == newest.updatedAt && (a.id ?? 0) > (newest.id ?? 0));
      if (isNewer) newest = a;
    }
    _selectedAddressId = newest.id;
    _notify();
  }

  void setDelivery(DeliveryMethod method) {
    _delivery = method;
    _notify();
  }

  void setPayment(PaymentMethod method) {
    _payment = method;
    _notify();
  }

  Future<PlaceResult> placeOrder({bool demoPaymentSucceeded = false}) async {
    if (_placing) return PlaceResult.alreadyPlacing;

    if (_placed != null) return PlaceResult.placed;

    final owner = _auth.userOwner;
    if (owner == null) return PlaceResult.notSignedIn;
    if (_status != CheckoutStatus.ready) return PlaceResult.notReady;
    if (_cart.items.isEmpty) return PlaceResult.emptyCart;
    final address = selectedAddress;
    if (address == null) return PlaceResult.noAddress;
    if (_payment == PaymentMethod.onlineDemo && !demoPaymentSucceeded) {
      return PlaceResult.paymentRequired;
    }

    _placing = true;
    _placeError = null;
    _notify();

    try {
      await _cart.flush();

      final items = List<CartItem>.of(_cart.items);
      final totals = CheckoutPricing.compute(
        items,
        couponCode: _cart.couponCode,
        method: _delivery,
      );

      final placed = await _orders.place(
        PlaceOrderRequest(
          ownerId: owner,
          idempotencyKey: _idempotencyKey,
          placedAt: _clock(),
          items: items,
          address: OrderAddress.fromAddress(address),
          deliveryMethod: _delivery,
          paymentMethod: _payment,
          paymentStatus: _payment == PaymentMethod.onlineDemo
              ? PaymentStatus.paidDemo
              : PaymentStatus.payOnDelivery,
          totals: totals,
        ),
      );

      _placed = placed.order;
      _onPlaced?.call(placed.order);
      await _cart.reload();
      return PlaceResult.placed;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not place the order: $e');
      _placeError = 'We could not place your order. Nothing was charged. Please try again.';
      return PlaceResult.failed;
    } finally {
      _placing = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cart.removeListener(notifyListeners);
    _addresses.removeListener(notifyListeners);
    super.dispose();
  }
}
