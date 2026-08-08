import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../auth/providers/auth_providers.dart';
import '../../customers/providers/customers_providers.dart';
import '../../products/providers/products_providers.dart';
import '../database/sales_dao.dart';
import '../repositories/sales_repository.dart';

/// صفحة المبيعات الكاملة: عرض، بحث، إنشاء، تعديل، حذف.
///
/// ملاحظة مهمة: لا يوجد ملف Provider مخصّص للمبيعات (لا `salesProvider` ولا
/// `salesRepositoryProvider`) في المشروع، على عكس ميزتَي المنتجات والعملاء.
/// TODO: أضف provider مخصص (مثلاً `salesRepositoryProvider` و
/// `salesProvider`) في مجلد providers خاص بالمبيعات بنفس نمط
/// `products_providers.dart` / `customers_providers.dart` لتوحيد الأسلوب.
/// بانتظار ذلك، تُبنى SalesRepository هنا محلياً اعتماداً على
/// appDatabaseProvider الموجود فعلياً (المعرّف في products_providers.dart)
/// لتفادي اختراع Provider جديد وفي نفس الوقت تفادي فتح اتصال قاعدة بيانات
/// إضافي منفصل.
class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  late final SalesRepository _salesRepository;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Future<List<Sale>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    final database = ref.read(appDatabaseProvider);
    _salesRepository = SalesRepository(SalesDao(database));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
      _searchFuture =
          _searchQuery.isEmpty ? null : _salesRepository.searchSales(_searchQuery);
    });
  }

  void _refreshSearchIfActive() {
    if (_searchQuery.isNotEmpty) {
      setState(() {
        _searchFuture = _salesRepository.searchSales(_searchQuery);
      });
    }
  }

  Future<void> _openSaleForm({Sale? sale}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _SaleFormSheet(
        sale: sale,
        salesRepository: _salesRepository,
      ),
    );
    _refreshSearchIfActive();
  }

  Future<void> _confirmDelete(BuildContext context, Sale sale) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف عملية البيع'),
          content: Text('هل أنت متأكد من حذف الفاتورة "${sale.invoiceNumber}"؟'),
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
      await _salesRepository.deleteSale(sale.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف الفاتورة "${sale.invoiceNumber}"')),
        );
      }
      _refreshSearchIfActive();
      setState(() {}); // لتحديث Stream المعروض عند عدم وجود بحث نشط
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 600;
    final customersAsync = ref.watch(customersProvider);
    final Map<String, String> customerNames = customersAsync.maybeWhen(
      data: (customers) => {
        for (final c in customers) c.id: c.fullName,
      },
      orElse: () => const {},
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('المبيعات'),
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
                  hintText: 'ابحث برقم الفاتورة أو الملاحظات...',
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
            Expanded(child: _buildBody(context, isWide, customerNames)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openSaleForm(),
        tooltip: 'إنشاء عملية بيع',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isWide,
    Map<String, String> customerNames,
  ) {
    if (_searchQuery.isEmpty) {
      return StreamBuilder<List<Sale>>(
        stream: _salesRepository.watchAllSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SalesLoadingState();
          }
          if (snapshot.hasError) {
            return _SalesErrorState(
              message: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }
          final items = snapshot.data ?? const <Sale>[];
          return items.isEmpty
              ? const _SalesEmptyState()
              : _SalesListView(
                  items: items,
                  isWide: isWide,
                  customerNames: customerNames,
                  onEdit: (sale) => _openSaleForm(sale: sale),
                  onDelete: (sale) => _confirmDelete(context, sale),
                );
        },
      );
    }

    return FutureBuilder<List<Sale>>(
      future: _searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SalesLoadingState();
        }
        if (snapshot.hasError) {
          return _SalesErrorState(
            message: snapshot.error.toString(),
            onRetry: () => _onSearchChanged(_searchQuery),
          );
        }
        final items = snapshot.data ?? const <Sale>[];
        return items.isEmpty
            ? const _SalesEmptyState(isSearch: true)
            : _SalesListView(
                items: items,
                isWide: isWide,
                customerNames: customerNames,
                onEdit: (sale) => _openSaleForm(sale: sale),
                onDelete: (sale) => _confirmDelete(context, sale),
              );
      },
    );
  }
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// قائمة/شبكة عمليات البيع، تتكيّف مع عرض الشاشة (Responsive).
class _SalesListView extends StatelessWidget {
  const _SalesListView({
    required this.items,
    required this.isWide,
    required this.customerNames,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Sale> items;
  final bool isWide;
  final Map<String, String> customerNames;
  final ValueChanged<Sale> onEdit;
  final ValueChanged<Sale> onDelete;

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
          final sale = items[index];
          return _SaleCard(
            sale: sale,
            customerName: customerNames[sale.customerId],
            onEdit: () => onEdit(sale),
            onDelete: () => onDelete(sale),
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
            final sale = items[index];
            return _SaleCard(
              sale: sale,
              customerName: customerNames[sale.customerId],
              onEdit: () => onEdit(sale),
              onDelete: () => onDelete(sale),
            );
          },
        );
      },
    );
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.sale,
    required this.customerName,
    required this.onEdit,
    required this.onDelete,
  });

  final Sale sale;
  final String? customerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showSaleDetails(context, sale),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
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
                            sale.invoiceNumber,
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
                      customerName ?? 'عميل غير معروف (${sale.customerId})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.payments_outlined,
                          label: sale.total.toStringAsFixed(2),
                        ),
                        _InfoChip(
                          icon: Icons.event_outlined,
                          label: _formatDate(sale.saleDate),
                        ),
                      ],
                    ),
                    if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        sale.notes!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة التحميل.
class _SalesLoadingState extends StatelessWidget {
  const _SalesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// حالة الخطأ مع إمكانية إعادة المحاولة.
class _SalesErrorState extends StatelessWidget {
  const _SalesErrorState({required this.message, required this.onRetry});

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
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'حدث خطأ أثناء تحميل عمليات البيع',
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

/// الحالة الفارغة لقائمة المبيعات.
class _SalesEmptyState extends StatelessWidget {
  const _SalesEmptyState({this.isSearch = false});

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
                  isSearch ? Icons.search_off : Icons.point_of_sale_outlined,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isSearch ? 'لا توجد نتائج مطابقة' : 'لا توجد عمليات بيع بعد',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isSearch
                    ? 'جرّب كلمة بحث مختلفة أو تحقق من الإملاء.'
                    : 'ابدأ بإنشاء أول عملية بيع عبر زر الإضافة أسفل الشاشة.',
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

/// عنصر سطر داخل نموذج إنشاء عملية البيع (منتج + كمية).
///
/// كائن مساعد للواجهة فقط، وليس نموذج بيانات في قاعدة البيانات — لا يوجد
/// جدول لعناصر الفاتورة (sale items) في المخطط الحالي.
class _SaleLineItem {
  _SaleLineItem({required this.product, required this.quantity});

  final Product product;
  int quantity;

  double get subtotal => product.sellingPrice * quantity;
}

/// نموذج إنشاء / تعديل عملية بيع، يُعرض كـ Bottom Sheet.
class _SaleFormSheet extends ConsumerStatefulWidget {
  const _SaleFormSheet({this.sale, required this.salesRepository});

  final Sale? sale;
  final SalesRepository salesRepository;

  bool get isEditing => sale != null;

  @override
  ConsumerState<_SaleFormSheet> createState() => _SaleFormSheetState();
}

class _SaleFormSheetState extends ConsumerState<_SaleFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _notesController;
  late final TextEditingController _manualTotalController;
  String? _selectedCustomerId;
  late DateTime _saleDate;

  // اختيار المنتج الجاري إضافته (وضع الإنشاء فقط).
  String? _pendingProductId;
  int _pendingQuantity = 1;
  final TextEditingController _pendingQuantityController =
      TextEditingController(text: '1');
  final List<_SaleLineItem> _lineItems = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final sale = widget.sale;
    _invoiceNumberController = TextEditingController(
      text: sale?.invoiceNumber ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
    );
    _notesController = TextEditingController(text: sale?.notes ?? '');
    _manualTotalController = TextEditingController(
      text: sale != null ? sale.total.toStringAsFixed(2) : '',
    );
    _selectedCustomerId = sale?.customerId;
    _saleDate = sale?.saleDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    _notesController.dispose();
    _manualTotalController.dispose();
    _pendingQuantityController.dispose();
    super.dispose();
  }

  double get _computedTotal =>
      _lineItems.fold<double>(0, (sum, item) => sum + item.subtotal);

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'هذا الحقل مطلوب';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _saleDate = picked);
    }
  }

  void _addLineItem(List<Product> products) {
    final productId = _pendingProductId;
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر منتجاً أولاً')),
      );
      return;
    }
    final product = products.firstWhere((p) => p.id == productId);

    if (_pendingQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الكمية يجب أن تكون أكبر من صفر')),
      );
      return;
    }

    final existingIndex = _lineItems.indexWhere((i) => i.product.id == productId);
    final int alreadyRequested =
        existingIndex >= 0 ? _lineItems[existingIndex].quantity : 0;

    if (alreadyRequested + _pendingQuantity > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الكمية المطلوبة (${alreadyRequested + _pendingQuantity}) تتجاوز '
            'الكمية المتاحة من "${product.name}" (${product.quantity}).',
          ),
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex >= 0) {
        _lineItems[existingIndex].quantity += _pendingQuantity;
      } else {
        _lineItems.add(
          _SaleLineItem(product: product, quantity: _pendingQuantity),
        );
      }
      _pendingProductId = null;
      _pendingQuantity = 1;
      _pendingQuantityController.text = '1';
    });
  }

  void _removeLineItem(_SaleLineItem item) {
    setState(() => _lineItems.remove(item));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العميل')),
      );
      return;
    }

    if (!widget.isEditing && _lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف منتجاً واحداً على الأقل')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String invoiceNumber = _invoiceNumberController.text.trim();
    final String customNotes = _notesController.text.trim();
    final now = DateTime.now();

    try {
      if (widget.isEditing) {
        final double? manualTotal =
            double.tryParse(_manualTotalController.text.trim());
        if (manualTotal == null || manualTotal < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('قيمة الإجمالي غير صالحة')),
          );
          setState(() => _isSaving = false);
          return;
        }

        final updated = widget.sale!.copyWith(
          customerId: _selectedCustomerId!,
          invoiceNumber: invoiceNumber,
          total: manualTotal,
          saleDate: _saleDate,
          notes: Value(customNotes.isEmpty ? null : customNotes),
          updatedAt: now,
          version: widget.sale!.version + 1,
        );
        await widget.salesRepository.updateSale(updated);
      } else {
        // TODO: استبدل بالمعرّف الفعلي للمستأجر بمجرد التأكد من تسجيل الدخول
        // (يُفترض أن AuthController يوفر المستخدم الحالي؛ إن كان null فهذا
        // يعني أن المستخدم غير مسجل دخول، وهي حالة يجب معالجتها لاحقاً).
        final tenantId = ref.read(authControllerProvider).user?.tenantId ?? '';

        // TODO: استبدل بمعرّف الجهاز الحقيقي عند توفر خدمة device info
        // ضمن مشروع CompFlow (غير متوفرة حالياً في الملفات المُتاحة).
        const deviceId = 'unknown-device';

        // TODO: لا يوجد جدول لعناصر الفاتورة (sale items) في المخطط الحالي،
        // لذا يتم تخزين ملخص المنتجات نصياً ضمن حقل notes كحل عملي مؤقت.
        // الحل الصحيح لاحقاً هو إضافة جدول SaleItems مرتبط بـ Sales.
        final String itemsSummary = _lineItems
            .map((i) => '${i.product.name} x${i.quantity}')
            .join('، ');
        final String finalNotes = [
          if (itemsSummary.isNotEmpty) 'المنتجات: $itemsSummary',
          if (customNotes.isNotEmpty) customNotes,
        ].join(' | ');

        final companion = SalesCompanion.insert(
          id: const Uuid().v4(),
          tenantId: tenantId,
          createdAt: now,
          updatedAt: now,
          deviceId: deviceId,
          customerId: _selectedCustomerId!,
          invoiceNumber: invoiceNumber,
          total: _computedTotal,
          saleDate: _saleDate,
          notes: finalNotes.isEmpty ? const Value.absent() : Value(finalNotes),
        );
        await widget.salesRepository.insertSale(companion);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ عملية البيع: $e')),
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
    final theme = Theme.of(context);

    final customersAsync = ref.watch(customersProvider);
    final productsAsync = ref.watch(productsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: mediaQuery.viewInsets.bottom + 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 640 : double.infinity),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isEditing ? 'تعديل عملية بيع' : 'إنشاء عملية بيع',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // اختيار العميل
                  customersAsync.when(
                    data: (customers) => DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: const InputDecoration(labelText: 'العميل'),
                      items: [
                        for (final c in customers)
                          DropdownMenuItem(value: c.id, child: Text(c.fullName)),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedCustomerId = value),
                      validator: (value) =>
                          value == null ? 'يرجى اختيار العميل' : null,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('تعذر تحميل العملاء: $e'),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _invoiceNumberController,
                    decoration: const InputDecoration(labelText: 'رقم الفاتورة'),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'تاريخ البيع',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(_formatDate(_saleDate)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!widget.isEditing) ...[
                    Text('المنتجات', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    productsAsync.when(
                      data: (products) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _pendingProductId,
                                  decoration: const InputDecoration(
                                    labelText: 'اختر منتجاً',
                                  ),
                                  items: [
                                    for (final p in products)
                                      DropdownMenuItem(
                                        value: p.id,
                                        child: Text(
                                          '${p.name} (${p.quantity})',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                  onChanged: (value) =>
                                      setState(() => _pendingProductId = value),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _pendingQuantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'الكمية',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    _pendingQuantity =
                                        int.tryParse(value.trim()) ?? 1;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: FilledButton.tonalIcon(
                              onPressed: () => _addLineItem(products),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة للفاتورة'),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text('تعذر تحميل المنتجات: $e'),
                    ),
                    const SizedBox(height: 12),

                    if (_lineItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'لم تتم إضافة منتجات بعد.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ...[
                        for (final item in _lineItems)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(item.product.name),
                              subtitle: Text(
                                'الكمية: ${item.quantity} × '
                                '${item.product.sellingPrice.toStringAsFixed(2)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item.subtotal.toStringAsFixed(2)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _removeLineItem(item),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الإجمالي',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          Text(
                            _computedTotal.toStringAsFixed(2),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // TODO: لا يمكن إعادة بناء قائمة المنتجات الأصلية لعملية
                    // بيع محفوظة مسبقاً لعدم وجود جدول لعناصر الفاتورة، لذا
                    // يُعدَّل الإجمالي يدوياً هنا حتى إضافة هذا الجدول لاحقاً.
                    TextFormField(
                      controller: _manualTotalController,
                      decoration: const InputDecoration(labelText: 'الإجمالي'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 0) {
                          return 'قيمة غير صالحة';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                    ),
                    maxLines: 3,
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
                            widget.isEditing
                                ? 'حفظ التعديلات'
                                : 'إنشاء عملية البيع',
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