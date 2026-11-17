import '../../cart/domain/cart_item.dart';
import '../domain/checkout_pricing.dart';
import '../domain/delivery_method.dart';
import '../domain/order.dart';
import '../domain/payment.dart';

class PlaceOrderRequest {
  final String ownerId;
  final String idempotencyKey;
  final DateTime placedAt;
  final List<CartItem> items;
  final OrderAddress address;
  final DeliveryMethod deliveryMethod;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final CheckoutTotals totals;

  const PlaceOrderRequest({
    required this.ownerId,
    required this.idempotencyKey,
    required this.placedAt,
    required this.items,
    required this.address,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.totals,
  });
}

class PlacedOrder {
  final Order order;

  final bool alreadyExisted;

  const PlacedOrder({required this.order, required this.alreadyExisted});
}

abstract class OrderRepository {
  Future<List<Order>> loadAll(String ownerId);

  Future<Order?> load(String ownerId, int id);

  Future<PlacedOrder> place(PlaceOrderRequest request);

  Future<bool> cancel(String ownerId, int orderId, DateTime now);
}
