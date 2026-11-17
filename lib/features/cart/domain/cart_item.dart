import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../products/data/product.dart';

@immutable
class CartItem {
  final int productId;
  final String title;
  final String? brand;
  final String thumbnail;
  final Money listPrice;
  final Money unitPrice;
  final double discountPercent;
  final int quantity;
  final int maxQuantity;
  final DateTime addedAt;

  const CartItem({
    required this.productId,
    required this.title,
    this.brand,
    required this.thumbnail,
    required this.listPrice,
    required this.unitPrice,
    required this.discountPercent,
    required this.quantity,
    required this.maxQuantity,
    required this.addedAt,
  });

  factory CartItem.fromProduct(
    Product product, {
    required int quantity,
    required DateTime addedAt,
  }) {
    final list = Money.fromDollars(product.price);
    final discounted = product.hasDiscount;
    return CartItem(
      productId: product.id,
      title: product.title,
      brand: product.brand,
      thumbnail: product.thumbnail,
      listPrice: list,
      unitPrice: discounted
          ? list.discountedBy(product.discountPercentage)
          : list,
      discountPercent: discounted ? product.discountPercentage : 0,
      quantity: quantity,
      maxQuantity: product.stock < 1 ? 1 : product.stock,
      addedAt: addedAt,
    );
  }

  Money get lineTotal => unitPrice * quantity;
  Money get lineList => listPrice * quantity;
  bool get hasDiscount => unitPrice < listPrice;
  bool get atLimit => quantity >= maxQuantity;

  CartItem copyWith({int? quantity}) => CartItem(
    productId: productId,
    title: title,
    brand: brand,
    thumbnail: thumbnail,
    listPrice: listPrice,
    unitPrice: unitPrice,
    discountPercent: discountPercent,
    quantity: quantity ?? this.quantity,
    maxQuantity: maxQuantity,
    addedAt: addedAt,
  );

  Product toPlaceholderProduct() => Product(
    id: productId,
    title: title,
    price: listPrice.cents / 100,
    discountPercentage: discountPercent,
    brand: brand,
    thumbnail: thumbnail,
    stock: maxQuantity,
  );
}
