import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/addresses/domain/address.dart';
import 'package:shoplite/features/addresses/domain/address_validators.dart';

Address _valid() => Address(
  label: AddressLabel.home,
  fullName: 'Rahim Uddin',
  phone: '01712345678',
  division: 'Dhaka',
  district: 'Dhaka',
  area: 'Mirpur',
  line1: 'House 12, Road 4',
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
);

void main() {
  test('a complete address has no errors', () {
    expect(AddressValidators.validateAll(_valid()), isEmpty);
  });

  test('every required field is checked, and the errors name the field', () {
    final bad = Address(
      label: AddressLabel.home,
      fullName: 'R',
      phone: '123',
      division: 'Atlantis',
      district: '',
      area: ' ',
      line1: 'abc',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    expect(AddressValidators.validateAll(bad).keys.toSet(), {
      'name',
      'phone',
      'division',
      'district',
      'area',
      'line1',
    });
  });

  test('the postal code is optional but must have four digits when given', () {
    expect(AddressValidators.postalCode(''), isNull);
    expect(AddressValidators.postalCode(null), isNull);
    expect(AddressValidators.postalCode('1216'), isNull);
    expect(AddressValidators.postalCode('12'), isNotNull);
    expect(AddressValidators.postalCode('12a6'), isNotNull);
  });

  test('a very long note or name is refused', () {
    expect(AddressValidators.note('x' * 121), isNotNull);
    expect(AddressValidators.note('x' * 120), isNull);
    expect(AddressValidators.name('x' * 61), isNotNull);
  });

  test('only the eight divisions are accepted', () {
    expect(AddressValidators.division('Sylhet'), isNull);
    expect(AddressValidators.division('sylhet'), isNotNull);
    expect(AddressValidators.division(null), isNotNull);
  });

  test('the single line joins the parts and skips an empty postal code', () {
    expect(_valid().singleLine, 'House 12, Road 4, Mirpur, Dhaka, Dhaka');
    expect(
      Address(
        label: AddressLabel.work,
        fullName: 'x',
        phone: '01712345678',
        division: 'Dhaka',
        district: 'Dhaka',
        area: 'Mirpur',
        line1: 'House 12',
        postalCode: '1216',
        updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      ).singleLine,
      'House 12, Mirpur, Dhaka, Dhaka, 1216',
    );
  });
}
