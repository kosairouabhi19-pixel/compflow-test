import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings_controller.dart';
import 'app_settings_state.dart';

final sharedPreferencesProvider =
    Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

final appSettingsControllerProvider = StateNotifierProvider<
    AppSettingsController,
    AppSettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);

  return AppSettingsController(prefs);
});