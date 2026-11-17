import 'package:sqflite/sqflite.dart';

import '../../../core/money/money.dart';
import '../domain/delivery_method.dart';
import '../domain/order.dart';
import '../domain/order_lifecycle.dart';
import '../domain/payment.dart';
import 'order_repository.dart';

class SqliteOrderRepository implements OrderRepository {
  final Future<Database> Function() _openDb;

  SqliteOrderRepository(this._openDb);

  @override
  Future<List<Order>> loadAll(String ownerId) async {
    final db = await _openDb();

    final orderRows = await db.query(
      'orders',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      orderBy: 'placed_at DESC, id DESC',
    );
    if (orderRows.isEmpty) return const [];

    final itemRows = await db.rawQuery(
      'SELECT oi.* FROM order_items oi '
      'JOIN orders o ON o.id = oi.order_id '
      'WHERE o.owner_id = ? ORDER BY oi.rowid',
      [ownerId],
    );
    final byOrder = <int, List<OrderItem>>{};
    for (final row in itemRows) {
      (byOrder[row['order_id'] as int] ??= []).add(_itemFromRow(row));
    }

    return [
      for (final row in orderRows)
        _orderFromRow(row, byOrder[row['id'] as int] ?? const []),
    ];
  }

  @override
  Future<Order?> load(String ownerId, int id) async {
    final db = await _openDb();
    final order = await _loadIn(db, id);
    if (order == null) return null;
    return await _ownerOf(db, id) == ownerId ? order : null;
  }

  @override
  Future<PlacedOrder> place(PlaceOrderRequest request) async {
    if (request.items.isEmpty) {
      throw ArgumentError('An order needs at least one item');
    }
    final db = await _openDb();

    return db.transaction((txn) async {
      final existing = await txn.query(
        'orders',
        columns: ['id'],
        where: 'idempotency_key = ?',
        whereArgs: [request.idempotencyKey],
      );
      if (existing.isNotEmpty) {
        final order = await _loadIn(txn, existing.first['id'] as int);
        return PlacedOrder(order: order!, alreadyExisted: true);
      }

      final number = await _nextOrderNumber(txn, request.placedAt);
      final orderId = await txn.insert('orders', _orderRow(request, number));

      for (final item in request.items) {
        await txn.insert('order_items', {
          'order_id': orderId,
          'product_id': item.productId,
          'title': item.title,
          'brand': item.brand,
          'thumbnail': item.thumbnail,
          'list_price_cents': item.listPrice.cents,
          'unit_price_cents': item.unitPrice.cents,
          'discount_percent': item.discountPercent,
          'quantity': item.quantity,
        });
      }

      await txn.delete(
        'cart_items',
        where: 'owner_id = ?',
        whereArgs: [request.ownerId],
      );
      await txn.delete(
        'cart_meta',
        where: 'owner_id = ?',
        whereArgs: [request.ownerId],
      );

      final order = await _loadIn(txn, orderId);
      return PlacedOrder(order: order!, alreadyExisted: false);
    });
  }

  @override
  Future<bool> cancel(String ownerId, int orderId, DateTime now) async {
    final db = await _openDb();

    return db.transaction((txn) async {
      final order = await _loadIn(txn, orderId);
      if (order == null || await _ownerOf(txn, orderId) != ownerId) {
        return false;
      }

      if (!OrderLifecycle.canCancel(order, now)) return false;

      final changed = await txn.update(
        'orders',
        {'cancelled_at': now.millisecondsSinceEpoch},
        where: 'id = ? AND cancelled_at IS NULL',
        whereArgs: [orderId],
      );
      return changed > 0;
    });
  }

  Future<String> _nextOrderNumber(DatabaseExecutor db, DateTime at) async {
    final day =
        '${at.year}'
        '${at.month.toString().padLeft(2, '0')}'
        '${at.day.toString().padLeft(2, '0')}';
    final prefix = 'SL-$day-';
    final rows = await db.rawQuery(
      'SELECT COUNT(*) FROM orders WHERE order_number LIKE ?',
      ['$prefix%'],
    );
    final next = (Sqflite.firstIntValue(rows) ?? 0) + 1;
    return '$prefix${next.toString().padLeft(4, '0')}';
  }

  Future<String?> _ownerOf(DatabaseExecutor db, int id) async {
    final rows = await db.query(
      'orders',
      columns: ['owner_id'],
      where: 'id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.first['owner_id'] as String;
  }

  Future<Order?> _loadIn(DatabaseExecutor db, int id) async {
    final rows = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final itemRows = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [id],
      orderBy: 'rowid',
    );
    return _orderFromRow(rows.first, itemRows.map(_itemFromRow).toList());
  }

  Map<String, Object?> _orderRow(PlaceOrderRequest r, String number) {
    final t = r.totals;
    final a = r.address;
    return {
      'owner_id': r.ownerId,
      'order_number': number,
      'idempotency_key': r.idempotencyKey,
      'placed_at': r.placedAt.millisecondsSinceEpoch,
      'delivery_method': r.deliveryMethod.name,
      'payment_method': r.paymentMethod.name,
      'payment_status': r.paymentStatus.name,
      'list_total_cents': t.listTotal.cents,
      'item_discount_cents': t.itemDiscount.cents,
      'subtotal_cents': t.subtotal.cents,
      'coupon_code': t.couponCode,
      'coupon_discount_cents': t.couponDiscount.cents,
      'shipping_cents': t.shipping.cents,
      'total_cents': t.total.cents,
      'ship_label': a.label,
      'ship_name': a.fullName,
      'ship_phone': a.phone,
      'ship_division': a.division,
      'ship_district': a.district,
      'ship_area': a.area,
      'ship_line1': a.line1,
      'ship_postal_code': a.postalCode,
      'ship_note': a.note,
    };
  }

  OrderItem _itemFromRow(Map<String, Object?> row) {
    return OrderItem(
      productId: row['product_id'] as int,
      title: row['title'] as String,
      brand: row['brand'] as String?,
      thumbnail: row['thumbnail'] as String,
      listPrice: Money(row['list_price_cents'] as int),
      unitPrice: Money(row['unit_price_cents'] as int),
      discountPercent: (row['discount_percent'] as num).toDouble(),
      quantity: row['quantity'] as int,
    );
  }

  Order _orderFromRow(Map<String, Object?> row, List<OrderItem> items) {
    final cancelled = row['cancelled_at'] as int?;
    return Order(
      id: row['id'] as int,
      orderNumber: row['order_number'] as String,
      placedAt: DateTime.fromMillisecondsSinceEpoch(row['placed_at'] as int),
      items: items,
      address: OrderAddress(
        label: row['ship_label'] as String,
        fullName: row['ship_name'] as String,
        phone: row['ship_phone'] as String,
        division: row['ship_division'] as String,
        district: row['ship_district'] as String,
        area: row['ship_area'] as String,
        line1: row['ship_line1'] as String,
        postalCode: row['ship_postal_code'] as String?,
        note: row['ship_note'] as String?,
      ),
      deliveryMethod: DeliveryMethod.fromName(
        row['delivery_method'] as String?,
      ),
      paymentMethod: PaymentMethod.fromName(row['payment_method'] as String?),
      paymentStatus: PaymentStatus.fromName(row['payment_status'] as String?),
      listTotal: Money(row['list_total_cents'] as int),
      itemDiscount: Money(row['item_discount_cents'] as int),
      subtotal: Money(row['subtotal_cents'] as int),
      couponCode: row['coupon_code'] as String?,
      couponDiscount: Money(row['coupon_discount_cents'] as int),
      shipping: Money(row['shipping_cents'] as int),
      total: Money(row['total_cents'] as int),
      cancelledAt: cancelled == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(cancelled),
    );
  }
}
