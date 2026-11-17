import 'package:shoplite/features/cart/data/cart_repository.dart';
import 'package:shoplite/features/cart/domain/cart_item.dart';
import 'package:shoplite/features/cart/domain/cart_merge.dart';

class FakeCartRepository implements CartRepository {
  final Map<String, Map<int, CartItem>> lines = {};
  final Map<String, String> coupons = {};

  bool failNextSave = false;

  @override
  Future<List<CartItem>> loadItems(String ownerId) async {
    final items = (lines[ownerId] ?? {}).values.toList();
    items.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  @override
  Future<void> saveItem(String ownerId, CartItem item) async {
    if (failNextSave) {
      failNextSave = false;
      throw Exception('disk full');
    }
    (lines[ownerId] ??= {})[item.productId] = item;
  }

  @override
  Future<void> removeItem(String ownerId, int productId) async {
    lines[ownerId]?.remove(productId);
  }

  @override
  Future<String?> loadCoupon(String ownerId) async => coupons[ownerId];

  @override
  Future<void> saveCoupon(String ownerId, String? code) async {
    if (code == null) {
      coupons.remove(ownerId);
    } else {
      coupons[ownerId] = code;
    }
  }

  @override
  Future<void> mergeGuestInto(String userOwnerId) async {
    final merged = mergeCartLines(
      (lines[userOwnerId]?.values ?? const <CartItem>[]).toList(),
      (lines[guestOwner]?.values ?? const <CartItem>[]).toList(),
    );
    if (merged.isNotEmpty) {
      lines[userOwnerId] = {for (final item in merged) item.productId: item};
    }
    lines.remove(guestOwner);

    final guestCoupon = coupons.remove(guestOwner);
    if (guestCoupon != null && !coupons.containsKey(userOwnerId)) {
      coupons[userOwnerId] = guestCoupon;
    }
  }
}
