import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/products_providers.dart';

/// صفحة المنتجات الكاملة: عرض، بحث، إضافة، تعديل، حذف.
///
/// تعتمد فقط على productsProvider و ProductsRepository الموجودين مسبقاً.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<Product>>? _searchFuture;

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
      builder: (context) => _ProductFormSheet(product: product),
    );
    _refreshSearchIfActive();
  }

  Future<void> _confirmDelete(BuildContext context, Product product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المنتج'),
          content: Text('هل أنت متأكد من حذف "${product.name}"؟'),
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
      await ref.read(productsRepositoryProvider).deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف "${product.name}"')),
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
        title: const Text('المنتجات'),
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
                  hintText: 'ابحث عن منتج بالاسم أو SKU...',
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
        onPressed: () => _openProductForm(),
        tooltip: 'إضافة منتج',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isWide) {
    if (_searchQuery.isEmpty) {
      final productsAsync = ref.watch(productsProvider);

      return productsAsync.when(
        data: (items) => items.isEmpty
            ? const _ProductsEmptyState()
            : _ProductsListView(
                items: items,
                isWide: isWide,
                onEdit: (product) => _openProductForm(product: product),
                onDelete: (product) => _confirmDelete(context, product),
              ),
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
        final items = snapshot.data ?? const <Product>[];
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

/// قائمة/شبكة المنتجات، تتكيّف مع عرض الشاشة (Responsive).
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
    final padding = EdgeInsets.symmetric(
      horizontal: isWide ? 24 : 16,
      vertical: 8,
    );

    if (!isWide) {
      return ListView.builder(
        padding: padding,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final product = items[index];
          return _ProductCard(
            product: product,
            onEdit: () => onEdit(product),
            onDelete: () => onDelete(product),
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
            final product = items[index];
            return _ProductCard(
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool lowStock = product.quantity <= product.minimumQuantity;

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
                  color: product.isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: product.isActive
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
                            product.name,
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
                      'SKU: ${product.sku}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.sell_outlined,
                          label: product.sellingPrice.toStringAsFixed(2),
                        ),
                        _InfoChip(
                          icon: Icons.numbers,
                          label: 'الكمية: ${product.quantity}',
                          emphasize: lowStock,
                        ),
                        if (!product.isActive)
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
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

/// حالة التحميل.
class _ProductsLoadingState extends StatelessWidget {
  const _ProductsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// حالة الخطأ مع إمكانية إعادة المحاولة.
class _ProductsErrorState extends StatelessWidget {
  const _ProductsErrorState({required this.message, required this.onRetry});

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
                'حدث خطأ أثناء تحميل المنتجات',
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

/// الحالة الفارغة لقائمة المنتجات.
class _ProductsEmptyState extends StatelessWidget {
  const _ProductsEmptyState({this.isSearch = false});

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
                  isSearch ? Icons.search_off : Icons.inventory_2_outlined,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSearch ? 'لا توجد نتائج مطابقة' : 'لا توجد منتجات بعد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSearch
                    ? 'جرّب كلمة بحث مختلفة أو تحقق من الإملاء.'
                    : 'ابدأ بإضافة أول منتج لديك عبر زر الإضافة أسفل الشاشة.',
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

/// نموذج إضافة / تعديل منتج، يُعرض كـ Bottom Sheet.
class _ProductFormSheet extends ConsumerStatefulWidget {
  const _ProductFormSheet({this.product});

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
    _categoryIdController =
        TextEditingController(text: product?.categoryId ?? '');
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  String? _priceValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;
    final parsed = double.tryParse(value!.trim());
    if (parsed == null || parsed < 0) {
      return 'قيمة غير صالحة';
    }
    return null;
  }

  String? _intValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'قيمة غير صالحة';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final String name = _nameController.text.trim();
    final String sku = _skuController.text.trim();
    final String barcode = _barcodeController.text.trim();
    final double purchasePrice =
        double.parse(_purchasePriceController.text.trim());
    final double sellingPrice =
        double.parse(_sellingPriceController.text.trim());
    final int quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    final int minimumQuantity =
        int.tryParse(_minimumQuantityController.text.trim()) ?? 0;
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
        // TODO: استبدل بالمعرّف الفعلي للمستأجر بمجرد التأكد من تسجيل الدخول
        // (يُفترض أن AuthController يوفر المستخدم الحالي؛ إن كان null فهذا
        // يعني أن المستخدم غير مسجل دخول، وهي حالة يجب معالجتها لاحقاً).
        final tenantId = ref.read(authControllerProvider).user?.tenantId ?? '';

        // TODO: استبدل بمعرّف الجهاز الحقيقي عند توفر خدمة device info
        // ضمن مشروع CompFlow (غير متوفرة حالياً في الملفات المُتاحة).
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
          categoryId:
              categoryId.isEmpty ? const Value.absent() : Value(categoryId),
          isActive: Value(_isActive),
        );
        await repository.addProduct(companion);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ المنتج: $e')),
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
                    widget.isEditing ? 'تعديل منتج' : 'إضافة منتج',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'اسم المنتج'),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU'),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'الباركود (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _purchasePriceController,
                          decoration:
                              const InputDecoration(labelText: 'سعر الشراء'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _priceValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sellingPriceController,
                          decoration:
                              const InputDecoration(labelText: 'سعر البيع'),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _priceValidator,
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
                          decoration:
                              const InputDecoration(labelText: 'الكمية'),
                          keyboardType: TextInputType.number,
                          validator: _intValidator,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minimumQuantityController,
                          decoration:
                              const InputDecoration(labelText: 'الحد الأدنى'),
                          keyboardType: TextInputType.number,
                          validator: _intValidator,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // TODO: استبدل هذا الحقل النصي بقائمة منسدلة (Dropdown) تُغذّى
                  // من CategoriesRepository عند توفره؛ لا يوجد نظام فئات جاهز
                  // ضمن الملفات المتاحة حالياً.
                  TextFormField(
                    controller: _categoryIdController,
                    decoration: const InputDecoration(
                      labelText: 'معرّف الفئة (اختياري)',
                    ),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('منتج نشط'),
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
                            widget.isEditing ? 'حفظ التعديلات' : 'إضافة المنتج',
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