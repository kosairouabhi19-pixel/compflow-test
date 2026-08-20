import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
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

  String _periodLabel(BuildContext context, AppLocalizations l10n, ReportPeriodOption option) {
    final language = Localizations.localeOf(context).languageCode;
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
    final previewLabel = language == 'en' ? 'Print preview' : language == 'fr' ? 'Aperçu avant impression' : 'معاينة الطباعة';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          reportAsync.maybeWhen(
            data: (report) => report.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16),
                    child: FilledButton.tonalIcon(
                      onPressed: () => _showPrintPreview(context, report),
                      icon: const Icon(Icons.preview_outlined),
                      label: Text(previewLabel),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
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
                        label: Text(_periodLabel(context, l10n, option)),
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
                data: (report) => report.isEmpty ? Center(child: Text(l10n.reportsEmpty)) : _ReportsContent(report: report),
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

  String _money(double value) => '${value.toStringAsFixed(0)} DZD';

  String _dateTime(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:${value.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final end = report.rangeEnd.subtract(const Duration(seconds: 1));
    final startText = '${report.rangeStart.day.toString().padLeft(2, '0')}/${report.rangeStart.month.toString().padLeft(2, '0')}/${report.rangeStart.year}';
    final endText = '${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}/${end.year}';
    final range = startText == endText ? startText : '$startText → $endText';

    final metrics = [
      _Metric(language == 'en' ? 'Total sales' : language == 'fr' ? 'Ventes totales' : 'إجمالي المبيعات', _money(report.totalSales), Icons.payments_outlined),
      _Metric(language == 'en' ? 'Invoices' : language == 'fr' ? 'Factures' : 'عدد الفواتير', '${report.salesCount}', Icons.receipt_long_outlined),
      _Metric(language == 'en' ? 'Average invoice' : language == 'fr' ? 'Panier moyen' : 'متوسط الفاتورة', _money(report.averageSale), Icons.shopping_cart_outlined),
      _Metric(language == 'en' ? 'Items sold' : language == 'fr' ? 'Articles vendus' : 'القطع المباعة', '${report.totalItemsSold}', Icons.inventory_2_outlined),
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
                        Text(language == 'en' ? 'Sales analysis' : language == 'fr' ? 'Analyse des ventes' : 'تحليل المبيعات', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${language == 'en' ? 'Period' : language == 'fr' ? 'Période' : 'الفترة'}: $range', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _showPrintPreview(context, report),
                    icon: const Icon(Icons.print_outlined),
                    label: Text(language == 'en' ? 'Preview & print' : language == 'fr' ? 'Aperçu et impression' : 'معاينة وطباعة'),
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: 118),
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
                      Text(language == 'en' ? 'Sales trend' : language == 'fr' ? 'Évolution des ventes' : 'اتجاه المبيعات', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(language == 'en' ? 'Sales movement for the selected period.' : language == 'fr' ? 'Évolution des ventes sur la période sélectionnée.' : 'حركة المبيعات للفترة المحددة.', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                      const SizedBox(height: 18),
                      SizedBox(height: 280, child: _SalesChart(data: report.dailySales)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stacked = constraints.maxWidth < 850;
                  final invoices = _InvoicesCard(sales: report.sales, money: _money, dateTime: _dateTime, language: language);
                  final products = _TopProductsCard(products: report.topProducts, money: _money, language: language);
                  return stacked ? Column(children: [invoices, const SizedBox(height: 18), products]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: invoices), const SizedBox(width: 18), Expanded(flex: 2, child: products)]);
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
  final List<Sale> sales;
  final String Function(double) money;
  final String Function(DateTime) dateTime;
  final String language;

  @override
  Widget build(BuildContext context) {
    final invoice = language == 'en' ? 'Invoice' : language == 'fr' ? 'Facture' : 'الفاتورة';
    final date = language == 'en' ? 'Date & time' : language == 'fr' ? 'Date et heure' : 'التاريخ والوقت';
    final total = language == 'en' ? 'Total' : language == 'fr' ? 'Total' : 'الإجمالي';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(language == 'en' ? 'Invoices' : language == 'fr' ? 'Factures' : 'الفواتير', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [DataColumn(label: Text(invoice)), DataColumn(label: Text(date)), DataColumn(label: Text(total))],
              rows: [for (final sale in sales.take(500)) DataRow(cells: [DataCell(Text(sale.invoiceNumber)), DataCell(Text(dateTime(sale.saleDate))), DataCell(Text(money(sale.total)))])],
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(language == 'en' ? 'Top products' : language == 'fr' ? 'Meilleurs produits' : 'الأكثر مبيعًا', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(language == 'en' ? 'Ranked by units sold' : language == 'fr' ? 'Classés par quantité vendue' : 'مرتبة حسب عدد القطع المباعة'),
          const SizedBox(height: 12),
          if (products.isEmpty) Text(language == 'en' ? 'Not enough data.' : language == 'fr' ? 'Données insuffisantes.' : 'لا توجد بيانات كافية.'),
          for (var i = 0; i < products.length; i++)
            ListTile(dense: true, leading: CircleAvatar(radius: 16, child: Text('${i + 1}')), title: Text(products[i].name, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: Text('${products[i].quantity} ${language == 'en' ? 'units' : language == 'fr' ? 'unités' : 'قطعة'}'), trailing: Text(money(products[i].salesTotal))),
        ]),
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
    const left = 58.0, right = 18.0, top = 16.0, bottom = 40.0;
    final width = math.max(1, size.width - left - right);
    final height = math.max(1, size.height - top - bottom);
    final maxValue = entries.fold<double>(0, (m, e) => math.max(m, e.value));
    final safeMax = maxValue <= 0 ? 1 : maxValue * 1.15;
    final gridPaint = Paint()..color = grid.withOpacity(.45)..strokeWidth = 1;
    final linePaint = Paint()..color = primary..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = primary;
    final areaPaint = Paint()..color = primary.withOpacity(.10);

    for (var i = 0; i <= 4; i++) {
      final y = top + height - height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
    }

    final points = <Offset>[];
    final path = Path();
    for (var i = 0; i < entries.length; i++) {
      final x = entries.length == 1 ? left + width / 2 : left + width * i / (entries.length - 1);
      final y = top + height - height * entries[i].value / safeMax;
      points.add(Offset(x, y));
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
    if (entries.length > 1 && (entries.length - 1) % step != 0) {
      final i = entries.length - 1;
      final point = points[i];
      canvas.drawCircle(point, 4.5, pointPaint);
      final label = '${entries[i].key.day}/${entries[i].key.month}';
      final tp = TextPainter(text: TextSpan(text: label, style: textStyle), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(point.dx - tp.width / 2, size.height - 24));
    }
  }

  @override
  bool shouldRepaint(covariant _ReportChartPainter oldDelegate) => oldDelegate.entries != entries;
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
  final theme = pw.ThemeData.withFont(
    base: latinFont,
    bold: latinBoldFont,
    fontFallback: [arabicFont, arabicBoldFont],
  );
  final document = pw.Document(theme: theme);
  final end = report.rangeEnd.subtract(const Duration(seconds: 1));
  String date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  String money(double v) => '${v.toStringAsFixed(0)} DZD';
  final l = _ReportPdfLabels(language);
  final rtl = language == 'ar';
  final textDirection = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;

  pw.Widget labelText(String text, {bool bold = false, double? fontSize, pw.TextDirection? direction}) {
    return pw.Text(
      text,
      textDirection: direction ?? textDirection,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontFallback: [arabicFont, arabicBoldFont],
      ),
    );
  }

  pw.Widget ltrText(String text, {bool bold = false}) => labelText(text, bold: bold, direction: pw.TextDirection.ltr);
  pw.Widget rtlText(String text, {bool bold = false}) => labelText(text, bold: bold, direction: pw.TextDirection.rtl);

  pw.Widget periodWidget() {
    if (!rtl) return labelText('${l.period}: ${date(report.rangeStart)} - ${date(end)}');
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      textDirection: pw.TextDirection.rtl,
      children: [
        rtlText(l.period),
        pw.SizedBox(width: 5),
        ltrText('${date(report.rangeStart)} - ${date(end)}'),
      ],
    );
  }

  pw.Widget moneyCell(String value) => pw.Padding(padding: const pw.EdgeInsets.all(7), child: ltrText(value));
  pw.Widget textCell(String value, {bool bold = false, bool rtlValue = false}) => pw.Padding(
        padding: const pw.EdgeInsets.all(7),
        child: rtlValue ? rtlText(value, bold: bold) : ltrText(value, bold: bold),
      );

  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      textDirection: textDirection,
      build: (_) => [
        labelText('CompFlow - ${l.report}', bold: true, fontSize: 22),
        pw.SizedBox(height: 6),
        periodWidget(),
        pw.SizedBox(height: 18),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(children: [
              textCell(l.totalSales, bold: true, rtlValue: rtl),
              textCell(l.invoices, bold: true, rtlValue: rtl),
              textCell(l.average, bold: true, rtlValue: rtl),
              textCell(l.items, bold: true, rtlValue: rtl),
            ]),
            pw.TableRow(children: [
              moneyCell(money(report.totalSales)),
              textCell('${report.salesCount}'),
              moneyCell(money(report.averageSale)),
              textCell('${report.totalItemsSold}'),
            ]),
          ],
        ),
        pw.SizedBox(height: 22),
        labelText(l.invoices, bold: true, fontSize: 16),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [l.invoice, l.dateTime, l.total],
          data: [
            for (final sale in report.sales.take(1000)) [
              ltrText(sale.invoiceNumber),
              ltrText(date(sale.saleDate)),
              ltrText(money(sale.total)),
            ],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontFallback: [arabicFont, arabicBoldFont]),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
        pw.SizedBox(height: 18),
        labelText(l.topProducts, bold: true, fontSize: 16),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: [l.product, l.qty, l.sales],
          data: [
            for (final product in report.topProducts) [
              rtl ? rtlText(product.name) : ltrText(product.name),
              ltrText('${product.quantity}'),
              ltrText(money(product.salesTotal)),
            ],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontFallback: [arabicFont, arabicBoldFont]),
          cellPadding: const pw.EdgeInsets.all(6),
        ),
      ],
    ),
  );
  return document.save();
}

class _ReportPdfLabels {
  _ReportPdfLabels(String language)
      : report = language == 'en' ? 'Sales Report' : language == 'fr' ? 'Rapport des ventes' : 'تقرير المبيعات',
        period = language == 'en' ? 'Period' : language == 'fr' ? 'Période' : 'الفترة',
        totalSales = language == 'en' ? 'Total sales' : language == 'fr' ? 'Ventes totales' : 'إجمالي المبيعات',
        invoices = language == 'en' ? 'Invoices' : language == 'fr' ? 'Factures' : 'الفواتير',
        average = language == 'en' ? 'Average invoice' : language == 'fr' ? 'Panier moyen' : 'متوسط الفاتورة',
        items = language == 'en' ? 'Items sold' : language == 'fr' ? 'Articles vendus' : 'القطع المباعة',
        invoice = language == 'en' ? 'Invoice' : language == 'fr' ? 'Facture' : 'الفاتورة',
        dateTime = language == 'en' ? 'Date & time' : language == 'fr' ? 'Date et heure' : 'التاريخ والوقت',
        total = language == 'en' ? 'Total' : language == 'fr' ? 'Total' : 'الإجمالي',
        topProducts = language == 'en' ? 'Top products' : language == 'fr' ? 'Meilleurs produits' : 'الأكثر مبيعًا',
        product = language == 'en' ? 'Product' : language == 'fr' ? 'Produit' : 'المنتج',
        qty = language == 'en' ? 'Qty' : language == 'fr' ? 'Qté' : 'الكمية',
        sales = language == 'en' ? 'Sales' : language == 'fr' ? 'Ventes' : 'المبيعات';

  final String report;
  final String period;
  final String totalSales;
  final String invoices;
  final String average;
  final String items;
  final String invoice;
  final String dateTime;
  final String total;
  final String topProducts;
  final String product;
  final String qty;
  final String sales;
}
