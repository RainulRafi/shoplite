import '../../../core/network/api_exception.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../products/data/product_repository.dart';
import '../domain/order.dart';
import '../../products/data/product.dart';

class ReorderSummary {
  final int linesAdded;
  final List<String> outOfStock;
  final List<String> unavailable;
  final List<String> reduced;

  const ReorderSummary({
    required this.linesAdded,
    required this.outOfStock,
    required this.unavailable,
    required this.reduced,
  });

  bool get nothingAdded => linesAdded == 0;

  String message() {
    final parts = <String>[
      if (linesAdded > 0)
        'Added $linesAdded ${linesAdded == 1 ? 'item' : 'items'} to your cart.'
      else
        'Nothing could be added to your cart.',
      if (reduced.isNotEmpty)
        'Quantity reduced to what is in stock: ${reduced.join(', ')}.',
      if (outOfStock.isNotEmpty) 'Out of stock: ${outOfStock.join(', ')}.',
      if (unavailable.isNotEmpty) 'Could not check: ${unavailable.join(', ')}.',
    ];
    return parts.join(' ');
  }
}

class ReorderService {
  final ProductRepository _products;
  final CartProvider _cart;

  ReorderService(this._products, this._cart);

  Future<ReorderSummary> run(Order order) async {
    var added = 0;
    final outOfStock = <String>[];
    final unavailable = <String>[];
    final reduced = <String>[];

    for (final item in order.items) {
      final fresh = await _fetch(item.productId);
      if (fresh == null) {
        unavailable.add(item.title);
        continue;
      }
      if (!fresh.inStock) {
        outOfStock.add(item.title);
        continue;
      }

      final before = _cart.quantityOf(item.productId);
      final result = _cart.addProduct(fresh, quantity: item.quantity);

      switch (result) {
        case AddToCartResult.added:
        case AddToCartResult.increased:
          added++;
          final gained = _cart.quantityOf(item.productId) - before;
          if (gained < item.quantity) reduced.add(item.title);
        case AddToCartResult.limitReached:
          reduced.add(item.title);
        case AddToCartResult.outOfStock:
          outOfStock.add(item.title);
        case AddToCartResult.notReady:
          unavailable.add(item.title);
      }
    }

    return ReorderSummary(
      linesAdded: added,
      outOfStock: outOfStock,
      unavailable: unavailable,
      reduced: reduced,
    );
  }

  Future<Product?> _fetch(int id) async {
    try {
      return await _products.fetchProduct(id);
    } on ApiException {
      return null;
    }
  }
}
