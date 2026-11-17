import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/core/storage/token_store.dart';
import 'package:shoplite/features/auth/data/auth_repository.dart';
import 'package:shoplite/features/auth/data/auth_session.dart';
import 'package:shoplite/features/auth/data/user_profile.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/cart/data/cart_repository.dart';
import 'package:shoplite/features/cart/domain/cart_item.dart';
import 'package:shoplite/features/cart/presentation/cart_provider.dart';
import 'package:shoplite/features/products/data/product.dart';

import '../../../helpers/fake_cart_repository.dart';
import '../../../helpers/fake_token_store.dart';

import 'package:shoplite/features/cart/domain/cart_reconcile.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

const _tokens = AuthTokens(accessToken: 'A', refreshToken: 'R');
const _emily = UserProfile(id: 1, username: 'emilys');

Product _p(int id, {double price = 10, double discount = 0, int stock = 5}) =>
    Product(
      id: id,
      title: 'P$id',
      price: price,
      discountPercentage: discount,
      stock: stock,
    );

CartItem _item(int id, {int qty = 1}) => CartItem(
  productId: id,
  title: 'P$id',
  thumbnail: '',
  listPrice: const Money(1000),
  unitPrice: const Money(1000),
  discountPercent: 0,
  quantity: qty,
  maxQuantity: 5,
  addedAt: DateTime.fromMillisecondsSinceEpoch(id * 1000),
);

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  late MockAuthRepository authRepo;
  late FakeCartRepository repo;
  late AuthProvider auth;
  late CartProvider cart;

  setUp(() {
    authRepo = MockAuthRepository();
    repo = FakeCartRepository();
    auth = AuthProvider(authRepo, FakeTokenStore());

    when(
      () => authRepo.login(
        username: any(named: 'username'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const AuthSession(tokens: _tokens, user: _emily));
  });

  tearDown(() {
    cart.dispose();
    auth.dispose();
  });

  Future<void> startAsGuest() async {
    await auth.restore();
    cart = CartProvider(repo, auth);
    await settle();
  }

  group('adding and changing', () {
    test('starts empty and ready for a guest', () async {
      await startAsGuest();
      expect(cart.status, CartStatus.ready);
      expect(cart.isEmpty, isTrue);
    });

    test(
      'adding a product shows it at once and saves it under the guest',
      () async {
        await startAsGuest();

        final result = cart.addProduct(_p(1));
        expect(result, AddToCartResult.added);
        expect(cart.itemCount, 1);

        await settle();
        expect(repo.lines[guestOwner]![1]!.quantity, 1);
      },
    );

    test('adding it again increases the quantity, up to the stock', () async {
      await startAsGuest();

      expect(cart.addProduct(_p(1, stock: 2)), AddToCartResult.added);
      expect(cart.addProduct(_p(1, stock: 2)), AddToCartResult.increased);
      expect(cart.addProduct(_p(1, stock: 2)), AddToCartResult.limitReached);
      expect(cart.quantityOf(1), 2);
    });

    test('an out of stock product cannot be added', () async {
      await startAsGuest();

      expect(cart.addProduct(_p(1, stock: 0)), AddToCartResult.outOfStock);
      expect(cart.isEmpty, isTrue);
    });

    test(
      'several quick taps are all counted and the last value is saved',
      () async {
        await startAsGuest();
        cart.addProduct(_p(1, stock: 10));

        for (var i = 0; i < 4; i++) {
          cart.increment(1);
        }
        expect(cart.quantityOf(1), 5);

        await settle();
        expect(repo.lines[guestOwner]![1]!.quantity, 5);
      },
    );

    test('increment stops at the limit and decrement stops at one', () async {
      await startAsGuest();
      cart.addProduct(_p(1, stock: 2));

      cart.increment(1);
      cart.increment(1);
      expect(cart.quantityOf(1), 2);

      cart.decrement(1);
      cart.decrement(1);
      expect(cart.quantityOf(1), 1);
    });

    test('a removed line can be restored', () async {
      await startAsGuest();
      cart.addProduct(_p(1));

      final removed = cart.remove(1);
      expect(removed, isNotNull);
      expect(cart.isEmpty, isTrue);
      await settle();
      expect(repo.lines[guestOwner]!.containsKey(1), isFalse);

      cart.restore(removed!);
      await settle();
      expect(cart.quantityOf(1), 1);
      expect(repo.lines[guestOwner]![1], isNotNull);
    });

    test(
      'a failed save puts the screen back in line with the database',
      () async {
        await startAsGuest();
        repo.failNextSave = true;

        cart.addProduct(_p(1));
        expect(cart.itemCount, 1);
        await settle();

        expect(cart.itemCount, 0);
        expect(cart.status, CartStatus.ready);
      },
    );
  });

  group('coupons', () {
    test(
      'an unknown code, a code below its minimum, and a good code',
      () async {
        await startAsGuest();
        cart.addProduct(_p(1, price: 10)); // subtotal $10

        expect(cart.applyCoupon(''), CouponOutcome.emptyInput);
        expect(cart.applyCoupon('NOPE'), CouponOutcome.unknown);
        expect(cart.couponMessage, 'That code is not valid.');
        expect(cart.applyCoupon('WELCOME5'), CouponOutcome.notEligible);
        expect(cart.couponMessage, 'Add \$20.00 more to use WELCOME5.');

        expect(cart.applyCoupon('save10'), CouponOutcome.applied);
        expect(cart.couponCode, 'SAVE10');
        expect(cart.couponMessage, isNull);
        expect(cart.totals.couponDiscount.cents, 100);

        await settle();
        expect(repo.coupons[guestOwner], 'SAVE10');
      },
    );

    test('removing the coupon clears it from the database too', () async {
      await startAsGuest();
      cart.addProduct(_p(1));
      cart.applyCoupon('SAVE10');

      cart.removeCoupon();
      await settle();

      expect(cart.couponCode, isNull);
      expect(repo.coupons.containsKey(guestOwner), isFalse);
    });
  });

  group('who owns the cart', () {
    test('signing in merges the guest cart into the user cart', () async {
      await startAsGuest();
      cart.addProduct(_p(1));
      cart.addProduct(_p(2));
      await settle();

      await auth.signIn('emilys', 'pw');
      await settle();

      expect(cart.items.map((i) => i.productId).toSet(), {1, 2});
      expect(repo.lines.containsKey(guestOwner), isFalse);
      expect(repo.lines['user:1']!.length, 2);
    });

    test(
      'signing out shows an empty guest cart and the user cart stays safe',
      () async {
        await startAsGuest();
        cart.addProduct(_p(1));
        await settle();
        await auth.signIn('emilys', 'pw');
        await settle();

        await auth.signOut();
        await settle();
        expect(cart.isEmpty, isTrue);
        expect(repo.lines['user:1']!.length, 1);

        await auth.signIn('emilys', 'pw');
        await settle();
        expect(cart.items.length, 1); // ফিরে এলে আবার পাওয়া যায়
      },
    );

    test('opening the app already signed in loads the user cart and does not merge', () async {
      repo.lines[guestOwner] = {9: _item(9)};
      repo.lines['user:1'] = {1: _item(1)};

      when(() => authRepo.fetchProfile()).thenAnswer((_) async => _emily);
      auth.dispose();
      auth = AuthProvider(authRepo, FakeTokenStore(_tokens, 1));
      await auth.restore();
      cart = CartProvider(repo, auth);
      await settle();

      expect(cart.items.map((i) => i.productId), [1]);
      expect(repo.lines[guestOwner], isNotNull);
    });

    test('while the user is unknown the cart waits instead of showing the guest cart', () async {
      final completer = Completer<UserProfile>();
      when(() => authRepo.fetchProfile()).thenAnswer((_) => completer.future);
      auth.dispose();
      auth = AuthProvider(authRepo, FakeTokenStore(_tokens)); // id রাখা নেই

      final restoring = auth.restore();
      cart = CartProvider(repo, auth);
      await settle();

      expect(cart.status, CartStatus.loading);
      expect(cart.addProduct(_p(1)), AddToCartResult.notReady);

      repo.lines['user:1'] = {1: _item(1)};
      completer.complete(_emily);
      await restoring;
      await settle();

      expect(cart.status, CartStatus.ready);
      expect(cart.items.length, 1);
    });
  });

  group('checkout support', () {
    test('adding several at once is capped at the stock', () async {
      await startAsGuest();

      expect(
        cart.addProduct(_p(1, stock: 3), quantity: 5),
        AddToCartResult.added,
      );
      expect(cart.quantityOf(1), 3);
      expect(
        cart.addProduct(_p(1, stock: 3), quantity: 2),
        AddToCartResult.limitReached,
      );

      cart.decrement(1); // 2
      expect(
        cart.addProduct(_p(1, stock: 3), quantity: 5),
        AddToCartResult.increased,
      );
      expect(cart.quantityOf(1), 3);
    });

    test('reload re-reads whatever is stored', () async {
      await startAsGuest();
      repo.lines[guestOwner] = {4: _item(4, qty: 2)};

      await cart.reload();

      expect(cart.items.single.productId, 4);
      expect(cart.status, CartStatus.ready);
    });

    test('applyReconcile replaces the lines and saves them', () async {
      await startAsGuest();
      cart.addProduct(_p(1, price: 10, stock: 5));
      cart.addProduct(_p(2, price: 10, stock: 5));
      await cart.flush();

      final result = reconcileCart(cart.items, {
        1: _p(1, price: 12, stock: 5),
        2: _p(2, stock: 0),
      });
      cart.applyReconcile(result);
      await cart.flush();

      expect(cart.items.map((i) => i.productId), [1]);
      expect(cart.items.single.unitPrice.cents, 1200);
      expect(repo.lines[guestOwner]!.containsKey(2), isFalse);
      expect(repo.lines[guestOwner]![1]!.unitPrice.cents, 1200);
    });

    test('flush returns once queued writes have landed', () async {
      await startAsGuest();
      cart.addProduct(_p(1));

      await cart.flush();

      expect(repo.lines[guestOwner]![1], isNotNull);
    });
  });
}
