import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../products/providers/products_providers.dart';
import '../../purchases/providers/purchases_providers.dart';
import '../../sales/providers/sales_providers.dart';

/// خيارات فترة التقرير المدعومة في نسخة الـ MVP.
enum ReportPeriodOption { today, thisWeek, thisMonth, custom }

/// الفترة الزمنية المختارة حالياً لعرض التقرير. الافتراضي: اليوم.
final reportPeriodProvider =
    StateProvider<ReportPeriodOption>((ref) => ReportPeriodOption.today);

/// الفترة المخصّصة (تُستخدم فقط عندما تكون [reportPeriodProvider] تساوي
/// [ReportPeriodOption.custom]).
final customReportRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

/// بث مباشر لكل عمليات البيع، ليعاد بناء التقرير تلقائياً عند أي تغيير.
final _allSalesStreamProvider = StreamProvider<List<Sale>>((ref) {
  return ref.watch(salesRepositoryProvider).watchAllSales();
});

/// بث مباشر لكل عمليات الشراء.
final _allPurchasesStreamProvider = StreamProvider<List<Purchase>>((ref) {
  return ref.watch(purchasesRepositoryProvider).watchAllPurchases();
});

/// بث مباشر لكل المصروفات.
final _allExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesRepositoryProvider).watchAllExpenses();
});

/// بيانات التقرير المُجمّعة لفترة زمنية محددة.
class ReportData {
  const ReportData({
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalSales,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.approxCostOfGoodsSold,
    required this.netProfitApprox,
    required this.salesCount,
    required this.purchasesCount,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;

  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;

  /// تقدير تقريبي لتكلفة المبيعات، محسوب من سعر الشراء **الحالي** لكل
  /// منتج (Product.purchasePrice) مضروباً في الكمية المباعة (SaleItems).
  /// ليس دقيقاً تاريخياً لأن سعر الشراء عند وقت البيع الفعلي غير مخزَّن
  /// حالياً في جدول SaleItems.
  final double approxCostOfGoodsSold;

  /// صافي الربح التقريبي = المبيعات - تكلفة المبيعات التقريبية - المصروفات.
  final double netProfitApprox;

  final int salesCount;
  final int purchasesCount;

  bool get isEmpty =>
      salesCount == 0 && purchasesCount == 0 && totalExpenses == 0;
}

bool _inRange(DateTime date, DateTime start, DateTime end) {
  return !date.isBefore(start) && date.isBefore(end);
}

(DateTime, DateTime) _resolveRange(
  ReportPeriodOption period,
  DateTimeRange? customRange,
) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  switch (period) {
    case ReportPeriodOption.today:
      return (today, today.add(const Duration(days: 1)));
    case ReportPeriodOption.thisWeek:
      final DateTime startOfWeek =
          today.subtract(Duration(days: today.weekday - 1));
      return (startOfWeek, startOfWeek.add(const Duration(days: 7)));
    case ReportPeriodOption.thisMonth:
      final DateTime startOfMonth = DateTime(now.year, now.month, 1);
      final DateTime startOfNextMonth = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      return (startOfMonth, startOfNextMonth);
    case ReportPeriodOption.custom:
      if (customRange == null) {
        return (today, today.add(const Duration(days: 1)));
      }
      final DateTime start = DateTime(
        customRange.start.year,
        customRange.start.month,
        customRange.start.day,
      );
      final DateTime end = DateTime(
        customRange.end.year,
        customRange.end.month,
        customRange.end.day,
      ).add(const Duration(days: 1));
      return (start, end);
  }
}

/// يجمّع بيانات المبيعات والمشتريات والمصروفات للفترة المختارة حالياً،
/// ويُعاد حسابه تلقائياً عند تغيّر الفترة أو عند تغيّر أي من البيانات
/// المصدرية (بفضل الاعتماد على الـ Stream providers أعلاه عبر ref.watch).
final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final ReportPeriodOption period = ref.watch(reportPeriodProvider);
  final DateTimeRange? customRange = ref.watch(customReportRangeProvider);
  final (DateTime start, DateTime end) = _resolveRange(period, customRange);

  final List<Sale> sales = await ref.watch(_allSalesStreamProvider.future);
  final List<Purchase> purchases =
      await ref.watch(_allPurchasesStreamProvider.future);
  final List<Expense> expenses =
      await ref.watch(_allExpensesStreamProvider.future);
  final List<Product> products = await ref.watch(productsProvider.future);

  final List<Sale> filteredSales =
      sales.where((s) => _inRange(s.saleDate, start, end)).toList();
  final List<Purchase> filteredPurchases = purchases
      .where((p) => _inRange(p.purchaseDate, start, end))
      .toList();
  final List<Expense> filteredExpenses = expenses
      .where((e) => _inRange(e.expenseDate, start, end))
      .toList();

  final double totalSales =
      filteredSales.fold<double>(0, (sum, s) => sum + s.total);
  final double totalPurchases =
      filteredPurchases.fold<double>(0, (sum, p) => sum + p.total);
  final double totalExpenses =
      filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  final Map<String, Product> productsById = {
    for (final p in products) p.id: p,
  };

  final saleItemsDao = ref.watch(saleItemsDaoProvider);
  double approxCogs = 0;
  for (final sale in filteredSales) {
    final items = await saleItemsDao.getItemsBySaleId(sale.id);
    for (final item in items) {
      final Product? product = productsById[item.productId];
      if (product != null) {
        approxCogs += product.purchasePrice * item.quantity;
      }
    }
  }

  final double netProfitApprox = totalSales - approxCogs - totalExpenses;

  return ReportData(
    rangeStart: start,
    rangeEnd: end,
    totalSales: totalSales,
    totalPurchases: totalPurchases,
    totalExpenses: totalExpenses,
    approxCostOfGoodsSold: approxCogs,
    netProfitApprox: netProfitApprox,
    salesCount: filteredSales.length,
    purchasesCount: filteredPurchases.length,
  );
});