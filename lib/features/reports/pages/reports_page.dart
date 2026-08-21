import 'dart:math' as math;
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
    if (picked == null) return;
    ref.read(customReportRangeProvider.notifier).state = picked;
    ref.read(reportPeriodProvider.notifier).state = ReportPeriodOption.custom;
  }

  String _periodLabel(AppLocalizations l10n, String language, ReportPeriodOption option) {
    return switch (option) {
      ReportPeriodOption.today => l10n.reportsToday,
      ReportPeriodOption.thisWeek => l10n.reportsWeek,
      ReportPeriodOption.thisMonth => l10n.reportsMonth,
      ReportPeriodOption.thisYear => language == 'en' ? 'Year' : language == 'fr' ? 'Année' : 'سنوي',
      ReportPeriodOption.custom => l10n.reportsCustom,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final selected = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(reportDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: SafeArea(
        child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: FilledButton.tonalIcon(
              onPressed: () => ref.invalidate(reportDataProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ),
          data: (report) {
            if (report.isEmpty) return Center(child: Text(l10n.reportsEmpty));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final option in ReportPeriodOption.values) ...[
                                ChoiceChip(
                                  label: Text(_periodLabel(l10n, language, option)),
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
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        onPressed: () => _showPrintPreview(context, report),
                        icon: const Icon(Icons.print_outlined),
                        label: Text(language == 'en' ? 'Preview & print' : language == 'fr' ? 'Aperçu et impression' : 'معاينة وطباعة'),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _ReportsContent(report: report, language: language)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.report, required this.language});
  final ReportData report;
  final String language;

  String _money(double value) => '${value.toStringAsFixed(0)} DZD';
  String _dateTime(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';
  String _tr(String ar, String en, String fr) => language == 'en' ? en : language == 'fr' ? fr : ar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final end = report.rangeEnd.subtract(const Duration(seconds: 1));
    final metrics = [
      _Metric(_tr('إجمالي المبيعات', 'Total sales', 'Ventes totales'), _money(report.totalSales), Icons.payments_outlined),
      _Metric(_tr('عدد الفواتير', 'Invoices', 'Factures'), '${report.salesCount}', Icons.receipt_long_outlined),
      _Metric(_tr('متوسط الفاتورة', 'Average invoice', 'Panier moyen'), _money(report.averageSale), Icons.shopping_cart_outlined),
      _Metric(_tr('القطع المباعة', 'Items sold', 'Articles vendus'), '${report.totalItemsSold}', Icons.inventory_2_outlined),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_tr('تحليل المبيعات', 'Sales analysis', 'Analyse des ventes'), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${_tr('الفترة', 'Period', 'Période')}: ${_dateTime(report.rangeStart)} - ${_dateTime(end)}', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 2 : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: metrics.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 112),
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
                      Text(_tr('اتجاه المبيعات', 'Sales trend', 'Évolution des ventes'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(_tr('حركة المبيعات خلال الفترة المحددة', 'Sales movement for the selected period', 'Évolution des ventes sur la période sélectionnée'), style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 18),
                      SizedBox(height: 280, child: _SalesChart(data: report.dailySales, emptyText: _tr('لا توجد بيانات كافية.', 'Not enough data.', 'Données insuffisantes.'))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final invoices = _InvoicesCard(sales: report.sales, money: _money, dateTime: _dateTime, language: language);
                  final products = _TopProductsCard(products: report.topProducts, money: _money, language: language);
                  if (constraints.maxWidth < 850) return Column(children: [invoices, const SizedBox(height: 18), products]);
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: invoices), const SizedBox(width: 18), Expanded(flex: 2, child: products)]);
                },
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
        child: Row(children: [
          CircleAvatar(backgroundColor: colors.primaryContainer, child: Icon(metric.icon, color: colors.onPrimaryContainer)),
          const SizedBox(width: 14),
          Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(metric.value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(metric.label, maxLines: 1, overflow: TextOverflow.ellipsis)])),
        ]),
      ),
    );
  }
}

class _InvoicesCard extends StatelessWidget {
  const _InvoicesCard({required this.sales, required this.money, required this.dateTime, required this.language});
  final List<dynamic> sales;
  final String Function(double) money;
  final String Function(DateTime) dateTime;
  final String language;

  String _tr(String ar, String en, String fr) => language == 'en' ? en : language == 'fr' ? fr : ar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_tr('الفواتير', 'Invoices', 'Factures'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(_tr('الفاتورة', 'Invoice', 'Facture'))),
                DataColumn(label: Text(_tr('التاريخ والوقت', 'Date & time', 'Date et heure'))),
                DataColumn(label: Text(_tr('الإجمالي', 'Total', 'Total'))),
              ],
              rows: [
                for (final sale in sales.take(500))
                  DataRow(cells: [
                    DataCell(Text(sale.invoiceNumber.toString())),
                    DataCell(Text(dateTime(sale.saleDate as DateTime))),
                    DataCell(Text(money((sale.total as num).toDouble()))),
                  ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products, required this.money, required this.language});
  final List<ReportProduct> products;
  final String Function(double) money;
  final String language;

  String _tr(String ar, String en, String fr) => language == 'en' ? en : language == 'fr' ? fr : ar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(_tr('الأكثر مبيعًا', 'Top products', 'Meilleurs produits'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_tr('مرتبة حسب عدد القطع المباعة', 'Ranked by units sold', 'Classés par quantité vendue')),
          const SizedBox(height: 12),
          if (products.isEmpty) Text(_tr('لا توجد بيانات كافية.', 'Not enough data.', 'Données insuffisantes.')),
          for (var i = 0; i < products.length; i++)
            ListTile(dense: true, leading: CircleAvatar(radius: 16, child: Text('${i + 1}')), title: Text(products[i].name, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${products[i].quantity} ${_tr('قطعة', 'units', 'unités')}'), trailing: Text(money(products[i].salesTotal))),
        ]),
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  const _SalesChart({required this.data, required this.emptyText});
  final Map<DateTime, double> data;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return Center(child: Text(emptyText));
    final entries = data.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return LayoutBuilder(
      builder: (context, constraints) => CustomPaint(
        size: Size(constraints.maxWidth, constraints.maxHeight),
        painter: _ReportChartPainter(entries: entries, primary: Theme.of(context).colorScheme.primary, grid: Theme.of(context).colorScheme.outlineVariant, textStyle: Theme.of(context).textTheme.bodySmall!),
      ),
    );
  }
}

class _ReportChartPainter extends CustomPainter {
  const _ReportChartPainter({required this.entries, required this.primary, required this.grid, required this.textStyle});
  final List<MapEntry<DateTime, double>> entries;
  final Color primary;
  final Color grid;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 58.0;
    const right = 18.0;
    const top = 16.0;
    const bottom = 40.0;
    final width = math.max(1.0, size.width - left - right);
    final height = math.max(1.0, size.height - top - bottom);
    final maxValue = entries.fold<double>(0, (m, e) => math.max(m, e.value));
    final safeMax = maxValue <= 0 ? 1 : maxValue * 1.15;
    final gridPaint = Paint()..color = grid.withValues(alpha: .45)..strokeWidth = 1;
    final linePaint = Paint()..color = primary..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = primary;
    final areaPaint = Paint()..color = primary.withValues(alpha: .10);
    for (var i = 0; i <= 4; i++) {
      final y = top + height - height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
    }
    final points = <Offset>[];
    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final x = entries.length == 1 ? left + width / 2 : left + width * i / (entries.length - 1);
      final y = top + height - height * entries[i].value / safeMax;
      final point = Offset(x, y);
      points.add(point);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final area = Path.from(path)..lineTo(points.last.dx, top + height)..lineTo(points.first.dx, top + height)..close();
    canvas.drawPath(area, areaPaint);
    canvas.drawPath(path, linePaint);
    final step = entries.length <= 8 ? 1 : (entries.length / 7).ceil();
    for (var i = 0; i < entries.length; i += step) {
      final point = points[i];
      canvas.drawCircle(point, 4.5, pointPaint);
      final label = '${entries[i].key.day}/${entries[i].key.month}';
      final tp = TextPainter(text: TextSpan(text: label, style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(point.dx - tp.width / 2, size.height - 24));
    }
  }

  @override
  bool shouldRepaint(covariant _ReportChartPainter oldDelegate) => oldDelegate.entries != entries || oldDelegate.primary != primary;
}

Future<void> _showPrintPreview(BuildContext context, ReportData report) async {
  final language = Localizations.localeOf(context).languageCode;
  final bytes = await _buildReportPdf(report, language);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(width: 1000, height: 760, child: PdfPreview(build: (_) async => bytes, canChangePageFormat: true, canChangeOrientation: true, allowPrinting: true, allowSharing: true, pdfFileName: 'compflow-sales-report.pdf')),
    ),
  );
}

Future<Uint8List> _buildReportPdf(ReportData report, String language) async {
  final arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
  final arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();
  final latinFont = await PdfGoogleFonts.notoSansRegular();
  final latinBoldFont = await PdfGoogleFonts.notoSansBold();
  final document = pw.Document(theme: pw.ThemeData.withFont(base: latinFont, bold: latinBoldFont, fontFallback: [arabicFont, arabicBoldFont]));
  final direction = language == 'ar' ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  final end = report.rangeEnd.subtract(const Duration(seconds: 1));
  String date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  String money(double v) => '${v.toStringAsFixed(0)} DZD';
  String tr(String ar, String en, String fr) => language == 'en' ? en : language == 'fr' ? fr : ar;
  pw.Widget text(String value, {bool bold = false, double? size}) => pw.Text(value, style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, fontFallback: [arabicFont, arabicBoldFont]));
  pw.Widget cell(String value, {bool bold = false}) => pw.Padding(padding: const pw.EdgeInsets.all(6), child: text(value, bold: bold));

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => [
        pw.Directionality(
          textDirection: direction,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              text('CompFlow - ${tr('تقرير المبيعات', 'Sales report', 'Rapport des ventes')}', bold: true, size: 22),
              pw.SizedBox(height: 6),
              text('${tr('الفترة', 'Period', 'Période')}: ${date(report.rangeStart)} - ${date(end)}'),
              pw.SizedBox(height: 18),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(children: [cell(tr('إجمالي المبيعات', 'Total sales', 'Ventes totales'), bold: true), cell(money(report.totalSales))]),
                  pw.TableRow(children: [cell(tr('عدد الفواتير', 'Invoices', 'Factures'), bold: true), cell('${report.salesCount}')]),
                  pw.TableRow(children: [cell(tr('متوسط الفاتورة', 'Average invoice', 'Panier moyen'), bold: true), cell(money(report.averageSale))]),
                  pw.TableRow(children: [cell(tr('القطع المباعة', 'Items sold', 'Articles vendus'), bold: true), cell('${report.totalItemsSold}')]),
                ],
              ),
              pw.SizedBox(height: 20),
              text(tr('الفواتير', 'Invoices', 'Factures'), bold: true, size: 16),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {0: const pw.FlexColumnWidth(1.5), 1: const pw.FlexColumnWidth(2.5), 2: const pw.FlexColumnWidth(1.5)},
                children: [
                  pw.TableRow(children: [cell(tr('رقم الفاتورة', 'Invoice', 'Facture'), bold: true), cell(tr('التاريخ والوقت', 'Date & time', 'Date et heure'), bold: true), cell(tr('الإجمالي', 'Total', 'Total'), bold: true)]),
                  for (final sale in report.sales.take(500))
                    pw.TableRow(children: [cell(sale.invoiceNumber.toString()), cell(date(sale.saleDate as DateTime)), cell(money((sale.total as num).toDouble()))]),
                ],
              ),
              pw.SizedBox(height: 20),
              text(tr('الأكثر مبيعًا', 'Top products', 'Meilleurs produits'), bold: true, size: 16),
              pw.SizedBox(height: 8),
              for (var i = 0; i < report.topProducts.length; i++)
                pw.Padding(padding: const pw.EdgeInsets.only(bottom: 5), child: text('${i + 1}. ${report.topProducts[i].name} — ${report.topProducts[i].quantity} ${tr('قطعة', 'units', 'unités')} — ${money(report.topProducts[i].salesTotal)}')),
            ],
          ),
        ),
      ],
    ),
  );
  return document.save();
}
