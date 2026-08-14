import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../auth/providers/auth_providers.dart';
import '../../customers/providers/customers_providers.dart';
import '../../products/providers/products_providers.dart';
import '../database/sale_items_dao.dart';
import '../providers/sales_providers.dart';
import '../repositories/sales_repository.dart';

const String _fallbackDeviceId = 'unknown-device';

/// صفحة المبيعات الحديثة (SaaS UI).
///
/// عرض، بحث، إنشاء، تعديل، حذف، وتفاصيل الفواتير.
class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  Future<List<Sale>>? _searchFuture;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final SalesRepository salesRepository = ref.read(salesRepositoryProvider);

    setState(() {
      _searchQuery = value.trim();
      _searchFuture = _searchQuery.isEmpty
          ? null
          : salesRepository.searchSales(_searchQuery);
    });
  }

  void _refreshSearchIfActive() {
    if (_searchQuery.isNotEmpty) {
      final SalesRepository salesRepository =
          ref.read(salesRepositoryProvider);

      setState(() {
        _searchFuture = salesRepository.searchSales(_searchQuery);
      });
    }
  }

  Future<void> _openSaleForm({Sale? sale}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaleFormSheet(sale: sale),
    );

    _refreshSearchIfActive();
  }

  Future<void> _confirmDelete(BuildContext context, Sale sale) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.salesDeleteTitle),
          content: Text(
            l10n.salesDeleteConfirm(sale.invoiceNumber),
          ),
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
      await ref.read(salesRepositoryProvider).deleteSale(sale.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.salesDeleted(sale.invoiceNumber),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      _refreshSearchIfActive();

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _showSaleDetails(
    BuildContext context,
    Sale sale,
    Map<String, String> customerNames,
    Map<String, Product> productsById,
  ) async {
    final SaleItemsDao saleItemsDao = ref.read(saleItemsDaoProvider);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SaleDetailsView(
          sale: sale,
          customerName: customerNames[sale.customerId],
          itemsFuture: saleItemsDao.getItemsBySaleId(sale.id),
          productsById: productsById,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 900;

    final customersAsync = ref.watch(customersProvider);
    final productsAsync = ref.watch(productsProvider);

    final Map<String, String> customerNames = customersAsync.maybeWhen(
      data: (customers) => {
        for (final c in customers) c.id: c.fullName,
      },
      orElse: () => const {},
    );

    final Map<String, Product> productsById = productsAsync.maybeWhen(
      data: (products) => {
        for (final p in products) p.id: p,
      },
      orElse: () => const {},
    );

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
                          l10n.salesTitle,
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
                    onPressed: () => _openSaleForm(),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.salesCreate),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // =========================
              // Search Bar
              // =========================
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: l10n.salesSearchHint,
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

              const SizedBox(height: 16),

              // =========================
              // قائمة الفواتير / المبيعات
              // =========================
              Expanded(
                child: _buildBody(
                  context,
                  isWide,
                  customerNames,
                  productsById,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isWide,
    Map<String, String> customerNames,
    Map<String, Product> productsById,
  ) {
    final SalesRepository salesRepository = ref.watch(salesRepositoryProvider);

    if (_searchQuery.isEmpty) {
      return StreamBuilder<List<Sale>>(
        stream: salesRepository.watchAllSales(),
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

          final List<Sale> items = snapshot.data ?? const <Sale>[];

          return items.isEmpty
              ? const _SalesEmptyState()
              : _SalesListView(
                  items: items,
                  isWide: isWide,
                  customerNames: customerNames,
                  onEdit: (sale) => _openSaleForm(sale: sale),
                  onDelete: (sale) => _confirmDelete(context, sale),
                  onViewDetails: (sale) => _showSaleDetails(
                    context,
                    sale,
                    customerNames,
                    productsById,
                  ),
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

        final List<Sale> items = snapshot.data ?? const <Sale>[];

        return items.isEmpty
            ? const _SalesEmptyState(isSearch: true)
            : _SalesListView(
                items: items,
                isWide: isWide,
                customerNames: customerNames,
                onEdit: (sale) => _openSaleForm(sale: sale),
                onDelete: (sale) => _confirmDelete(context, sale),
                onViewDetails: (sale) => _showSaleDetails(
                  context,
                  sale,
                  customerNames,
                  productsById,
                ),
              );
      },
    );
  }
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// شبكة / قائمة عمليات البيع
class _SalesListView extends StatelessWidget {
  const _SalesListView({
    required this.items,
    required this.isWide,
    required this.customerNames,
    required this.onEdit,
    required this.onDelete,
    required this.onViewDetails,
  });

  final List<Sale> items;
  final bool isWide;
  final Map<String, String> customerNames;
  final ValueChanged<Sale> onEdit;
  final ValueChanged<Sale> onDelete;
  final ValueChanged<Sale> onViewDetails;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final sale = items[index];

          return _SaleCard(
            sale: sale,
            customerName: customerNames[sale.customerId],
            onEdit: () => onEdit(sale),
            onDelete: () => onDelete(sale),
            onViewDetails: () => onViewDetails(sale),
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
            final sale = items[index];

            return _SaleCard(
              sale: sale,
              customerName: customerNames[sale.customerId],
              onEdit: () => onEdit(sale),
              onDelete: () => onDelete(sale),
              onViewDetails: () => onViewDetails(sale),
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
    required this.onViewDetails,
  });

  final Sale sale;
  final String? customerName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onViewDetails,
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
                      color: colorScheme.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sale.invoiceNumber,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customerName ?? l10n.salesUnknownCustomer(sale.customerId),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    onSelected: (value) {
                      if (value == 'details') onViewDetails();
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'details',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.salesInvoiceDetails),
                          ],
                        ),
                      ),
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
                children: [
                  Text(
                    '${sale.total.toStringAsFixed(2)} ${l10n.currencyDzd}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _InfoChip(
                    icon: Icons.event_outlined,
                    label: _formatDate(sale.saleDate),
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

/// تفاصيل فاتورة المبيعات (Sale Details Sheet)
class _SaleDetailsView extends StatelessWidget {
  const _SaleDetailsView({
    required this.sale,
    required this.customerName,
    required this.itemsFuture,
    required this.productsById,
  });

  final Sale sale;
  final String? customerName;
  final Future<List<SaleItem>> itemsFuture;
  final Map<String, Product> productsById;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.salesInvoiceDetails,
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

                const SizedBox(height: 12),

                // بطاقة ترويسة الفاتورة والعميل
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.receipt_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sale.invoiceNumber,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customerName ?? l10n.salesUnknownCustomer(sale.customerId),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              l10n.salesDate(_formatDate(sale.saleDate)),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  l10n.salesProducts,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // عناصر الفاتورة
                FutureBuilder<List<SaleItem>>(
                  future: itemsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text(
                        l10n.salesLoadItemsError(snapshot.error.toString()),
                        style: TextStyle(color: colorScheme.error),
                      );
                    }

                    final List<SaleItem> items = snapshot.data ?? const <SaleItem>[];

                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.salesNoItems,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final product = productsById[item.productId];

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product?.name ?? item.productId,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l10n.salesQuantity(item.quantity)} ${item.unitPrice.toStringAsFixed(2)} ${l10n.currencyDzd}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${item.total.toStringAsFixed(2)} ${l10n.currencyDzd}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // إجمالي الفاتورة
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.salesTotal,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${sale.total.toStringAsFixed(2)} ${l10n.currencyDzd}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),

                if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.salesNotes,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      sale.notes!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ],
            ),
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
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesLoadingState extends StatelessWidget {
  const _SalesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _SalesErrorState extends StatelessWidget {
  const _SalesErrorState({
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
              l10n.salesLoadError,
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

class _SalesEmptyState extends StatelessWidget {
  const _SalesEmptyState({
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
                isSearch ? Icons.search_off_rounded : Icons.receipt_long_outlined,
                size: 44,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? l10n.salesNoResults : l10n.salesEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearch ? l10n.salesSearchEmptyHint : l10n.salesEmptyHint,
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

class _SaleLineItem {
  _SaleLineItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  int quantity;

  double get subtotal => product.sellingPrice * quantity;
}

/// نموذج إنشاء / تعديل عملية البيع (Sale Form Sheet)
class _SaleFormSheet extends ConsumerStatefulWidget {
  const _SaleFormSheet({this.sale});

  final Sale? sale;

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
      text: sale?.invoiceNumber ??
          'INV-${DateTime.now().millisecondsSinceEpoch}',
    );

    _notesController = TextEditingController(
      text: sale?.notes ?? '',
    );

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

  double get _computedTotal => _lineItems.fold<double>(
        0,
        (sum, item) => sum + item.subtotal,
      );

  String? _requiredValidator(BuildContext context, String? value) {
    final l10n = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l10n.commonRequiredField;
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
    final l10n = AppLocalizations.of(context);
    final productId = _pendingProductId;

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.salesChooseProduct),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final product = products.firstWhere((p) => p.id == productId);

    if (_pendingQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.salesQuantityPositive),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final existingIndex = _lineItems.indexWhere((i) => i.product.id == productId);
    final int alreadyRequested = existingIndex >= 0 ? _lineItems[existingIndex].quantity : 0;
    final int requested = alreadyRequested + _pendingQuantity;

    if (requested > product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.salesQuantityExceeded(
              requested,
              product.name,
              product.quantity,
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex >= 0) {
        _lineItems[existingIndex].quantity += _pendingQuantity;
      } else {
        _lineItems.add(
          _SaleLineItem(
            product: product,
            quantity: _pendingQuantity,
          ),
        );
      }

      _pendingProductId = null;
      _pendingQuantity = 1;
      _pendingQuantityController.text = '1';
    });
  }

  void _removeLineItem(_SaleLineItem item) {
    setState(() {
      _lineItems.remove(item);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    if (!widget.isEditing && _selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.salesChooseCustomer),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!widget.isEditing && _lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.salesAddItem),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final String invoiceNumber = _invoiceNumberController.text.trim();
    final String customNotes = _notesController.text.trim();
    final DateTime now = DateTime.now();

    try {
      if (widget.isEditing) {
        final double? manualTotal = double.tryParse(_manualTotalController.text.trim());

        if (manualTotal == null || manualTotal < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.salesInvalidTotal),
              behavior: SnackBarBehavior.floating,
            ),
          );

          setState(() => _isSaving = false);
          return;
        }

        final Sale updated = widget.sale!.copyWith(
          invoiceNumber: invoiceNumber,
          total: manualTotal,
          saleDate: _saleDate,
          notes: Value(customNotes.isEmpty ? null : customNotes),
          updatedAt: now,
          version: widget.sale!.version + 1,
        );

        await ref.read(salesRepositoryProvider).updateSale(updated);
      } else {
        final currentUser = ref.read(authControllerProvider).user;
        final String? tenantId = currentUser?.tenantId;

        if (tenantId == null || tenantId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.salesLoginRequired),
              behavior: SnackBarBehavior.floating,
            ),
          );

          setState(() => _isSaving = false);
          return;
        }

        final String saleId = const Uuid().v4();

        final Sale newSale = Sale(
          id: saleId,
          tenantId: tenantId,
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
          version: 1,
          syncStatus: 'pending',
          deviceId: _fallbackDeviceId,
          customerId: _selectedCustomerId!,
          invoiceNumber: invoiceNumber,
          total: _computedTotal,
          saleDate: _saleDate,
          notes: customNotes.isEmpty ? null : customNotes,
        );

        final List<SaleItemsCompanion> itemCompanions = [
          for (final item in _lineItems)
            SaleItemsCompanion.insert(
              id: const Uuid().v4(),
              tenantId: tenantId,
              createdAt: now,
              updatedAt: now,
              deviceId: _fallbackDeviceId,
              saleId: saleId,
              productId: item.product.id,
              quantity: item.quantity,
              unitPrice: item.product.sellingPrice,
              total: item.subtotal,
            ),
        ];

        await ref.read(salesRepositoryProvider).completeSale(
              sale: newSale,
              items: itemCompanions,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.salesSaveFailed(e.toString())),
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

    final customersAsync = ref.watch(customersProvider);
    final productsAsync = ref.watch(productsProvider);

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
            maxWidth: isWide ? 640 : double.infinity,
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
                        widget.isEditing ? l10n.salesEdit : l10n.salesCreate,
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

                  // اختيار العميل (يظهر فقط عند إنشاء فاتورة جديدة)
                  if (!widget.isEditing) ...[
                    customersAsync.when(
                      data: (customers) => DropdownButtonFormField<String>(
                        initialValue: customers.any((c) => c.id == _selectedCustomerId)
                            ? _selectedCustomerId
                            : null,
                        decoration: InputDecoration(
                          labelText: l10n.salesCustomer,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        items: [
                          for (final c in customers)
                            DropdownMenuItem(
                              value: c.id,
                              child: Text(c.fullName),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomerId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? l10n.salesChooseCustomer : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text(
                        l10n.salesLoadCustomersError(e.toString()),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceNumberController,
                          decoration: InputDecoration(
                            labelText: l10n.salesInvoiceNumber,
                            prefixIcon: const Icon(Icons.receipt_outlined),
                          ),
                          validator: (value) => _requiredValidator(context, value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: l10n.salesDateLabel,
                              suffixIcon: const Icon(Icons.calendar_today_outlined),
                            ),
                            child: Text(_formatDate(_saleDate)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (!widget.isEditing) ...[
                    Text(
                      l10n.salesProducts,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

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
                                  decoration: InputDecoration(
                                    labelText: l10n.salesChooseProduct,
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
                                  onChanged: (value) {
                                    setState(() {
                                      _pendingProductId = value;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _pendingQuantityController,
                                  decoration: InputDecoration(
                                    labelText: l10n.productsQuantityLabel,
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
                              icon: const Icon(Icons.add_rounded),
                              label: Text(l10n.salesAddToInvoice),
                            ),
                          ),
                        ],
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (e, s) => Text(
                        l10n.salesLoadProductsError(e.toString()),
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_lineItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          l10n.salesNoProductsAdded,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _lineItems.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final item = _lineItems[index];

                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colorScheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${l10n.salesQuantity(item.quantity)} ${item.product.sellingPrice.toStringAsFixed(2)} ${l10n.currencyDzd}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.subtotal.toStringAsFixed(2)} ${l10n.currencyDzd}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: Icon(Icons.close_rounded, size: 18, color: colorScheme.error),
                                  onPressed: () => _removeLineItem(item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.salesTotal,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_computedTotal.toStringAsFixed(2)} ${l10n.currencyDzd}',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _manualTotalController,
                      decoration: InputDecoration(
                        labelText: l10n.salesTotal,
                        prefixIcon: const Icon(Icons.payments_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final parsed = double.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 0) {
                          return l10n.salesInvalidValue;
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: l10n.salesNotesOptional,
                      prefixIcon: const Icon(Icons.note_alt_outlined),
                    ),
                    maxLines: 2,
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
                                  : l10n.salesCreateAction,
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