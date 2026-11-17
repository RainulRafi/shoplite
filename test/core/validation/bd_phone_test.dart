import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/validation/bd_phone.dart';

void main() {
  test('every common way of writing the same number becomes one form', () {
    for (final input in [
      '01712345678',
      '+8801712345678',
      '8801712345678',
      '017 1234-5678',
      ' (017) 12345678 ',
    ]) {
      expect(normalizeBdPhone(input), '01712345678', reason: input);
    }
  });

  test('numbers that are not valid mobile numbers are rejected', () {
    for (final input in [
      '',
      '0171234567',
      '017123456789',
      '01212345678',
      '02123456789',
      'abcdefghijk',
    ]) {
      expect(normalizeBdPhone(input), isNull, reason: input);
    }
  });
}
