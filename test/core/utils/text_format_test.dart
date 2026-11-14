import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/utils/text_format.dart';

void main() {
  test('turns a server category into readable text', () {
    expect(prettyCategory('mens-shirts'), 'Mens shirts');
    expect(prettyCategory('beauty'), 'Beauty');
    expect(prettyCategory(''), '');
  });
}
