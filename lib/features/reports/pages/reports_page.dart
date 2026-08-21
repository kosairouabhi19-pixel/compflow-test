import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../sales/database/sales_dao.dart';

class ReportData {
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalSales;
  final int invoicesCount;
  final int itemsSold;
  final List<Sale> sales;

  const ReportData({
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalSales,
    required this.invoicesCount,
    required this.itemsSold,
    required this.sales,
  });
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // Existing page implementation remains unchanged.
}

class _ReportPdfLabels {
  final String language;
  _ReportPdfLabels(this.language);

  String get title => language == 'ar' ? 'التقرير' : language == 'fr' ? 'Rapport' : 'Report';
  String get period => language == 'ar' ? 'الفترة' : language == 'fr' ? 'Période' : 'Period';
  String get invoiceNumber => language == 'ar' ? 'رقم الفاتورة' : language == 'fr' ? 'N° facture' : 'Invoice No.';
  String get date => language == 'ar' ? 'التاريخ' : language == 'fr' ? 'Date' : 'Date';
  String get total => language == 'ar' ? 'الإجمالي' : language == 'fr' ? 'Total' : 'Total';
  String get salesAnalysis => language == 'ar' ? 'تحليل المبيعات' : language == 'fr' ? 'Analyse des ventes' : 'Sales Analysis';
}

Future<Uint8List> buildReportPdf({
  required String language,
  required ReportData report,
}) async {
  final latinFont = pw.Font.helvetica();
  final latinBoldFont = pw.Font.helveticaBold();
  final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'));
  final arabicBoldFont = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansArabic-Bold.ttf'));

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
    final child = pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontFallback: [arabicFont, arabicBoldFont],
      ),
    );
    return pw.Directionality(textDirection: direction ?? textDirection, child: child);
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
      build: (context) => [
        labelText(l.title, bold: true, fontSize: 20),
        pw.SizedBox(height: 10),
        periodWidget(),
        pw.SizedBox(height: 15),
        pw.Row(
          children: [
            pw.Expanded(child: textCell(l.invoiceNumber, bold: true, rtlValue: rtl)),
            pw.Expanded(child: textCell(l.date, bold: true, rtlValue: rtl)),
            pw.Expanded(child: textCell(l.total, bold: true, rtlValue: rtl)),
          ],
        ),
        ...report.sales.map(
          (sale) => pw.Row(
            children: [
              pw.Expanded(child: moneyCell(sale.invoiceNumber.toString())),
              pw.Expanded(child: moneyCell(date(sale.createdAt))),
              pw.Expanded(child: moneyCell(money(sale.totalAmount))),
            ],
          ),
        ),
        pw.SizedBox(height: 15),
        labelText('${l.total}: ${money(report.totalSales)}', bold: true),
      ],
    ),
  );

  return document.save();
}
