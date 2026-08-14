import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings_state.dart';

class _PrefsKeys {
  _PrefsKeys();

  static const String localeCode = 'app_settings.locale_code';
  static const String themeMode = 'app_settings.theme_mode';
}

class AppSettingsController
    extends StateNotifier<AppSettingsState> {
  AppSettingsController(this._prefs)
      : super(_readInitialState(_prefs));

  final SharedPreferences _prefs;

  static AppSettingsState _readInitialState(
    SharedPreferences prefs,
  ) {
    const defaults = AppSettingsState.initial();

    final String? storedLocale =
        prefs.getString(_PrefsKeys.localeCode);

    final String? storedTheme =
        prefs.getString(_PrefsKeys.themeMode);

    return AppSettingsState(
      locale: storedLocale != null
          ? Locale(storedLocale)
          : defaults.locale,
      themeMode:
          _themeModeFromString(storedTheme) ??
              defaults.themeMode,
    );
  }

  static ThemeMode? _themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return null;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'dark';
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (state.locale.languageCode ==
        locale.languageCode) {
      return;
    }

    state = state.copyWith(locale: locale);

    await _prefs.setString(
      _PrefsKeys.localeCode,
      locale.languageCode,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == ThemeMode.system) {
      return;
    }

    if (state.themeMode == mode) {
      return;
    }

    state = state.copyWith(themeMode: mode);

    await _prefs.setString(
      _PrefsKeys.themeMode,
      _themeModeToString(mode),
    );
  }
}