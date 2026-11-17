import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/settings/data/sqlite_settings_repository.dart';
import 'package:shoplite/features/settings/presentation/settings_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/test_support.dart';

void main() {
  late Database db;
  late SqliteSettingsRepository repo;

  setUp(() async {
    db = await openTestDatabase();
    repo = SqliteSettingsRepository(() async => db);
  });

  tearDown(() => db.close());

  test(
    'a missing setting reads as null, and a saved one can be replaced',
    () async {
      expect(await repo.read('k'), isNull);

      await repo.write('k', 'one');
      await repo.write('k', 'two');

      expect(await repo.read('k'), 'two');
    },
  );

  test('the theme follows the phone until the user chooses', () async {
    final settings = SettingsProvider(repo);
    await settings.load();

    expect(settings.themeMode, ThemeMode.system);
  });

  test('a chosen theme is remembered after a restart', () async {
    final first = SettingsProvider(repo);
    await first.load();
    await first.setThemeMode(ThemeMode.dark);
    expect(first.themeMode, ThemeMode.dark);

    final restarted = SettingsProvider(repo);
    await restarted.load();
    expect(restarted.themeMode, ThemeMode.dark);
  });

  test('an unknown saved value falls back to the system theme', () async {
    await repo.write('theme_mode', 'sepia');

    final settings = SettingsProvider(repo);
    await settings.load();

    expect(settings.themeMode, ThemeMode.system);
  });
}
