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

    String selectedRole = user?.role.isNotEmpty == true
        ? user!.role
        : 'cashier';

    bool isActive = user?.isActive ?? true;

    final isEditing = user != null;

    final result = await showDialog<UserModel>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing
                    ? l10n.usersEditUser
                    : l10n.usersAddUser,
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.usersColumnName,
                          prefixIcon:
                              const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: l10n.usersColumnEmail,
                          prefixIcon:
                              const Icon(Icons.email_outlined),
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
                            setDialogState(() {
                              selectedRole = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: Text(l10n.usersColumnStatus),
                        subtitle: Text(
                          isActive
                              ? l10n.usersStatusActive
                              : l10n.usersStatusInactive,
                        ),
                        value: isActive,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();

                    if (name.isEmpty || email.isEmpty) {
                      return;
                    }

                    final authUser =
                        ref.read(authControllerProvider).user;

                    if (authUser == null) {
                      return;
                    }

                    final newUser = UserModel(
                      uid: user?.uid ??
                          DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),
                      tenantId:
                          user?.tenantId ?? authUser.tenantId,
                      fullName: name,
                      email: email,
                      role: selectedRole,
                      isActive: isActive,
                      createdAt:
                          user?.createdAt ?? DateTime.now(),
                    );

                    Navigator.of(context).pop(newUser);
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

    if (result == null) {
      return;
    }

    try {
      if (isEditing) {
        await ref
            .read(usersRepositoryProvider)
            .updateUser(result);
      } else {
        await ref
            .read(usersRepositoryProvider)
            .updateUser(result);
      }

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
          content: Text(
            '${l10n.usersDeleteConfirm}\n"${user.fullName}"',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error,
                foregroundColor:
                    Theme.of(context).colorScheme.onError,
              ),
              onPressed: () =>
                  Navigator.of(context).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(usersRepositoryProvider)
          .deleteUser(user.uid);

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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: usersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Center(child: Text(error.toString())),
            data: (users) {
              final query = _searchQuery.trim().toLowerCase();

              final filteredUsers = query.isEmpty
                  ? users
                  : users.where((user) {
                      final name =
                          user.fullName.toLowerCase();
                      final email =
                          user.email.toLowerCase();
                      final role = _getRoleLabel(
                        user.role,
                        l10n,
                      ).toLowerCase();

                      return name.contains(query) ||
                          email.contains(query) ||
                          role.contains(query);
                    }).toList();

              final totalCount = users.length;
              final activeCount =
                  users.where((u) => u.isActive).length;

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.usersTitle,
                            style: theme
                                .textTheme.headlineMedium
                                ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.usersSubtitle,
                            style: theme
                                .textTheme.bodyMedium
                                ?.copyWith(
                              color:
                                  colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showUserDialog(),
                        icon: const Icon(
                          Icons.person_add_rounded,
                        ),
                        label: Text(l10n.usersAddUser),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _UserMetricCard(
                        title: l10n.usersTotalCount,
                        value: totalCount.toString(),
                        icon: Icons.people_alt_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 16),
                      _UserMetricCard(
                        title: l10n.usersActiveCount,
                        value: activeCount.toString(),
                        icon:
                            Icons.check_circle_outline_rounded,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: l10n.usersSearchHint,
                      prefixIcon:
                          const Icon(Icons.search_rounded),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear_rounded,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                l10n.usersEmptyList,
                                style: theme
                                    .textTheme.bodyLarge
                                    ?.copyWith(
                                  color: colors
                                      .onSurfaceVariant,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding:
                                  const EdgeInsets.all(8),
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  headingRowHeight: 52,
                                  dataRowMaxHeight: 68,
                                  horizontalMargin: 16,
                                  columnSpacing: 24,
                                  columns: [
                                    DataColumn(
                                      label: Text(
                                        l10n.usersColumnName,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        l10n.usersColumnEmail,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        l10n.usersColumnRole,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        l10n.usersColumnStatus,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        l10n.usersColumnActions,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  rows: filteredUsers
                                      .map((user) {
                                    final roleColor =
                                        _getRoleColor(
                                      user.role,
                                      colors,
                                    );

                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    colors
                                                        .primaryContainer,
                                                child: Text(
                                                  user.fullName
                                                          .isNotEmpty
                                                      ? user.fullName[
                                                              0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: TextStyle(
                                                    color: colors
                                                        .onPrimaryContainer,
                                                    fontWeight:
                                                        FontWeight
                                                            .bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                  width: 12),
                                              Text(
                                                user.fullName,
                                                style:
                                                    const TextStyle(
                                                  fontWeight:
                                                      FontWeight
                                                          .w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(user.email),
                                        ),
                                        DataCell(
                                          Chip(
                                            labelPadding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 8,
                                            ),
                                            padding:
                                                EdgeInsets.zero,
                                            backgroundColor:
                                                roleColor
                                                    .withValues(
                                              alpha: 0.15,
                                            ),
                                            side: BorderSide(
                                              color: roleColor
                                                  .withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                            label: Text(
                                              _getRoleLabel(
                                                user.role,
                                                l10n,
                                              ),
                                              style: TextStyle(
                                                color: roleColor,
                                                fontWeight:
                                                    FontWeight
                                                        .w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Chip(
                                            avatar: Icon(
                                              user.isActive
                                                  ? Icons
                                                      .check_circle_rounded
                                                  : Icons
                                                      .cancel_rounded,
                                              size: 16,
                                              color: user.isActive
                                                  ? Colors.green
                                                  : colors.error,
                                            ),
                                            labelPadding:
                                                const EdgeInsets
                                                    .symmetric(
                                              horizontal: 4,
                                            ),
                                            padding:
                                                EdgeInsets.zero,
                                            backgroundColor:
                                                user.isActive
                                                    ? Colors.green
                                                        .withValues(
                                                        alpha: 0.12,
                                                      )
                                                    : colors
                                                        .errorContainer
                                                        .withValues(
                                                        alpha: 0.3,
                                                      ),
                                            side: BorderSide.none,
                                            label: Text(
                                              user.isActive
                                                  ? l10n
                                                      .usersStatusActive
                                                  : l10n
                                                      .usersStatusInactive,
                                              style: TextStyle(
                                                color: user.isActive
                                                    ? Colors.green
                                                    : colors.error,
                                                fontWeight:
                                                    FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons
                                                      .edit_outlined,
                                                ),
                                                tooltip: l10n
                                                    .usersEditUser,
                                                onPressed: () =>
                                                    _showUserDialog(
                                                  user: user,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  Icons
                                                      .delete_outline,
                                                  color:
                                                      colors.error,
                                                ),
                                                tooltip: l10n
                                                    .usersDeleteUser,
                                                onPressed: () =>
                                                    _confirmDelete(
                                                  user,
                                                ),
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
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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

    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme
                          .colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme
                        .textTheme.headlineSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
