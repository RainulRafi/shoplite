import '../../../core/money/money.dart';
import '../domain/cart_item.dart';

extension CartItemRow on CartItem {
  Map<String, Object?> toRow(String ownerId) => {
    'owner_id': ownerId,
    'product_id': productId,
    'title': title,
    'brand': brand,
    'thumbnail': thumbnail,
    'list_price_cents': listPrice.cents,
    'unit_price_cents': unitPrice.cents,
    'discount_percent': discountPercent,
    'quantity': quantity,
    'max_quantity': maxQuantity,
    'added_at': addedAt.millisecondsSinceEpoch,
  };
}

CartItem cartItemFromRow(Map<String, Object?> row) {
  return CartItem(
    productId: row['product_id'] as int,
    title: row['title'] as String,
    brand: row['brand'] as String?,
    thumbnail: row['thumbnail'] as String,
    listPrice: Money(row['list_price_cents'] as int),
    unitPrice: Money(row['unit_price_cents'] as int),
    discountPercent: (row['discount_percent'] as num).toDouble(),
    quantity: row['quantity'] as int,
    maxQuantity: row['max_quantity'] as int,
    addedAt: DateTime.fromMillisecondsSinceEpoch(row['added_at'] as int),
  );
}
