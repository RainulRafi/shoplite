import '../money/money.dart';

String formatPrice(double value) => Money.fromDollars(value).format();
