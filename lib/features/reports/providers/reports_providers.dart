import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/database/app_database.dart';
import '../../expenses/providers/expenses_providers.dart';
import '../../products/providers/products_providers.dart';
import '../../purchases/providers/purchases_providers.dart';
import '../../sales/providers/sales_providers.dart';

enum ReportPeriodOption { today, thisWeek, thisMonth, thisYear, custom }

final reportPeriodProvider =
    StateProvider<ReportPeriodOption>((ref) => ReportPeriodOption.today);

final customReportRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final _allSalesStreamProvider = StreamProvider<List<Sale>>((ref) {
  return ref.watch(salesRepositoryProvider).watchAllSales();
});

final _allPurchasesStreamProvider = StreamProvider<List<Purchase>>((ref) {
  return ref.watch(purchasesRepositoryProvider).watchAllPurchases();
});

final _allExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesRepositoryProvider).watchAllExpenses();
});

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
    required this.sales,
    required this.dailySales,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalSales;
  final double totalPurchases;
  final double totalExpenses;
  final double approxCostOfGoodsSold;
  final double netProfitApprox;
  final int salesCount;
  final int purchasesCount;
  final List<Sale> sales;
  final Map<DateTime, double> dailySales;

  double get averageSale => salesCount == 0 ? 0 : totalSales / salesCount;

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
      final DateTime start = today.subtract(Duration(days: today.weekday - 1));
      return (start, start.add(const Duration(days: 7)));
    case ReportPeriodOption.thisMonth:
      final DateTime start = DateTime(now.year, now.month, 1);
      final DateTime end = now.month == 12
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 1, 1);
      return (start, end);
    case ReportPeriodOption.thisYear:
      return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
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

final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final customRange = ref.watch(customReportRangeProvider);
  final (start, end) = _resolveRange(period, customRange);

  final sales = await ref.watch(_allSalesStreamProvider.future);
  final purchases = await ref.watch(_allPurchasesStreamProvider.future);
  final expenses = await ref.watch(_allExpensesStreamProvider.future);
  final products = await ref.watch(productsProvider.future);

  final filteredSales = sales.where((s) => _inRange(s.saleDate, start, end)).toList()
    ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
  final filteredPurchases = purchases
      .where((p) => _inRange(p.purchaseDate, start, end))
      .toList();
  final filteredExpenses = expenses
      .where((e) => _inRange(e.expenseDate, start, end))
      .toList();

  final totalSales = filteredSales.fold<double>(0, (sum, s) => sum + s.total);
  final totalPurchases =
      filteredPurchases.fold<double>(0, (sum, p) => sum + p.total);
  final totalExpenses =
      filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  final productsById = {for (final p in products) p.id: p};
  final saleItemsDao = ref.watch(saleItemsDaoProvider);
  double approxCogs = 0;
  for (final sale in filteredSales) {
    final items = await saleItemsDao.getItemsBySaleId(sale.id);
    for (final item in items) {
      final product = productsById[item.productId];
      if (product != null) approxCogs += product.purchasePrice * item.quantity;
    }
  }

  final dailySales = <DateTime, double>{};
  for (final sale in filteredSales) {
    final day = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
    dailySales[day] = (dailySales[day] ?? 0) + sale.total;
  }

  return ReportData(
    rangeStart: start,
    rangeEnd: end,
    totalSales: totalSales,
    totalPurchases: totalPurchases,
    totalExpenses: totalExpenses,
    approxCostOfGoodsSold: approxCogs,
    netProfitApprox: totalSales - approxCogs - totalExpenses,
    salesCount: filteredSales.length,
    purchasesCount: filteredPurchases.length,
    sales: filteredSales,
    dailySales: dailySales,
  );
});
