import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/money/money.dart';

void main() {
  group('Money', () {
    test('turns a server price into whole cents', () {
      expect(Money.fromDollars(9.99).cents, 999);
      expect(Money.fromDollars(10).cents, 1000);
    });

    test('adding decimals does not drift like doubles do', () {
      // double-এ 0.1 + 0.2 = 0.30000000000000004
      expect((Money.fromDollars(0.1) + Money.fromDollars(0.2)).cents, 30);
    });

    test(
      'formats with a dollar sign, two decimals and thousands separators',
      () {
        expect(const Money(2000).format(), '\$20.00');
        expect(const Money(5).format(), '\$0.05');
        expect(const Money(123456789).format(), '\$1,234,567.89');
        expect(const Money(-420).format(), '-\$4.20');
      },
    );

    test('percentages round to the nearest cent', () {
      expect(const Money(1999).percent(10).cents, 200); // 199.9 -> 200
      expect(const Money(999).discountedBy(10.48).cents, 894);
    });

    test('supports arithmetic, negation and comparison', () {
      expect((const Money(500) * 3).cents, 1500);
      expect((const Money(500) - const Money(200)).cents, 300);
      expect((-const Money(500)).cents, -500);
      expect(const Money(500) > const Money(499), isTrue);
      expect(const Money(500) >= const Money(500), isTrue);
      expect(const Money(500) == const Money(500), isTrue);
      expect(const Money(500).hashCode, const Money(500).hashCode);
    });
  });
}
