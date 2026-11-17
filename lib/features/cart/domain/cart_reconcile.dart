import '../../../core/money/money.dart';
import '../../products/data/product.dart';
import 'cart_item.dart';

enum CartChangeType {
  priceChanged,
  quantityReduced,
  removedOutOfStock,
  removedUnavailable,
}

class CartChange {
  final CartChangeType type;
  final int productId;
  final String title;
  final Money? oldUnitPrice;
  final Money? newUnitPrice;
  final int? oldQuantity;
  final int? newQuantity;

  const CartChange({
    required this.type,
    required this.productId,
    required this.title,
    this.oldUnitPrice,
    this.newUnitPrice,
    this.oldQuantity,
    this.newQuantity,
  });

  String describe() {
    switch (type) {
      case CartChangeType.priceChanged:
        return '$title: price changed from ${oldUnitPrice!.format()} to ${newUnitPrice!.format()}.';
      case CartChangeType.quantityReduced:
        return '$title: only $newQuantity in stock, so we reduced your quantity from $oldQuantity.';
      case CartChangeType.removedOutOfStock:
        return '$title: out of stock, removed from your cart.';
      case CartChangeType.removedUnavailable:
        return '$title: no longer available, removed from your cart.';
    }
  }
}

class ReconcileResult {
  final List<CartItem> items;
  final List<CartChange> changes;

  const ReconcileResult({required this.items, required this.changes});
}

ReconcileResult reconcileCart(List<CartItem> items, Map<int, Product?> fresh) {
  final kept = <CartItem>[];
  final changes = <CartChange>[];

  for (final item in items) {
    if (!fresh.containsKey(item.productId)) {
      kept.add(item);
      continue;
    }

    final product = fresh[item.productId];
    if (product == null) {
      changes.add(
        CartChange(
          type: CartChangeType.removedUnavailable,
          productId: item.productId,
          title: item.title,
        ),
      );
      continue;
    }
    if (!product.inStock) {
      changes.add(
        CartChange(
          type: CartChangeType.removedOutOfStock,
          productId: item.productId,
          title: item.title,
        ),
      );
      continue;
    }

    final quantity = item.quantity > product.stock
        ? product.stock
        : item.quantity;
    final updated = CartItem.fromProduct(
      product,
      quantity: quantity,
      addedAt: item.addedAt,
    );

    if (quantity < item.quantity) {
      changes.add(
        CartChange(
          type: CartChangeType.quantityReduced,
          productId: item.productId,
          title: updated.title,
          oldQuantity: item.quantity,
          newQuantity: quantity,
        ),
      );
    }
    if (updated.unitPrice != item.unitPrice) {
      changes.add(
        CartChange(
          type: CartChangeType.priceChanged,
          productId: item.productId,
          title: updated.title,
          oldUnitPrice: item.unitPrice,
          newUnitPrice: updated.unitPrice,
        ),
      );
    }
    kept.add(updated);
  }

  return ReconcileResult(items: kept, changes: changes);
}
