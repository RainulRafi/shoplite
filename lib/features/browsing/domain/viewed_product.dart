import 'package:flutter/foundation.dart';

import '../../../core/money/money.dart';
import '../../products/data/product.dart';
import '../../products/data/product_money.dart';

@immutable
class ViewedProduct {
  final int productId;
  final String title;
  final String? brand;
  final String thumbnail;
  final Money listPrice;
  final Money unitPrice;
  final double discountPercent;
  final DateTime viewedAt;

  const ViewedProduct({
    required this.productId,
    required this.title,
    this.brand,
    required this.thumbnail,
    required this.listPrice,
    required this.unitPrice,
    required this.discountPercent,
    required this.viewedAt,
  });

  factory ViewedProduct.fromProduct(Product p, {required DateTime viewedAt}) {
    return ViewedProduct(
      productId: p.id,
      title: p.title,
      brand: p.brand,
      thumbnail: p.thumbnail,
      listPrice: p.listMoney,
      unitPrice: p.saleMoney,
      discountPercent: p.hasDiscount ? p.discountPercentage : 0,
      viewedAt: viewedAt,
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
