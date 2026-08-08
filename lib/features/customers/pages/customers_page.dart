import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/customers_providers.dart';

/// صفحة العملاء الكاملة: عرض، بحث، إضافة، تعديل، حذف.
///
/// تعتمد فقط على customersProvider و CustomersRepository الموجودين مسبقاً،
/// وتتبع نفس أسلوب تصميم صفحة المنتجات لضمان توحيد الواجهة.
class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<Customer>>? _searchFuture;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _searchFuture = _searchQuery.isEmpty
          ? null
          : ref.read(customersRepositoryProvider).searchCustomers(_searchQuery);
    });
  }

  void _refreshSearchIfActive() {
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchFuture = ref
            .read(customersRepositoryProvider)
            .searchCustomers(_searchQuery);
      });
    }
  }

  Future<void> _openCustomerForm({Customer? customer}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CustomerFormSheet(customer: customer),
    );
    _refreshSearchIfActive();
  }

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف العميل'),
          content: Text('هل أنت متأكد من حذف "${customer.fullName}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(customersRepositoryProvider).deleteCustomer(customer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف "${customer.fullName}"')),
        );
      }
      _refreshSearchIfActive();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('العملاء'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 12,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 720 : double.infinity,
                ),
                child: SearchBar(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  hintText: 'ابحث عن عميل بالاسم...',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'مسح البحث',
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody(context, isWide)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCustomerForm(),
        tooltip: 'إضافة عميل',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isWide) {
    if (_searchQuery.isEmpty) {
      final customersAsync = ref.watch(customersProvider);

      return customersAsync.when(
        data: (items) => items.isEmpty
            ? const _CustomersEmptyState()
            : _CustomersListView(
                items: items,
                isWide: isWide,
                onEdit: (customer) => _openCustomerForm(customer: customer),
                onDelete: (customer) => _confirmDelete(context, customer),
              ),
        loading: () => const _CustomersLoadingState(),
        error: (error, stackTrace) => _CustomersErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(customersProvider),
        ),
      );
    }

    return FutureBuilder<List<Customer>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _CustomersLoadingState();
        }
        if (snapshot.hasError) {
          return _CustomersErrorState(
            message: snapshot.error.toString(),
            onRetry: () => _onSearchChanged(_searchQuery),
          );
        }
        final items = snapshot.data ?? const <Customer>[];
        return items.isEmpty
            ? const _CustomersEmptyState(isSearch: true)
            : _CustomersListView(
                items: items,
                isWide: isWide,
                onEdit: (customer) => _openCustomerForm(customer: customer),
                onDelete: (customer) => _confirmDelete(context, customer),
              );
      },
    );
  }
}

/// قائمة/شبكة العملاء، تتكيّف مع عرض الشاشة (Responsive).
class _CustomersListView extends StatelessWidget {
  const _CustomersListView({
    required this.items,
    required this.isWide,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Customer> items;
  final bool isWide;
  final ValueChanged<Customer> onEdit;
  final ValueChanged<Customer> onDelete;

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: isWide ? 24 : 16,
      vertical: 8,
    );

    if (!isWide) {
      return ListView.builder(
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final customer = items[index];
          return _CustomerCard(
            customer: customer,
            onEdit: () => onEdit(customer),
            onDelete: () => onDelete(customer),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = (constraints.maxWidth / 380)
            .floor()
            .clamp(2, 4);

        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 190,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final customer = items[index];
            return _CustomerCard(
              customer: customer,
              onEdit: () => onEdit(customer),
              onDelete: () => onDelete(customer),
            );
          },
        );
      },
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: customer.isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: customer.isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') onEdit();
                            if (value == 'delete') onDelete();
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('تعديل'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('حذف'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      customer.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (customer.email != null && customer.email!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.email_outlined,
                            label: customer.email!,
                          ),
                        if (customer.address != null &&
                            customer.address!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: customer.address!,
                          ),
                        if (!customer.isActive)
                          const _InfoChip(
                            icon: Icons.visibility_off_outlined,
                            label: 'غير نشط',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color background = emphasize
        ? theme.colorScheme.errorContainer
        : theme.colorScheme.secondaryContainer;
    final Color foreground = emphasize
        ? theme.colorScheme.onErrorContainer
        : theme.colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: foreground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة التحميل.
class _CustomersLoadingState extends StatelessWidget {
  const _CustomersLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// حالة الخطأ مع إمكانية إعادة المحاولة.
class _CustomersErrorState extends StatelessWidget {
  const _CustomersErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 420 : 320),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ أثناء تحميل العملاء',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الحالة الفارغة لقائمة العملاء.
class _CustomersEmptyState extends StatelessWidget {
  const _CustomersEmptyState({this.isSearch = false});

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 420 : 320),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSearch ? Icons.search_off : Icons.people_outline,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSearch ? 'لا توجد نتائج مطابقة' : 'لا يوجد عملاء بعد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSearch
                    ? 'جرّب كلمة بحث مختلفة أو تحقق من الإملاء.'
                    : 'ابدأ بإضافة أول عميل لديك عبر زر الإضافة أسفل الشاشة.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نموذج إضافة / تعديل عميل، يُعرض كـ Bottom Sheet.
class _CustomerFormSheet extends ConsumerStatefulWidget {
  const _CustomerFormSheet({this.customer});

  final Customer? customer;

  bool get isEditing => customer != null;

  @override
  ConsumerState<_CustomerFormSheet> createState() =>
      _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late bool _isActive;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    _fullNameController = TextEditingController(text: customer?.fullName ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
    _addressController = TextEditingController(text: customer?.address ?? '');
    _notesController = TextEditingController(text: customer?.notes ?? '');
    _isActive = customer?.isActive ?? true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'بريد إلكتروني غير صالح';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final String fullName = _fullNameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String email = _emailController.text.trim();
    final String address = _addressController.text.trim();
    final String notes = _notesController.text.trim();

    final repository = ref.read(customersRepositoryProvider);
    final now = DateTime.now();

    try {
      if (widget.isEditing) {
        final updated = widget.customer!.copyWith(
          fullName: fullName,
          phone: phone,
          email: Value(email.isEmpty ? null : email),
          address: Value(address.isEmpty ? null : address),
          notes: Value(notes.isEmpty ? null : notes),
          isActive: _isActive,
          updatedAt: now,
          version: widget.customer!.version + 1,
        );
        await repository.updateCustomer(updated);
      } else {
        // TODO: استبدل بالمعرّف الفعلي للمستأجر بمجرد التأكد من تسجيل الدخول
        // (يُفترض أن AuthController يوفر المستخدم الحالي؛ إن كان null فهذا
        // يعني أن المستخدم غير مسجل دخول، وهي حالة يجب معالجتها لاحقاً).
        final tenantId = ref.read(authControllerProvider).user?.tenantId ?? '';

        // TODO: استبدل بمعرّف الجهاز الحقيقي عند توفر خدمة device info
        // ضمن مشروع CompFlow (غير متوفرة حالياً في الملفات المُتاحة).
        const deviceId = 'unknown-device';

        final companion = CustomersCompanion.insert(
          id: const Uuid().v4(),
          tenantId: tenantId,
          createdAt: now,
          updatedAt: now,
          deviceId: deviceId,
          fullName: fullName,
          phone: phone,
          email: email.isEmpty ? const Value.absent() : Value(email),
          address: address.isEmpty ? const Value.absent() : Value(address),
          notes: notes.isEmpty ? const Value.absent() : Value(notes),
          isActive: Value(_isActive),
        );
        await repository.insertCustomer(companion);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ العميل: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 600;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: mediaQuery.viewInsets.bottom + 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isEditing ? 'تعديل عميل' : 'إضافة عميل',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                    keyboardType: TextInputType.phone,
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني (اختياري)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'العنوان (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('عميل نشط'),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.isEditing ? 'حفظ التعديلات' : 'إضافة العميل',
                          ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}