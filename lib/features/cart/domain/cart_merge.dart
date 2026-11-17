import 'cart_item.dart';

List<CartItem> mergeCartLines(List<CartItem> user, List<CartItem> guest) {
  final byId = <int, CartItem>{for (final item in user) item.productId: item};

  for (final g in guest) {
    final u = byId[g.productId];
    if (u == null) {
      byId[g.productId] = g;
      continue;
    }
    final newer = g.addedAt.isAfter(u.addedAt) ? g : u;
    final sum = u.quantity + g.quantity;
    final quantity = sum > newer.maxQuantity ? newer.maxQuantity : sum;
    byId[g.productId] = newer.copyWith(quantity: quantity);
  }
  return byId.values.toList();
}
