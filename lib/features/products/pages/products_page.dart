import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/products_providers.dart';

enum _ProductFilter { all, active, lowStock }

/// صفحة إدارة المنتجات الحديثة (SaaS UI).
///
/// عرض، بحث، تصفية، إضافة، تعديل، حذف مع التكيف الكامل للموبايل والديسكتب.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<Product>>? _searchFuture;
  _ProductFilter _selectedFilter = _ProductFilter.all;

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
          : ref.read(productsRepositoryProvider).searchProducts(_searchQuery);
    });
  }

  void _refreshSearchIfActive() {
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchFuture =
            ref.read(productsRepositoryProvider).searchProducts(_searchQuery);
      });
    }
  }

  Future<void> _openProductForm({Product? product}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductFormSheet(product: product),
    );
    _refreshSearchIfActive();
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.commonDelete),
          content: Text(l10n.productsDeleteConfirm(product.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                foregroundColor: theme.colorScheme.onErrorContainer,
                backgroundColor: theme.colorScheme.errorContainer,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await ref.read(productsRepositoryProvider).deleteProduct(product.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productsDeleted(product.name)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _refreshSearchIfActive();
    }
  }

  List<Product> _applyFilter(List<Product> items) {
    switch (_selectedFilter) {
      case _ProductFilter.active:
        return items.where((p) => p.isActive).toList();
      case _ProductFilter.lowStock:
        return items.where((p) => p.quantity <= p.minimumQuantity).toList();
      case _ProductFilter.all:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 900;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isWide ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // Header الرئيسي
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.productsTitle,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.dashboardSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _openProductForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.productsAdd),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =========================
              // Search and Filter Bar
              // =========================
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: l10n.productsSearchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                tooltip: l10n.commonClear,
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // رقائق الفلترة (Filter Chips)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedFilter == _ProductFilter.all,
                      label: Text(l10n.commonSearch),
                      onSelected: (val) {
                        setState(() => _selectedFilter = _ProductFilter.all);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == _ProductFilter.active,
                      label: Text(l10n.productsActive),
                      onSelected: (val) {
                        setState(() => _selectedFilter = _ProductFilter.active);
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _selectedFilter == _ProductFilter.lowStock,
                      avatar: Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: _selectedFilter == _ProductFilter.lowStock
                            ? colorScheme.onErrorContainer
                            : colorScheme.error,
                      ),
                      label: Text(l10n.dashboardLowStockTitle),
                      onSelected: (val) {
                        setState(() => _selectedFilter = _ProductFilter.lowStock);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =========================
              // محتوى المنتجات (Grid / List)
              // =========================
              Expanded(
                child: _buildBody(context, isWide),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isWide) {
    if (_searchQuery.isEmpty) {
      final productsAsync = ref.watch(productsProvider);

      return productsAsync.when(
        data: (items) {
          final filtered = _applyFilter(items);
          return filtered.isEmpty
              ? const _ProductsEmptyState()
              : _ProductsListView(
                  items: filtered,
                  isWide: isWide,
                  onEdit: (product) => _openProductForm(product: product),
                  onDelete: (product) => _confirmDelete(context, product),
                );
        },
        loading: () => const _ProductsLoadingState(),
        error: (error, stackTrace) => _ProductsErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(productsProvider),
        ),
      );
    }

    return FutureBuilder<List<Product>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _ProductsLoadingState();
        }

        if (snapshot.hasError) {
          return _ProductsErrorState(
            message: snapshot.error.toString(),
            onRetry: () => _onSearchChanged(_searchQuery),
          );
        }

        final items = _applyFilter(snapshot.data ?? const <Product>[]);

        return items.isEmpty
            ? const _ProductsEmptyState(isSearch: true)
            : _ProductsListView(
                items: items,
                isWide: isWide,
                onEdit: (product) => _openProductForm(product: product),
                onDelete: (product) => _confirmDelete(context, product),
              );
      },
    );
  }
}

/// شبكة / قائمة المنتجات المتكيفة
class _ProductsListView extends StatelessWidget {
  const _ProductsListView({
    required this.items,
    required this.isWide,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Product> items;
  final bool isWide;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = items[index];
          return _ProductCardItem(
            product: product,
            onEdit: () => onEdit(product),
            onDelete: () => onDelete(product),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount = (constraints.maxWidth / 360).floor().clamp(2, 4);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 175,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final product = items[index];

            return _ProductCardItem(
              product: product,
              onEdit: () => onEdit(product),
              onDelete: () => onDelete(product),
            );
          },
        );
      },
    );
  }
}

class _ProductCardItem extends StatelessWidget {
  const _ProductCardItem({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool lowStock = product.quantity <= product.minimumQuantity;

    return Card(
      elevation: 0,
      color: product.isActive
          ? colorScheme.surface
          : colorScheme.surfaceContainerLow.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: product.isActive
                          ? colorScheme.primaryContainer.withValues(alpha: 0.7)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: product.isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.productsSku(product.sku),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.commonEdit),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                            const SizedBox(width: 8),
                            Text(
                              l10n.commonDelete,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${product.sellingPrice.toStringAsFixed(2)} ${l10n.currencyDzd}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.purchasePrice > 0)
                        Text(
                          '${l10n.productsPurchasePrice}: ${product.purchasePrice.toStringAsFixed(2)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 6,
                    children: [
                      _InfoChip(
                        icon: lowStock ? Icons.warning_amber_rounded : Icons.numbers_rounded,
                        label: l10n.productsQuantity(product.quantity),
                        emphasize: lowStock,
                      ),
                      if (!product.isActive)
                        _InfoChip(
                          icon: Icons.visibility_off_outlined,
                          label: l10n.productsInactive,
                        ),
                    ],
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
    final colorScheme = theme.colorScheme;

    final Color background = emphasize
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;

    final Color foreground = emphasize
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductsLoadingState extends StatelessWidget {
  const _ProductsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ProductsErrorState extends StatelessWidget {
  const _ProductsErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.productsLoadError,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
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
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState({
    this.isSearch = false,
  });

  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
                size: 44,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? l10n.productsNoResults : l10n.productsEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearch ? l10n.productsSearchEmptyHint : l10n.productsEmptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// نموذج إضافة / تعديل منتج (Product Form Sheet)
class _ProductFormSheet extends ConsumerStatefulWidget {
  const _ProductFormSheet({
    this.product,
  });

  final Product? product;

  bool get isEditing => product != null;

  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumQuantityController;
  late final TextEditingController _categoryIdController;

  late bool _isActive;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(text: product?.name ?? '');
    _skuController = TextEditingController(text: product?.sku ?? '');
    _barcodeController = TextEditingController(text: product?.barcode ?? '');
    _purchasePriceController = TextEditingController(
      text: product != null ? product.purchasePrice.toString() : '',
    );
    _sellingPriceController = TextEditingController(
      text: product != null ? product.sellingPrice.toString() : '',
    );
    _quantityController = TextEditingController(
      text: product != null ? product.quantity.toString() : '0',
    );
    _minimumQuantityController = TextEditingController(
      text: product != null ? product.minimumQuantity.toString() : '0',
    );
    _categoryIdController = TextEditingController(
      text: product?.categoryId ?? '',
    );

    _isActive = product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    _minimumQuantityController.dispose();
    _categoryIdController.dispose();
    super.dispose();
  }

  String? _requiredValidator(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l10n.commonRequiredField;
    }
    return null;
  }

  String? _priceValidator(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    final requiredError = _requiredValidator(context, value);
    if (requiredError != null) return requiredError;

    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < 0) {
      return l10n.commonInvalidValue;
    }
    return null;
  }

  String? _intValidator(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) return null;

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return l10n.commonInvalidValue;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final String name = _nameController.text.trim();
    final String sku = _skuController.text.trim();
    final String barcode = _barcodeController.text.trim();
    final double purchasePrice = double.parse(_purchasePriceController.text.trim());
    final double sellingPrice = double.parse(_sellingPriceController.text.trim());
    final int quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final int minimumQuantity = int.tryParse(_minimumQuantityController.text.trim()) ?? 0;
    final String categoryId = _categoryIdController.text.trim();

    final repository = ref.read(productsRepositoryProvider);
    final now = DateTime.now();

    try {
      if (widget.isEditing) {
        final updated = widget.product!.copyWith(
          name: name,
          sku: sku,
          barcode: Value(barcode.isEmpty ? null : barcode),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          quantity: quantity,
          minimumQuantity: minimumQuantity,
          categoryId: Value(categoryId.isEmpty ? null : categoryId),
          isActive: _isActive,
          updatedAt: now,
          version: widget.product!.version + 1,
        );

        await repository.updateProduct(updated);
      } else {
        final tenantId = ref.read(authControllerProvider).user?.tenantId ?? '';
        const deviceId = 'unknown-device';

        final companion = ProductsCompanion.insert(
          id: const Uuid().v4(),
          tenantId: tenantId,
          createdAt: now,
          updatedAt: now,
          deviceId: deviceId,
          name: name,
          sku: sku,
          barcode: barcode.isEmpty ? const Value.absent() : Value(barcode),
          purchasePrice: purchasePrice,
          sellingPrice: sellingPrice,
          quantity: Value(quantity),
          minimumQuantity: Value(minimumQuantity),
          categoryId: categoryId.isEmpty ? const Value.absent() : Value(categoryId),
          isActive: Value(_isActive),
        );

        await repository.addProduct(companion);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.productsSaveFailed(e)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 600;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 600 : double.infinity,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEditing ? l10n.productsEdit : l10n.productsAdd,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // البيانات الأساسية
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.productsName,
                      prefixIcon: const Icon(Icons.label_outlined),
                    ),
                    validator: (value) => _requiredValidator(context, value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _skuController,
                          decoration: const InputDecoration(
                            labelText: 'SKU',
                            prefixIcon: Icon(Icons.qr_code_outlined),
                          ),
                          validator: (value) => _requiredValidator(context, value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: l10n.productsBarcodeOptional,
                            prefixIcon: const Icon(Icons.barcode_reader),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // الأسعار والمخزون
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          decoration: InputDecoration(
                            labelText: l10n.productsPurchasePrice,
                            prefixIcon: const Icon(Icons.shopping_bag_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => _priceValidator(context, value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          decoration: InputDecoration(
                            labelText: l10n.productsSalePrice,
                            prefixIcon: const Icon(Icons.sell_outlined),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) => _priceValidator(context, value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText: l10n.productsQuantityLabel,
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => _intValidator(context, value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minimumQuantityController,
                          decoration: InputDecoration(
                            labelText: l10n.productsMinimum,
                            prefixIcon: const Icon(Icons.warning_amber_rounded),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => _intValidator(context, value),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryIdController,
                    decoration: InputDecoration(
                      labelText: l10n.productsCategoryOptional,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                  ),

                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.productsActive),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.isEditing
                                  ? l10n.commonSave
                                  : l10n.productsAddAction,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}