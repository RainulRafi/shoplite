import 'package:shoplite/core/money/money.dart';
import 'package:shoplite/features/addresses/domain/address.dart';
import 'package:shoplite/features/cart/domain/cart_item.dart';
import 'package:shoplite/features/orders/data/order_repository.dart';
import 'package:shoplite/features/orders/domain/checkout_pricing.dart';
import 'package:shoplite/features/orders/domain/delivery_method.dart';
import 'package:shoplite/features/orders/domain/order.dart';
import 'package:shoplite/features/orders/domain/payment.dart';
import 'package:shoplite/features/products/data/product.dart';

final DateTime t0 = DateTime(2026, 11, 17, 12, 0);

Product testProduct(
  int id, {
  double price = 10,
  double discount = 0,
  int stock = 5,
  String? title,
}) => Product(
  id: id,
  title: title ?? 'P$id',
  price: price,
  discountPercentage: discount,
  stock: stock,
  thumbnail: 'https://x.test/$id.png',
);

CartItem testCartItem(
  int id, {
  int qty = 1,
  int unit = 1000,
  int list = 1000,
  int max = 5,
  int addedAt = 1000,
}) => CartItem(
  productId: id,
  title: 'P$id',
  brand: 'B',
  thumbnail: 'https://x.test/$id.png',
  listPrice: Money(list),
  unitPrice: Money(unit),
  discountPercent: 0,
  quantity: qty,
  maxQuantity: max,
  addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
);

Address testAddress({
  String name = 'Rahim Uddin',
  String phone = '01712345678',
  String line1 = 'House 12, Road 4',
  bool isDefault = false,
  int updatedAt = 0,
}) => Address(
  label: AddressLabel.home,
  fullName: name,
  phone: phone,
  division: 'Dhaka',
  district: 'Dhaka',
  area: 'Mirpur',
  line1: line1,
  isDefault: isDefault,
  updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
);

PlaceOrderRequest testRequest({
  String ownerId = 'user:1',
  String key = 'key-1',
  DateTime? placedAt,
  List<CartItem>? items,
  DeliveryMethod delivery = DeliveryMethod.standard,
  PaymentMethod payment = PaymentMethod.cashOnDelivery,
  PaymentStatus status = PaymentStatus.payOnDelivery,
  String? coupon,
  Address? address,
}) {
  final cartItems = items ?? [testCartItem(1, qty: 2)];
  return PlaceOrderRequest(
    ownerId: ownerId,
    idempotencyKey: key,
    placedAt: placedAt ?? t0,
    items: cartItems,
    address: OrderAddress.fromAddress(address ?? testAddress()),
    deliveryMethod: delivery,
    paymentMethod: payment,
    paymentStatus: status,
    totals: CheckoutPricing.compute(
      cartItems,
      couponCode: coupon,
      method: delivery,
    ),
  );
}

Order testOrder({
  DateTime? placedAt,
  DeliveryMethod delivery = DeliveryMethod.standard,
  DateTime? cancelledAt,
}) {
  final item = OrderItem.fromCartItem(testCartItem(1, qty: 2));
  final total = item.lineTotal;
  return Order(
    id: 1,
    orderNumber: 'SL-20261117-0001',
    placedAt: placedAt ?? t0,
    items: [item],
    address: OrderAddress.fromAddress(testAddress()),
    deliveryMethod: delivery,
    paymentMethod: PaymentMethod.cashOnDelivery,
    paymentStatus: PaymentStatus.payOnDelivery,
    listTotal: total,
    itemDiscount: Money.zero,
    subtotal: total,
    couponCode: null,
    couponDiscount: Money.zero,
    shipping: Money.zero,
    total: total,
    cancelledAt: cancelledAt,
  );
}
