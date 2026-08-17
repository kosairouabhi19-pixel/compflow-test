import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/user_model.dart';
import '../providers/users_providers.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getRoleLabel(String role, AppLocalizations l10n) {
    switch (role.toLowerCase()) {
      case 'admin':
        return l10n.usersRoleAdmin;
      case 'manager':
        return l10n.usersRoleManager;
      case 'cashier':
        return l10n.usersRoleCashier;
      default:
        return role;
    }
  }

  Color _getRoleColor(String role, ColorScheme colors) {
    switch (role.toLowerCase()) {
      case 'admin':
        return colors.primary;
      case 'manager':
        return colors.tertiary;
      case 'cashier':
        return colors.secondary;
      default:
        return colors.outline;
    }
  }

  Future<void> _showUserDialog({UserModel? user}) async {
    final l10n = AppLocalizations.of(context);
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');

    String selectedRole =
        user?.role.isNotEmpty == true ? user!.role : 'cashier';
    bool isActive = user?.isActive ?? true;
    final isEditing = user != null;

    final result = await showDialog<UserModel>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? l10n.usersEditUser : l10n.usersAddUser,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.usersColumnName,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l10n.usersColumnEmail,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: l10n.usersColumnRole,
                        prefixIcon: const Icon(
                          Icons.admin_panel_settings_outlined,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'admin',
                          child: Text(l10n.usersRoleAdmin),
                        ),
                        DropdownMenuItem(
                          value: 'manager',
                          child: Text(l10n.usersRoleManager),
                        ),
                        DropdownMenuItem(
                          value: 'cashier',
                          child: Text(l10n.usersRoleCashier),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.usersColumnStatus),
                      subtitle: Text(
                        isActive
                            ? l10n.usersStatusActive
                            : l10n.usersStatusInactive,
                      ),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty || email.isEmpty) return;

                    final authUser = ref.read(authControllerProvider).user;
                    if (authUser == null) return;

                    Navigator.of(dialogContext).pop(
                      UserModel(
                        uid: user?.uid ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        tenantId: user?.tenantId ?? authUser.tenantId,
                        fullName: name,
                        email: email,
                        role: selectedRole,
                        isActive: isActive,
                        createdAt: user?.createdAt ?? DateTime.now(),
                      ),
                    );
                  },
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();

    if (result == null) return;

    try {
      await ref.read(usersRepositoryProvider).updateUser(result);
      ref.invalidate(usersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _confirmDelete(UserModel user) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.usersDeleteUser),
          content: Text('${l10n.usersDeleteConfirm}\n"${user.fullName}"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await ref.read(usersRepositoryProvider).deleteUser(user.uid);
      ref.invalidate(usersProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final horizontalPadding = compact ? 16.0 : 28.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                compact ? 18 : 28,
                horizontalPadding,
                compact ? 18 : 28,
              ),
              child: usersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
                data: (users) {
                  final query = _searchQuery.trim().toLowerCase();
                  final filteredUsers = query.isEmpty
                      ? users
                      : users.where((user) {
                          final name = user.fullName.toLowerCase();
                          final email = user.email.toLowerCase();
                          final role = _getRoleLabel(user.role, l10n)
                              .toLowerCase();
                          return name.contains(query) ||
                              email.contains(query) ||
                              role.contains(query);
                        }).toList();

                  final totalCount = users.length;
                  final activeCount = users.where((u) => u.isActive).length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UsersHeader(
                        compact: compact,
                        title: l10n.usersTitle,
                        subtitle: l10n.usersSubtitle,
                        addLabel: l10n.usersAddUser,
                        onAdd: () => _showUserDialog(),
                      ),
                      SizedBox(height: compact ? 20 : 26),
                      _UsersMetrics(
                        compact: compact,
                        totalTitle: l10n.usersTotalCount,
                        totalValue: totalCount.toString(),
                        activeTitle: l10n.usersActiveCount,
                        activeValue: activeCount.toString(),
                        primaryColor: colors.primary,
                      ),
                      SizedBox(height: compact ? 18 : 24),
                      _SearchBox(
                        controller: _searchController,
                        hintText: l10n.usersSearchHint,
                        query: _searchQuery,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        onClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: compact
                            ? _MobileUsersList(
                                users: filteredUsers,
                                l10n: l10n,
                                colors: colors,
                                onEdit: _showUserDialog,
                                onDelete: _confirmDelete,
                              )
                            : _DesktopUsersTable(
                                users: filteredUsers,
                                l10n: l10n,
                                colors: colors,
                                onEdit: _showUserDialog,
                                onDelete: _confirmDelete,
                              ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.addLabel,
    required this.onAdd,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    );

    final button = FilledButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.person_add_alt_1_rounded),
      label: Text(addLabel),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 16),
          button,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 20),
        button,
      ],
    );
  }
}

class _UsersMetrics extends StatelessWidget {
  const _UsersMetrics({
    required this.compact,
    required this.totalTitle,
    required this.totalValue,
    required this.activeTitle,
    required this.activeValue,
    required this.primaryColor,
  });

  final bool compact;
  final String totalTitle;
  final String totalValue;
  final String activeTitle;
  final String activeValue;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    final children = [
      Expanded(
        child: _UserMetricCard(
          title: totalTitle,
          value: totalValue,
          icon: Icons.people_alt_outlined,
          color: primaryColor,
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: _UserMetricCard(
          title: activeTitle,
          value: activeValue,
          icon: Icons.check_circle_outline_rounded,
          color: Colors.green,
        ),
      ),
    ];

    return Row(children: children);
  }
}

class _UserMetricCard extends StatelessWidget {
  const _UserMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.hintText,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
    );
  }
}

class _MobileUsersList extends StatelessWidget {
  const _MobileUsersList({
    required this.users,
    required this.l10n,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UserModel> users;
  final AppLocalizations l10n;
  final ColorScheme colors;
  final Future<void> Function({UserModel? user}) onEdit;
  final Future<void> Function(UserModel user) onDelete;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyUsersState(message: l10n.usersEmptyList);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = users[index];
          final roleColor = _roleColor(user.role, colors);

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: l10n.usersColumnActions,
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit(user: user);
                        } else if (value == 'delete') {
                          onDelete(user);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.edit_outlined),
                            title: Text(l10n.usersEditUser),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.delete_outline,
                              color: colors.error,
                            ),
                            title: Text(l10n.usersDeleteUser),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _RoleChip(
                      label: _roleLabel(user.role, l10n),
                      color: roleColor,
                    ),
                    _StatusChip(
                      active: user.isActive,
                      activeLabel: l10n.usersStatusActive,
                      inactiveLabel: l10n.usersStatusInactive,
                      colors: colors,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DesktopUsersTable extends StatelessWidget {
  const _DesktopUsersTable({
    required this.users,
    required this.l10n,
    required this.colors,
    required this.onEdit,
    required this.onDelete,
  });

  final List<UserModel> users;
  final AppLocalizations l10n;
  final ColorScheme colors;
  final Future<void> Function({UserModel? user}) onEdit;
  final Future<void> Function(UserModel user) onDelete;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyUsersState(message: l10n.usersEmptyList);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: double.infinity,
          child: DataTable(
            headingRowHeight: 54,
            dataRowMaxHeight: 72,
            horizontalMargin: 16,
            columnSpacing: 28,
            columns: [
              _column(l10n.usersColumnName),
              _column(l10n.usersColumnEmail),
              _column(l10n.usersColumnRole),
              _column(l10n.usersColumnStatus),
              _column(l10n.usersColumnActions),
            ],
            rows: users.map((user) {
              final roleColor = _roleColor(user.role, colors);

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: colors.primaryContainer,
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: colors.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 190),
                          child: Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    _RoleChip(
                      label: _roleLabel(user.role, l10n),
                      color: roleColor,
                    ),
                  ),
                  DataCell(
                    _StatusChip(
                      active: user.isActive,
                      activeLabel: l10n.usersStatusActive,
                      inactiveLabel: l10n.usersStatusInactive,
                      colors: colors,
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n.usersEditUser,
                          onPressed: () => onEdit(user: user),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: colors.error),
                          tooltip: l10n.usersDeleteUser,
                          onPressed: () => onDelete(user),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn _column(String label) {
    return DataColumn(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.active,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.colors,
  });

  final bool active;
  final String activeLabel;
  final String inactiveLabel;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.green : colors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            active ? activeLabel : inactiveLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyUsersState extends StatelessWidget {
  const _EmptyUsersState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 42,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _roleLabel(String role, AppLocalizations l10n) {
  switch (role.toLowerCase()) {
    case 'admin':
      return l10n.usersRoleAdmin;
    case 'manager':
      return l10n.usersRoleManager;
    case 'cashier':
      return l10n.usersRoleCashier;
    default:
      return role;
  }
}

Color _roleColor(String role, ColorScheme colors) {
  switch (role.toLowerCase()) {
    case 'admin':
      return colors.primary;
    case 'manager':
      return colors.tertiary;
    case 'cashier':
      return colors.secondary;
    default:
      return colors.outline;
  }
}
