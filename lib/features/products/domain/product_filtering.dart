import '../data/product.dart';
import '../data/product_money.dart';
import 'product_query.dart';

List<Product> applyQuery(List<Product> source, ProductQuery query) {
  final f = query.filters;

  final result = source.where((p) {
    if (query.category != null && p.category != query.category) return false;

    final price = p.saleMoney;
    if (f.minPrice != null && price < f.minPrice!) return false;
    if (f.maxPrice != null && price > f.maxPrice!) return false;
    if (f.inStockOnly && !p.inStock) return false;
    if (f.minRating > 0 && p.rating < f.minRating) return false;
    return true;
  }).toList();

  int byId(Product a, Product b) => a.id.compareTo(b.id);
  double discountOf(Product p) => p.hasDiscount ? p.discountPercentage : 0;

  switch (query.sort) {
    case ProductSort.relevance:
      break;
    case ProductSort.priceLowHigh:
      result.sort((a, b) {
        final c = a.saleMoney.compareTo(b.saleMoney);
        return c != 0 ? c : byId(a, b);
      });
    case ProductSort.priceHighLow:
      result.sort((a, b) {
        final c = b.saleMoney.compareTo(a.saleMoney);
        return c != 0 ? c : byId(a, b);
      });
    case ProductSort.topRated:
      result.sort((a, b) {
        final c = b.rating.compareTo(a.rating);
        return c != 0 ? c : byId(a, b);
      });
    case ProductSort.biggestDiscount:
      result.sort((a, b) {
        final c = discountOf(b).compareTo(discountOf(a));
        return c != 0 ? c : byId(a, b);
      });
  }
  return result;
}
