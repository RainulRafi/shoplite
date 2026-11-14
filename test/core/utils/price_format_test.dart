import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/utils/price_format.dart';

void main() {
  test('always shows two decimals with a dollar sign', () {
    expect(formatPrice(10), '\$10.00');
    expect(formatPrice(8.944), '\$8.94');
    expect(formatPrice(9.999), '\$10.00');
  });
}
