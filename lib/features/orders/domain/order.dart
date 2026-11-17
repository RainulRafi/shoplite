import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../addresses/domain/address.dart';
import '../../cart/domain/cart_item.dart';
import '../../products/data/product.dart';
import 'delivery_method.dart';
import 'payment.dart';

@immutable
class OrderItem {
  final int productId;
  final String title;
  final String? brand;
  final String thumbnail;
  final Money listPrice;
  final Money unitPrice;
  final double discountPercent;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.title,
    this.brand,
    required this.thumbnail,
    required this.listPrice,
    required this.unitPrice,
    required this.discountPercent,
    required this.quantity,
  });

  factory OrderItem.fromCartItem(CartItem item) => OrderItem(
    productId: item.productId,
    title: item.title,
    brand: item.brand,
    thumbnail: item.thumbnail,
    listPrice: item.listPrice,
    unitPrice: item.unitPrice,
    discountPercent: item.discountPercent,
    quantity: item.quantity,
  );

  Money get lineTotal => unitPrice * quantity;
  bool get hasDiscount => unitPrice < listPrice;

  Product toPlaceholderProduct() => Product(
    id: productId,
    title: title,
    price: listPrice.cents / 100,
    discountPercentage: discountPercent,
    brand: brand,
    thumbnail: thumbnail,
    stock: 1,
  );
}

@immutable
class OrderAddress {
  final String label;
  final String fullName;
  final String phone;
  final String division;
  final String district;
  final String area;
  final String line1;
  final String? postalCode;
  final String? note;

  const OrderAddress({
    required this.label,
    required this.fullName,
    required this.phone,
    required this.division,
    required this.district,
    required this.area,
    required this.line1,
    this.postalCode,
    this.note,
  });

  factory OrderAddress.fromAddress(Address a) => OrderAddress(
    label: a.label.title,
    fullName: a.fullName,
    phone: a.phone,
    division: a.division,
    district: a.district,
    area: a.area,
    line1: a.line1,
    postalCode: a.postalCode,
    note: a.note,
  );

  String get singleLine {
    final parts = [
      line1,
      area,
      district,
      division,
      if (postalCode != null && postalCode!.isNotEmpty) postalCode!,
    ];
    return parts.join(', ');
  }
}

@immutable
class Order {
  final int id;
  final String orderNumber;
  final DateTime placedAt;
  final List<OrderItem> items;
  final OrderAddress address;
  final DeliveryMethod deliveryMethod;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;

  final Money listTotal;
  final Money itemDiscount;
  final Money subtotal;
  final String? couponCode;
  final Money couponDiscount;
  final Money shipping;
  final Money total;

  final DateTime? cancelledAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.placedAt,
    required this.items,
    required this.address,
    required this.deliveryMethod,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.listTotal,
    required this.itemDiscount,
    required this.subtotal,
    required this.couponCode,
    required this.couponDiscount,
    required this.shipping,
    required this.total,
    this.cancelledAt,
  });

  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);
}
