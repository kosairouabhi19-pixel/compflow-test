import 'package:flutter/material.dart';

/// الحالة الحالية لإعدادات التطبيق العامة (اللغة والمظهر) التي يجب أن
/// تبقى محفوظة محلياً بين مرات تشغيل التطبيق.
@immutable
class AppSettingsState {
  const AppSettingsState({
    required this.locale,
    required this.themeMode,
  });

  /// القيم الافتراضية عند أول تشغيل للتطبيق: عربي + مظهر داكن.
  const AppSettingsState.initial()
      : locale = const Locale('ar'),
        themeMode = ThemeMode.dark;

  final Locale locale;
  final ThemeMode themeMode;

  AppSettingsState copyWith({
    Locale? locale,
    ThemeMode? themeMode,
  }) {
    return AppSettingsState(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}