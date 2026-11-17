import 'package:flutter/material.dart';

import '../data/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  final SettingsRepository _repository;

  SettingsProvider(this._repository);

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      _themeMode = _parse(await _repository.read(_themeKey));
    } on Exception {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      await _repository.write(_themeKey, mode.name);
      // ignore: empty_catches
    } on Exception {}
  }

  ThemeMode _parse(String? raw) {
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return ThemeMode.system;
  }
}
