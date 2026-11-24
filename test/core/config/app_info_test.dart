import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/core/config/app_info.dart';

void main() {
  test('the version shown in the app matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml has no version line');
    expect(AppInfo.version, match!.group(1));
  });
}
