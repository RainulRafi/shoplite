import '../../../core/money/money.dart';
import 'product.dart';

extension ProductMoney on Product {
  Money get listMoney => Money.fromDollars(price);

  Money get saleMoney =>
      hasDiscount ? listMoney.discountedBy(discountPercentage) : listMoney;
}
