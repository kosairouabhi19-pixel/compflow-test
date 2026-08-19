import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/app_localizations.dart';
import '../../customers/providers/customers_providers.dart';
import '../../products/providers/products_providers.dart';
import '../database/sale_items_dao.dart';
import '../providers/sales_providers.dart';

class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});

  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final customersAsync = ref.watch(customersProvider);
    final productsAsync = ref.watch(productsProvider);
    final salesRepository = ref.watch(salesRepositoryProvider);

    final customerNames = customersAsync.maybeWhen(
      data: (customers) => {for (final c in customers) c.id: c.fullName},
      orElse: () => const <String, String>{},
    );
    final productsById = productsAsync.maybeWhen(
      data: (products) => {for (final p in products) p.id: p},
      orElse: () => const <String, Product>{},
    );

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isWide ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.salesTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'سجل المبيعات والفواتير المنفذة من نافذة البيع',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: l10n.salesSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear_rounded),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Sale>>(
                  stream: salesRepository.watchAllSales(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text(l10n.salesLoadError));
                    }

                    final sales = (snapshot.data ?? const <Sale>[]).where((sale) {
                      if (_searchQuery.isEmpty) return true;
                      return sale.invoiceNumber.toLowerCase().contains(_searchQuery) ||
                          sale.total.toString().contains(_searchQuery);
                    }).toList();

                    if (sales.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 52, color: colors.outline),
                            const SizedBox(height: 12),
                            Text(l10n.salesEmpty, style: theme.textTheme.titleMedium),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: sales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final sale = sales[index];
                        return _SaleCard(
                          sale: sale,
                          customerName: customerNames[sale.customerId],
                          onOpen: () => _showDetails(
                            context,
                            sale,
                            customerNames[sale.customerId],
                            productsById,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetails(
    BuildContext context,
    Sale sale,
    String? customerName,
    Map<String, Product> productsById,
  ) async {
    final items = await ref.read(saleItemsDaoProvider).getItemsBySaleId(sale.id);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _SaleDetailsDialog(
        sale: sale,
        customerName: customerName,
        items: items,
        productsById: productsById,
        onPrint: () => _printSale(sale, items, productsById),
      ),
    );
  }

  Future<void> _printSale(
    Sale sale,
    List<SaleItem> items,
    Map<String, Product> productsById,
  ) async {
    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text(
                  'CompFlow',
                  style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Invoice: ${sale.invoiceNumber}'),
                pw.Text('Date: ${_formatDate(sale.saleDate)}'),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: const ['SKU', 'Qty', 'Unit price', 'Total'],
                  data: [
                    for (final item in items)
                      [
                        productsById[item.productId]?.sku ?? item.productId,
                        '${item.quantity}',
                        '${item.unitPrice.toStringAsFixed(0)} DZD',
                        '${item.total.toStringAsFixed(0)} DZD',
                      ],
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text(
                    'TOTAL: ${sale.total.toStringAsFixed(0)} DZD',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }
}

class _SaleCard extends StatelessWidget {
  const _SaleCard({
    required this.sale,
    required this.customerName,
    required this.onOpen,
  });

  final Sale sale;
  final String? customerName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale.invoiceNumber,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customerName ?? 'عميل مباشر',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                '${sale.total.toStringAsFixed(0)} DZD',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.chevron_left_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleDetailsDialog extends StatelessWidget {
  const _SaleDetailsDialog({
    required this.sale,
    required this.customerName,
    required this.items,
    required this.productsById,
    required this.onPrint,
  });

  final Sale sale;
  final String? customerName;
  final List<SaleItem> items;
  final Map<String, Product> productsById;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text(sale.invoiceNumber)),
          IconButton(
            tooltip: 'طباعة',
            onPressed: onPrint,
            icon: const Icon(Icons.print_outlined),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('التاريخ: ${_formatDate(sale.saleDate)}'),
              const SizedBox(height: 4),
              Text('العميل: ${customerName ?? 'عميل مباشر'}'),
              const SizedBox(height: 20),
              ...items.map((item) {
                final product = productsById[item.productId];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product?.name ?? item.productId, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            Text('SKU: ${product?.sku ?? item.productId}'),
                            Text('الكمية: ${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} DZD'),
                          ],
                        ),
                      ),
                      Text('${item.total.toStringAsFixed(0)} DZD', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الإجمالي', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${sale.total.toStringAsFixed(0)} DZD', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
        FilledButton.icon(onPressed: onPrint, icon: const Icon(Icons.print_outlined), label: const Text('طباعة الفاتورة')),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
