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
    final wide = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          reportAsync.maybeWhen(
            data: (report) => IconButton(
              tooltip: 'طباعة التقرير',
              icon: const Icon(Icons.print_outlined),
              onPressed: report.isEmpty
                  ? null
                  : () => _printReport(context, report),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
                    : _ReportsContent(report: report, wide: wide),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.report, required this.wide});

  final ReportData report;
  final bool wide;

  String _money(double value) => '${value.toStringAsFixed(2)} دج';

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastDay = report.rangeEnd.subtract(const Duration(days: 1));
    final range = _date(report.rangeStart) == _date(lastDay)
        ? _date(report.rangeStart)
        : '${_date(report.rangeStart)} → ${_date(lastDay)}';

    final metrics = [
      _Metric('المبيعات', _money(report.totalSales), Icons.point_of_sale_outlined),
      _Metric('عدد الفواتير', '${report.salesCount}', Icons.receipt_long_outlined),
      _Metric('متوسط الفاتورة', _money(report.averageSale), Icons.shopping_cart_outlined),
      _Metric('صافي الربح التقريبي', _money(report.netProfitApprox), Icons.trending_up_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('التقرير: $range', style: theme.textTheme.titleMedium),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: wide ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 112,
                ),
                itemCount: metrics.length,
                itemBuilder: (_, index) => _MetricCard(metric: metrics[index]),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.insights_outlined),
                          const SizedBox(width: 8),
                          Text('اتجاه المبيعات', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          Text('حسب اليوم', style: theme.textTheme.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(height: 230, child: _SalesChart(data: report.dailySales)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.table_chart_outlined),
                          const SizedBox(width: 8),
                          Text('الفواتير', style: theme.textTheme.titleMedium),
                          const Spacer(),
                          FilledButton.tonalIcon(
                            onPressed: () => _printReport(context, report),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('طباعة التقرير'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SalesTable(sales: report.sales, money: _money, date: _date),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('ملخص مالي', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 10),
                      _SummaryRow('المبيعات', _money(report.totalSales)),
                      _SummaryRow('تكلفة البضاعة التقريبية', _money(report.approxCostOfGoodsSold)),
                      _SummaryRow('المصروفات', _money(report.totalExpenses)),
                      const Divider(),
                      _SummaryRow('صافي الربح التقريبي', _money(report.netProfitApprox), bold: true),
                      const SizedBox(height: 8),
                      Text(
                        'ملاحظة: الربح تقريبي لأن تكلفة الشراء التاريخية للمنتج وقت البيع غير محفوظة كقيمة مستقلة.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
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
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        );
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
    final rows = sales.take(50).toList();
    if (rows.isEmpty) return const Text('لا توجد فواتير في الفترة المحددة.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('رقم الفاتورة')),
          DataColumn(label: Text('التاريخ')),
          DataColumn(label: Text('الإجمالي')),
        ],
        rows: [
          for (final sale in rows)
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
    if (data.isEmpty) return const Center(child: Text('لا توجد بيانات كافية للرسم البياني.'));
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final visible = entries.length > 31 ? entries.sublist(entries.length - 31) : entries;
    final maxValue = visible.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _SalesChartPainter(
            entries: visible,
            maxValue: maxValue == 0 ? 1 : maxValue,
            textStyle: Theme.of(context).textTheme.bodySmall!,
            primary: Theme.of(context).colorScheme.primary,
            grid: Theme.of(context).colorScheme.outlineVariant,
          ),
        );
      },
    );
  }
}

class _SalesChartPainter extends CustomPainter {
  const _SalesChartPainter({
    required this.entries,
    required this.maxValue,
    required this.textStyle,
    required this.primary,
    required this.grid,
  });

  final List<MapEntry<DateTime, double>> entries;
  final double maxValue;
  final TextStyle textStyle;
  final Color primary;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 48.0;
    const bottom = 28.0;
    final chartWidth = size.width - left - 8;
    final chartHeight = size.height - bottom - 8;
    final gridPaint = Paint()..color = grid.withValues(alpha: .35);
    final barPaint = Paint()..color = primary;

    for (var i = 0; i <= 4; i++) {
      final y = 8 + chartHeight - (chartHeight * i / 4);
      canvas.drawLine(Offset(left, y), Offset(size.width - 8, y), gridPaint);
    }

    final slot = chartWidth / entries.length;
    final barWidth = (slot * .62).clamp(3.0, 28.0);
    for (var i = 0; i < entries.length; i++) {
      final value = entries[i].value;
      final height = chartHeight * value / maxValue;
      final x = left + i * slot + (slot - barWidth) / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 8 + chartHeight - height, barWidth, height),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);

      if (entries.length <= 14 || i % ((entries.length / 7).ceil()) == 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${entries[i].key.day}/${entries[i].key.month}', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: slot);
        tp.paint(canvas, Offset(left + i * slot + (slot - tp.width) / 2, size.height - 22));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SalesChartPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.maxValue != maxValue;
}

Future<void> _printReport(BuildContext context, ReportData report) async {
  final document = pw.Document();
  final lastDay = report.rangeEnd.subtract(const Duration(days: 1));
  String date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String money(double v) => '${v.toStringAsFixed(2)} DZD';

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => [
        pw.Text('CompFlow - Sales Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text('Period: ${date(report.rangeStart)} - ${date(lastDay)}'),
        pw.SizedBox(height: 18),
        pw.Table.fromTextArray(
          headers: ['Invoice', 'Date', 'Total'],
          data: [
            for (final sale in report.sales)
              [sale.invoiceNumber, date(sale.saleDate), money(sale.total)],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
        pw.SizedBox(height: 18),
        pw.Text('Summary', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Total sales: ${money(report.totalSales)}'),
        pw.Text('Invoices: ${report.salesCount}'),
        pw.Text('Average invoice: ${money(report.averageSale)}'),
        pw.Text('Approx. net profit: ${money(report.netProfitApprox)}'),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (_) async => document.save());
}
