import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_providers.dart';
import '../../l10n/app_localizations.dart';

class AppSidebar extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onSelect;
  final VoidCallback? onReports;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.onReports,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = ref.watch(authControllerProvider).user;
    final language = Localizations.localeOf(context).languageCode;
    final logoutLabel = switch (language) {
      'fr' => 'Se déconnecter',
      'en' => 'Log out',
      _ => 'تسجيل الخروج',
    };

    final items = [
      (Icons.dashboard_rounded, l10n.navDashboard),
      (Icons.point_of_sale_rounded, l10n.navPos),
      (Icons.inventory_2_rounded, l10n.navProducts),
      (Icons.receipt_long_rounded, l10n.navSales),
      (Icons.people_alt_rounded, l10n.navUsers),
      (Icons.settings_rounded, l10n.navSettings),
    ];

    final displayName = currentUser?.fullName.trim().isNotEmpty == true
        ? currentUser!.fullName.trim()
        : currentUser?.email ?? l10n.navUsers;
    final displayRole = currentUser?.role.trim().isNotEmpty == true
        ? currentUser!.role
        : null;

    Future<void> logout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(logoutLabel),
          content: Text(
            switch (language) {
              'fr' => 'Voulez-vous vraiment vous déconnecter ?',
              'en' => 'Are you sure you want to log out?',
              _ => 'هل أنت متأكد أنك تريد تسجيل الخروج؟',
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(logoutLabel),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await ref.read(authControllerProvider.notifier).signOut();
      }
    }

    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: BorderDirectional(end: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.memory_rounded, color: colorScheme.onPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text('CompFlow', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (int index = 0; index < items.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _SidebarItem(
                        icon: items[index].$1,
                        label: items[index].$2,
                        selected: selectedIndex == index,
                        onTap: () => onSelect(index),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: _SidebarItem(
                      icon: Icons.analytics_outlined,
                      label: l10n.navReports,
                      selected: false,
                      onTap: onReports,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: colorScheme.primary,
                          child: Icon(Icons.person_rounded, color: colorScheme.onPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(displayName, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                              if (displayRole != null)
                                Text(displayRole, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: Text(logoutLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
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