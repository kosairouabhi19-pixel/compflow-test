import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/reports_providers.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final current = ref.read(customReportRangeProvider);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: current,
    );
    if (picked != null) {
      ref.read(customReportRangeProvider.notifier).state = picked;
      ref.read(reportPeriodProvider.notifier).state = ReportPeriodOption.custom;
    }
  }

  String _periodLabel(AppLocalizations l10n, ReportPeriodOption option) {
    switch (option) {
      case ReportPeriodOption.today:
        return l10n.reportsToday;
      case ReportPeriodOption.thisWeek:
        return l10n.reportsWeek;
      case ReportPeriodOption.thisMonth:
        return l10n.reportsMonth;
      case ReportPeriodOption.thisYear:
        return 'سنوي';
      case ReportPeriodOption.custom:
        return l10n.reportsCustom;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(reportDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          reportAsync.maybeWhen(
            data: (report) => report.isEmpty
                ? const SizedBox.shrink()
                : FilledButton.tonalIcon(
                    onPressed: () => _showPrintPreview(context, report),
                    icon: const Icon(Icons.preview_outlined),
                    label: const Text('معاينة الطباعة'),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in ReportPeriodOption.values)
                      ChoiceChip(
                        label: Text(_periodLabel(l10n, option)),
                        selected: selected == option,
                        onSelected: (value) {
                          if (!value) return;
                          if (option == ReportPeriodOption.custom) {
                            _pickCustomRange(context, ref);
                          } else {
                            ref.read(reportPeriodProvider.notifier).state = option;
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: FilledButton.tonalIcon(
                    onPressed: () => ref.invalidate(reportDataProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.commonRetry),
                  ),
                ),
                data: (report) => report.isEmpty
                    ? Center(child: Text(l10n.reportsEmpty))
                    : _ReportsContent(report: report),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.report});

  final ReportData report;

  String _money(double value) => '${value.toStringAsFixed(0)} دج';

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final end = report.rangeEnd.subtract(const Duration(days: 1));
    final range = _date(report.rangeStart) == _date(end)
        ? _date(report.rangeStart)
        : '${_date(report.rangeStart)} → ${_date(end)}';

    final metrics = [
      _Metric('إجمالي المبيعات', _money(report.totalSales), Icons.payments_outlined),
      _Metric('عدد الفواتير', '${report.salesCount}', Icons.receipt_long_outlined),
      _Metric('متوسط الفاتورة', _money(report.averageSale), Icons.shopping_cart_outlined),
      _Metric('الربح التقريبي', _money(report.netProfitApprox), Icons.trending_up_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تحليل المبيعات', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('الفترة: $range', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showPrintPreview(context, report),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('معاينة وطباعة'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 118,
                    ),
                    itemBuilder: (_, index) => _MetricCard(metric: metrics[index]),
                  );
                },
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('حركة المبيعات', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('قيمة المبيعات حسب اليوم داخل الفترة المحددة', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 18),
                      SizedBox(height: 260, child: _SalesChart(data: report.dailySales)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('الفواتير', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            _SalesTable(sales: report.sales, money: _money, date: _date),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('الملخص المالي', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            _SummaryRow('المبيعات', _money(report.totalSales)),
                            _SummaryRow('تكلفة البضاعة', _money(report.approxCostOfGoodsSold)),
                            _SummaryRow('المصروفات', _money(report.totalExpenses)),
                            const Divider(height: 24),
                            _SummaryRow('الربح التقريبي', _money(report.netProfitApprox), bold: true),
                            const SizedBox(height: 12),
                            Text(
                              'الربح تقريبي لأن تكلفة الشراء التاريخية وقت البيع غير محفوظة كقيمة مستقلة.',
                              style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
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

class _Metric {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Icon(metric.icon, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(metric.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: bold ? FontWeight.w800 : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

class _SalesTable extends StatelessWidget {
  const _SalesTable({required this.sales, required this.money, required this.date});
  final List<Sale> sales;
  final String Function(double) money;
  final String Function(DateTime) date;

  @override
  Widget build(BuildContext context) {
    if (sales.isEmpty) return const Text('لا توجد فواتير في الفترة المحددة.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('الفاتورة')),
          DataColumn(label: Text('التاريخ')),
          DataColumn(label: Text('الإجمالي')),
        ],
        rows: [
          for (final sale in sales.take(200))
            DataRow(cells: [
              DataCell(Text(sale.invoiceNumber)),
              DataCell(Text(date(sale.saleDate))),
              DataCell(Text(money(sale.total))),
            ]),
        ],
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.data});
  final Map<DateTime, double> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('لا توجد بيانات كافية.'));
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final visible = entries.length > 31 ? entries.sublist(entries.length - 31) : entries;
    final maxValue = visible.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _SalesChartPainter(
          entries: visible,
          maxValue: maxValue == 0 ? 1 : maxValue,
          primary: Theme.of(context).colorScheme.primary,
          grid: Theme.of(context).colorScheme.outlineVariant,
          textStyle: Theme.of(context).textTheme.bodySmall!,
        ),
      ),
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter({required this.entries, required this.maxValue, required this.primary, required this.grid, required this.textStyle});
  final List<MapEntry<DateTime, double>> entries;
  final double maxValue;
  final Color primary;
  final Color grid;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 52.0;
    const right = 12.0;
    const top = 12.0;
    const bottom = 34.0;
    final width = size.width - left - right;
    final height = size.height - top - bottom;
    final gridPaint = Paint()..color = grid.withValues(alpha: .35);
    final barPaint = Paint()..color = primary;

    for (var i = 0; i <= 4; i++) {
      final y = top + height - height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
    }

    final slot = width / entries.length;
    final barWidth = (slot * .62).clamp(4.0, 28.0);
    for (var i = 0; i < entries.length; i++) {
      final valueHeight = height * entries[i].value / maxValue;
      final x = left + i * slot + (slot - barWidth) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, top + height - valueHeight, barWidth, valueHeight), const Radius.circular(5)),
        barPaint,
      );
      if (entries.length <= 14 || i % ((entries.length / 7).ceil()) == 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${entries[i].key.day}/${entries[i].key.month}', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: slot);
        tp.paint(canvas, Offset(left + i * slot + (slot - tp.width) / 2, size.height - 24));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) => oldDelegate.entries != entries || oldDelegate.maxValue != maxValue;
}

Future<void> _showPrintPreview(BuildContext context, ReportData report) async {
  final bytes = await _buildReportPdf(report);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1000,
        height: 760,
        child: PdfPreview(
          build: (_) async => bytes,
          canChangePageFormat: true,
          canChangeOrientation: true,
          allowPrinting: true,
          allowSharing: true,
          pdfFileName: 'compflow-sales-report.pdf',
        ),
      ),
    ),
  );
}

Future<Uint8List> _buildReportPdf(ReportData report) async {
  final document = pw.Document();
  final end = report.rangeEnd.subtract(const Duration(days: 1));
  String date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String money(double v) => '${v.toStringAsFixed(0)} DZD';

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Text('CompFlow - Sales Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('Period: ${date(report.rangeStart)} - ${date(end)}'),
        pw.SizedBox(height: 18),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(children: [
              _pdfCell('Total sales', bold: true),
              _pdfCell('Invoices', bold: true),
              _pdfCell('Average invoice', bold: true),
              _pdfCell('Approx. profit', bold: true),
            ]),
            pw.TableRow(children: [
              _pdfCell(money(report.totalSales)),
              _pdfCell('${report.salesCount}'),
              _pdfCell(money(report.averageSale)),
              _pdfCell(money(report.netProfitApprox)),
            ]),
          ],
        ),
        pw.SizedBox(height: 22),
        pw.Text('Invoices', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: const ['Invoice', 'Date', 'Total'],
          data: [
            for (final sale in report.sales.take(1000))
              [sale.invoiceNumber, date(sale.saleDate), money(sale.total)],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
        pw.SizedBox(height: 18),
        pw.Text('Financial summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Sales: ${money(report.totalSales)}'),
        pw.Text('Approx. cost of goods: ${money(report.approxCostOfGoodsSold)}'),
        pw.Text('Expenses: ${money(report.totalExpenses)}'),
        pw.Text('Approx. net profit: ${money(report.netProfitApprox)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
  return document.save();
}

pw.Widget _pdfCell(String text, {bool bold = false}) => pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
