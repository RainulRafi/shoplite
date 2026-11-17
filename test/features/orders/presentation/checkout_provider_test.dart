import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/core/state/data_status.dart';
import 'package:shoplite/features/addresses/data/sqlite_address_repository.dart';
import 'package:shoplite/features/addresses/presentation/address_provider.dart';
import 'package:shoplite/features/cart/data/sqlite_cart_repository.dart';
import 'package:shoplite/features/cart/domain/cart_reconcile.dart';
import 'package:shoplite/features/cart/presentation/cart_provider.dart';
import 'package:shoplite/features/orders/data/sqlite_order_repository.dart';
import 'package:shoplite/features/orders/domain/delivery_method.dart';
import 'package:shoplite/features/orders/domain/order.dart';
import 'package:shoplite/features/orders/domain/payment.dart';
import 'package:shoplite/features/orders/presentation/checkout_provider.dart';
import 'package:shoplite/features/products/data/product_repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/order_fixtures.dart';
import '../../../helpers/test_support.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const _noInternet = ApiException(
  type: ApiErrorType.noConnection,
  message: 'No internet',
);
const _notFound = ApiException(
  type: ApiErrorType.notFound,
  message: 'Not found',
);

void main() {
  late Database db;
  late AuthRig rig;
  late SqliteCartRepository cartRepo;
  late CartProvider cart;
  late AddressProvider addresses;
  late SqliteOrderRepository orders;
  late MockProductRepository products;
  late List<CheckoutProvider> made;
  late List<Order> placedCallbacks;

  setUp(() async {
    db = await openTestDatabase();
    rig = AuthRig();
    await rig.auth.restore();
    cartRepo = SqliteCartRepository(() async => db);
    cart = CartProvider(cartRepo, rig.auth);
    addresses = AddressProvider(
      SqliteAddressRepository(() async => db),
      rig.auth,
    );
    orders = SqliteOrderRepository(() async => db);
    products = MockProductRepository();
    made = [];
    placedCallbacks = [];

    await rig.signIn();
    await waitUntil(
      () =>
          cart.status == CartStatus.ready &&
          addresses.status == DataStatus.ready,
    );
  });

  tearDown(() async {
    for (final checkout in made) {
      checkout.dispose();
    }
    cart.dispose();
    addresses.dispose();
    rig.dispose();
    await db.close();
  });

  CheckoutProvider makeCheckout({String key = 'key-1'}) {
    final checkout = CheckoutProvider(
      products: products,
      orders: orders,
      cart: cart,
      addresses: addresses,
      auth: rig.auth,
      idempotencyKey: key,
      onPlaced: placedCallbacks.add,
      clock: () => t0,
    );
    made.add(checkout);
    return checkout;
  }

  void serverHas(
    int id, {
    double price = 10,
    int stock = 5,
    double discount = 0,
  }) {
    when(() => products.fetchProduct(id)).thenAnswer(
      (_) async =>
          testProduct(id, price: price, stock: stock, discount: discount),
    );
  }

  Future<void> addToCart(int id, {int quantity = 1, double price = 10}) async {
    cart.addProduct(testProduct(id, price: price), quantity: quantity);
    await cart.flush();
  }

  Future<void> saveAddress({String name = 'Rahim Uddin'}) async {
    expect(await addresses.save(testAddress(name: name)), AddressResult.saved);
  }

  group('checking the cart', () {
    test('unchanged products leave the cart alone and are ready', () async {
      await addToCart(1, quantity: 2);
      serverHas(1);
      final checkout = makeCheckout();

      await checkout.verify();

      expect(checkout.status, CheckoutStatus.ready);
      expect(checkout.changes, isEmpty);
      expect(cart.quantityOf(1), 2);
    });

    test('a new price is applied to the cart and reported', () async {
      await addToCart(1, quantity: 2);
      serverHas(1, price: 12);
      final checkout = makeCheckout();

      await checkout.verify();
      await cart.flush();

      expect(checkout.status, CheckoutStatus.ready);
      expect(checkout.changes.single.type, CartChangeType.priceChanged);
      expect(cart.items.single.unitPrice.cents, 1200);
      expect(checkout.totals.subtotal.cents, 2400);

      expect((await cartRepo.loadItems('user:1')).single.unitPrice.cents, 1200);
    });

    test(
      'a product that ran out is removed, and an empty cart ends checkout',
      () async {
        await addToCart(1);
        serverHas(1, stock: 0);
        final checkout = makeCheckout();

        await checkout.verify();

        expect(checkout.status, CheckoutStatus.empty);
        expect(checkout.changes.single.type, CartChangeType.removedOutOfStock);
        expect(cart.isEmpty, isTrue);
      },
    );

    test('a product that no longer exists is removed', () async {
      await addToCart(1);
      await addToCart(2);
      serverHas(1);
      when(() => products.fetchProduct(2))
          .thenAnswer((_) => Future.error(_notFound));
      final checkout = makeCheckout();

      await checkout.verify();

      expect(checkout.status, CheckoutStatus.ready);
      expect(cart.items.map((i) => i.productId), [1]);
      expect(checkout.changes.single.type, CartChangeType.removedUnavailable);
    });

    test(
      'with no internet the check fails, ordering is blocked, and retry works',
      () async {
        await addToCart(1);
        await saveAddress();
        when(() => products.fetchProduct(1))
            .thenAnswer((_) => Future.error(_noInternet));
        final checkout = makeCheckout();

        await checkout.verify();

        expect(checkout.status, CheckoutStatus.verifyFailed);
        expect(checkout.verifyMessage, 'No internet');
        expect(await checkout.placeOrder(), PlaceResult.notReady);
        expect(await orders.loadAll('user:1'), isEmpty);

        serverHas(1);
        await checkout.verify();
        expect(checkout.status, CheckoutStatus.ready);
      },
    );

    test('an empty cart goes straight to the empty state', () async {
      final checkout = makeCheckout();

      await checkout.verify();

      expect(checkout.status, CheckoutStatus.empty);
    });
  });

  group('choosing', () {
    test(
      'the default address is chosen for you, and you can change it',
      () async {
        await saveAddress(name: 'First Person');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await saveAddress(name: 'Second Person');
        final checkout = makeCheckout();

        expect(checkout.selectedAddress!.fullName, 'First Person');

        final second = addresses.addresses.firstWhere(
          (a) => a.fullName == 'Second Person',
        );
        checkout.selectAddress(second.id!);
        expect(checkout.selectedAddress!.fullName, 'Second Person');
      },
    );

    test('a newly added address can be chosen as the newest', () async {
      await saveAddress(name: 'First Person');
      final checkout = makeCheckout();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await saveAddress(name: 'Second Person');

      checkout.selectNewestAddress();

      expect(checkout.selectedAddress!.fullName, 'Second Person');
    });

    test('with no address you cannot place the order', () async {
      await addToCart(1);
      serverHas(1);
      final checkout = makeCheckout();
      await checkout.verify();

      expect(checkout.canPlace, isFalse);
      expect(await checkout.placeOrder(), PlaceResult.noAddress);
    });

    test('express changes the total', () async {
      await addToCart(1, quantity: 2); // $20
      serverHas(1);
      final checkout = makeCheckout();
      await checkout.verify();

      expect(checkout.totals.shipping.cents, 500);
      checkout.setDelivery(DeliveryMethod.express);
      expect(checkout.totals.shipping.cents, 1200);
      expect(checkout.totals.total.cents, 3200);
    });
  });

  group('placing the order', () {
    Future<CheckoutProvider> readyCheckout({String key = 'key-1'}) async {
      await addToCart(1, quantity: 2);
      await saveAddress();
      serverHas(1);
      final checkout = makeCheckout(key: key);
      await checkout.verify();
      expect(checkout.status, CheckoutStatus.ready);
      return checkout;
    }

    test('cash on delivery saves the order and empties the cart', () async {
      final checkout = await readyCheckout();
      final totalShown = checkout.totals.total;

      expect(await checkout.placeOrder(), PlaceResult.placed);

      final saved = await orders.loadAll('user:1');
      expect(saved, hasLength(1));
      expect(saved.single.paymentStatus, PaymentStatus.payOnDelivery);
      expect(saved.single.total, totalShown);
      expect(checkout.placedOrder!.id, saved.single.id);
      expect(cart.isEmpty, isTrue);
      expect(await cartRepo.loadItems('user:1'), isEmpty);
      expect(placedCallbacks.single.id, saved.single.id);
    });

    test('the order keeps the chosen address, delivery and payment', () async {
      final checkout = await readyCheckout();
      checkout.setDelivery(DeliveryMethod.express);

      await checkout.placeOrder();

      final order = (await orders.loadAll('user:1')).single;
      expect(order.deliveryMethod, DeliveryMethod.express);
      expect(order.shipping.cents, 1200);
      expect(order.address.fullName, 'Rahim Uddin');
      expect(order.placedAt, t0);
    });

    test('online payment needs a successful payment first', () async {
      final checkout = await readyCheckout();
      checkout.setPayment(PaymentMethod.onlineDemo);

      expect(await checkout.placeOrder(), PlaceResult.paymentRequired);
      expect(await orders.loadAll('user:1'), isEmpty);
      expect(cart.isEmpty, isFalse);

      expect(
        await checkout.placeOrder(demoPaymentSucceeded: true),
        PlaceResult.placed,
      );
      final order = (await orders.loadAll('user:1')).single;
      expect(order.paymentMethod, PaymentMethod.onlineDemo);
      expect(order.paymentStatus, PaymentStatus.paidDemo);
    });

    test('tapping twice at once places exactly one order', () async {
      final checkout = await readyCheckout();

      final results = await Future.wait([
        checkout.placeOrder(),
        checkout.placeOrder(),
      ]);

      expect(results.where((r) => r == PlaceResult.placed), hasLength(1));
      expect(
        results.where((r) => r == PlaceResult.alreadyPlacing),
        hasLength(1),
      );
      expect(await orders.loadAll('user:1'), hasLength(1));

      expect(await checkout.placeOrder(), PlaceResult.placed);
      expect(await orders.loadAll('user:1'), hasLength(1));
      expect(placedCallbacks, hasLength(1));
    });

    test('a retry with the same key after a lost reply does not duplicate the order', () async {
      final first = await readyCheckout(key: 'same-attempt');
      await first.placeOrder();

      await addToCart(1, quantity: 2);
      final retry = makeCheckout(key: 'same-attempt');
      await retry.verify();
      expect(await retry.placeOrder(), PlaceResult.placed);

      expect(await orders.loadAll('user:1'), hasLength(1));
    });

    test('a failure leaves the cart as it was and says so', () async {
      final checkout = await readyCheckout();

      await db.update('cart_items', {'quantity': 1}, where: 'product_id = 1');
      await db.execute('DROP TABLE order_items');

      final result = await checkout.placeOrder();

      expect(result, PlaceResult.failed);
      expect(checkout.placeError, contains('Nothing was charged'));
      expect(checkout.placing, isFalse);
      expect(await cartRepo.loadItems('user:1'), isNotEmpty);
      expect(
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM orders')),
        0,
      );
    });

    test('nothing can be placed when signed out', () async {
      final checkout = await readyCheckout();
      await rig.auth.signOut();

      expect(await checkout.placeOrder(), PlaceResult.notSignedIn);
    });
  });
}
