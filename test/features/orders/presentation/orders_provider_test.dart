import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/state/data_status.dart';
import 'package:shoplite/features/orders/data/sqlite_order_repository.dart';
import 'package:shoplite/features/orders/presentation/orders_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/order_fixtures.dart';
import '../../../helpers/test_support.dart';

void main() {
  late Database db;
  late SqliteOrderRepository repo;
  late AuthRig rig;
  late OrdersProvider provider;

  setUp(() async {
    db = await openTestDatabase();
    repo = SqliteOrderRepository(() async => db);
    rig = AuthRig();
    await rig.auth.restore();
    provider = OrdersProvider(repo, rig.auth);
  });

  tearDown(() async {
    provider.dispose();
    rig.dispose();
    await db.close();
  });

  test('a guest has no orders', () {
    expect(provider.status, DataStatus.ready);
    expect(provider.orders, isEmpty);
  });

  test('signing in loads that person orders and nobody else', () async {
    await repo.place(testRequest(ownerId: 'user:1', key: 'a'));
    await repo.place(testRequest(ownerId: 'user:2', key: 'b'));

    await rig.signIn(); // user 1
    await waitUntil(
      () => provider.status == DataStatus.ready && provider.orders.isNotEmpty,
    );
    expect(provider.orders, hasLength(1));

    await rig.auth.signOut();
    expect(provider.orders, isEmpty);

    await rig.signIn(testUser2);
    await waitUntil(
      () => provider.status == DataStatus.ready && provider.orders.isNotEmpty,
    );
    expect(provider.orders, hasLength(1));
    expect(provider.orders.single.id, isNot(1));
  });

  test('a freshly placed order is added on top without a duplicate', () async {
    await rig.signIn();
    await waitUntil(() => provider.status == DataStatus.ready);
    final placed = await repo.place(testRequest(key: 'a'));

    provider.addPlaced(placed.order);
    provider.addPlaced(placed.order);

    expect(provider.orders, hasLength(1));
    expect(provider.byId(placed.order.id), isNotNull);
    expect(provider.byId(999), isNull);
  });

  test('cancelling works early and the list shows it', () async {
    await rig.signIn();
    await waitUntil(() => provider.status == DataStatus.ready);
    final placed = await repo.place(testRequest(key: 'a'));
    provider.addPlaced(placed.order);

    final result = await provider.cancel(
      placed.order,
      now: t0.add(const Duration(minutes: 2)),
    );

    expect(result, CancelResult.cancelled);
    expect(provider.byId(placed.order.id)!.cancelledAt, isNotNull);
  });

  test('cancelling after it shipped is refused and changes nothing', () async {
    await rig.signIn();
    await waitUntil(() => provider.status == DataStatus.ready);
    final placed = await repo.place(testRequest(key: 'a'));
    provider.addPlaced(placed.order);

    final result = await provider.cancel(
      placed.order,
      now: t0.add(const Duration(minutes: 7)),
    );

    expect(result, CancelResult.notAllowed);
    expect(provider.byId(placed.order.id)!.cancelledAt, isNull);
  });

  test('a guest cannot cancel anything', () async {
    final placed = await repo.place(testRequest(key: 'a'));

    expect(await provider.cancel(placed.order), CancelResult.failed);
  });
}
