import '../domain/cart_item.dart';

const String guestOwner = 'guest';

abstract class CartRepository {
  Future<List<CartItem>> loadItems(String ownerId);

  Future<void> saveItem(String ownerId, CartItem item);

  Future<void> removeItem(String ownerId, int productId);

  Future<String?> loadCoupon(String ownerId);
  Future<void> saveCoupon(String ownerId, String? code);

  Future<void> mergeGuestInto(String userOwnerId);
}
