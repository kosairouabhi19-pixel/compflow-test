import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_settings_providers.dart';
import '../../../l10n/app_localizations.dart';

/// صفحة الإعدادات المخصصة لتطبيق سطح المكتب (Windows Desktop):
/// التبديل الفوري بين اللغات الثلاث (العربية، الإنجليزية، الفرنسية) والمظهر (داكن / فاتح)
/// والمعلومات العامة للتطبيق، باستخدام AppLocalizations بالكامل وبدون أي نص ثابت.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsControllerProvider);
    final controller = ref.read(appSettingsControllerProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Desktop Header
              Text(
                l10n.settingsTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.settingsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Language Section
                        _SettingsCard(
                          title: l10n.settingsLanguageSection,
                          icon: Icons.language_outlined,
                          child: Column(
                            children: [
                              _RadioSettingOptionTile(
                                label: l10n.settingsLanguageArabic,
                                subtitle: l10n.settingsLanguageArabicNative,
                                selected: settings.locale.languageCode == 'ar',
                                onSelect: () => controller.setLocale(const Locale('ar')),
                              ),
                              const Divider(height: 1),
                              _RadioSettingOptionTile(
                                label: l10n.settingsLanguageEnglish,
                                subtitle: l10n.settingsLanguageEnglishNative,
                                selected: settings.locale.languageCode == 'en',
                                onSelect: () => controller.setLocale(const Locale('en')),
                              ),
                              const Divider(height: 1),
                              _RadioSettingOptionTile(
                                label: l10n.settingsLanguageFrench,
                                subtitle: l10n.settingsLanguageFrenchNative,
                                selected: settings.locale.languageCode == 'fr',
                                onSelect: () => controller.setLocale(const Locale('fr')),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Theme Section
                        _SettingsCard(
                          title: l10n.settingsThemeSection,
                          icon: Icons.dark_mode_outlined,
                          child: Column(
                            children: [
                              _RadioSettingOptionTile(
                                label: l10n.settingsThemeDark,
                                icon: Icons.dark_mode_outlined,
                                selected: settings.themeMode == ThemeMode.dark,
                                onSelect: () => controller.setThemeMode(ThemeMode.dark),
                              ),
                              const Divider(height: 1),
                              _RadioSettingOptionTile(
                                label: l10n.settingsThemeLight,
                                icon: Icons.light_mode_outlined,
                                selected: settings.themeMode == ThemeMode.light,
                                onSelect: () => controller.setThemeMode(ThemeMode.light),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // About Section
                        _SettingsCard(
                          title: l10n.settingsAboutSection,
                          icon: Icons.info_outline_rounded,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'C',
                                    style: TextStyle(
                                      color: colors.onPrimary,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.appTitle,
                                        style: theme.textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        l10n.settingsAboutDescription,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${l10n.settingsVersion}: 1.0.0',
                                          style: theme.textTheme.labelMedium?.copyWith(
                                            color: colors.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: colors.surfaceContainerHigh,
            child: Row(
              children: [
                Icon(icon, color: colors.primary, size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RadioSettingOptionTile extends StatelessWidget {
  const _RadioSettingOptionTile({
    required this.label,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: icon != null
          ? Icon(
              icon,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            )
          : Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            )
          : null,
      trailing: icon != null
          ? Switch(
              value: selected,
              onChanged: (_) => onSelect(),
            )
          : (selected
              ? Icon(Icons.check_circle_rounded, color: colors.primary)
              : null),
      onTap: onSelect,
    );
  }
}