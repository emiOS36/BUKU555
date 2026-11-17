import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferences {
  ThemePreferences._();

  static final ThemePreferences instance = ThemePreferences._();

  static const _themeKey = 'theme_mode';

  final _preferences = SharedPreferencesAsync();

  final ValueNotifier<ThemeMode> current = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final savedMode = await _preferences.getString(_themeKey);

    current.value = ThemeMode.values.firstWhere(
      (mode) => mode.name == savedMode,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> save(ThemeMode mode) async {
    await _preferences.setString(_themeKey, mode.name);
    current.value = mode;
  }
}
