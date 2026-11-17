import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../products/data/product.dart';
import '../../products/data/product_money.dart';

@immutable
class WishlistItem {
  final int productId;
  final String title;
  final String? brand;
  final String thumbnail;
  final Money listPrice;
  final Money unitPrice;
  final double discountPercent;
  final DateTime addedAt;

  const WishlistItem({
    required this.productId,
    required this.title,
    this.brand,
    required this.thumbnail,
    required this.listPrice,
    required this.unitPrice,
    required this.discountPercent,
    required this.addedAt,
  });

  factory WishlistItem.fromProduct(
    Product product, {
    required DateTime addedAt,
  }) {
    return WishlistItem(
      productId: product.id,
      title: product.title,
      brand: product.brand,
      thumbnail: product.thumbnail,
      listPrice: product.listMoney,
      unitPrice: product.saleMoney,
      discountPercent: product.hasDiscount ? product.discountPercentage : 0,
      addedAt: addedAt,
    );
  }

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
