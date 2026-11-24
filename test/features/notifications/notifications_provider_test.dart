import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/state/data_status.dart';
import 'package:shoplite/features/notifications/data/sqlite_notifications_repository.dart';
import 'package:shoplite/features/notifications/presentation/notifications_provider.dart';
import 'package:shoplite/features/orders/data/sqlite_order_repository.dart';
import 'package:shoplite/features/orders/presentation/orders_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shoplite/features/auth/data/user_profile.dart';

import '../../helpers/auth_rig.dart';
import '../../helpers/order_fixtures.dart';
import '../../helpers/test_support.dart';

void main() {
  late Database db;
  late AuthRig rig;
  late SqliteOrderRepository orderRepo;
  late SqliteNotificationsRepository repo;
  late OrdersProvider orders;
  late NotificationsProvider notifications;
  late DateTime now;

  setUp(() async {
    db = await openTestDatabase();
    rig = AuthRig();
    await rig.auth.restore();
    orderRepo = SqliteOrderRepository(() async => db);
    repo = SqliteNotificationsRepository(() async => db);
    orders = OrdersProvider(orderRepo, rig.auth);
    now = t0;
    // tickEvery: null, নিজে সময় এগোই (now বদলে)
    notifications = NotificationsProvider(
      repo,
      orders,
      rig.auth,
      clock: () => now,
      tickEvery: null,
    );
  });

  tearDown(() async {
    await notifications.flush();
    notifications.dispose();
    orders.dispose();
    rig.dispose();
    await db.close();
  });

  // লগইন, তারপর t0 সময়ে একটা Order
  Future<void> signInWithOrder([UserProfile? user]) async {
    await rig.signIn(user ?? testUser);
    await waitUntil(
      () => orders.status == DataStatus.ready && notifications.isReady,
    );
    final placed = await orderRepo.place(
      testRequest(
        ownerId: 'user:${(user ?? testUser).id}',
        key: 'k${user?.id ?? 1}',
        placedAt: t0,
      ),
    );
    orders.addPlaced(placed.order);
  }

  test('a guest has nothing', () {
    expect(notifications.items, isEmpty);
    expect(notifications.unreadCount, 0);
  });

  test('unread grows with the clock as the order moves along', () async {
    await signInWithOrder();

    expect(notifications.unreadCount, 1); // placed
    now = t0.add(const Duration(minutes: 4));
    expect(notifications.unreadCount, 3); // placed, confirmed, packed
  });

  test('marking one read lowers the count, marking all clears it', () async {
    await signInWithOrder();
    now = t0.add(const Duration(minutes: 4));

    notifications.markRead(notifications.items.first.key);
    expect(notifications.unreadCount, 2);

    notifications.markAllRead();
    expect(notifications.unreadCount, 0);
  });

  test('a step that arrives later is unread again', () async {
    await signInWithOrder();
    now = t0.add(const Duration(minutes: 1));
    notifications.markAllRead();
    expect(notifications.unreadCount, 0);

    now = t0.add(const Duration(minutes: 3)); // packed আসে
    expect(notifications.unreadCount, 1);
    expect(notifications.items.first.title, 'Order packed');
  });

  test('read marks survive a restart', () async {
    await signInWithOrder();
    now = t0.add(const Duration(minutes: 4));
    notifications.markAllRead();
    await notifications.flush();

    final restarted = NotificationsProvider(
      repo,
      orders,
      rig.auth,
      clock: () => now,
      tickEvery: null,
    );
    await waitUntil(() => restarted.isReady);

    expect(restarted.unreadCount, 0);
    restarted.dispose();
  });

  test('each person has their own notifications and read marks', () async {
    await signInWithOrder();
    notifications.markAllRead();
    await notifications.flush();

    await rig.auth.signOut();
    expect(notifications.items, isEmpty);
    expect(notifications.unreadCount, 0);

    await rig.signIn(testUser2);
    await waitUntil(
      () => orders.status == DataStatus.ready && notifications.isReady,
    );
    expect(notifications.items, isEmpty); // অন্যজনের Order নেই

    await rig.auth.signOut();
    await rig.signIn();
    await waitUntil(() => orders.orders.isNotEmpty && notifications.isReady);
    expect(notifications.unreadCount, 0); // প্রথমজনের পড়া-চিহ্ন মনে আছে
  });
}
