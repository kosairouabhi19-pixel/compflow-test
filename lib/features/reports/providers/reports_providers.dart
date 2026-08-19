import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../products/providers/products_providers.dart';
import '../../sales/providers/sales_providers.dart';

enum ReportPeriodOption { today, thisWeek, thisMonth, thisYear, custom }

final reportPeriodProvider = StateProvider<ReportPeriodOption>((ref) => ReportPeriodOption.today);
final customReportRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final _allSalesStreamProvider = StreamProvider<List<Sale>>((ref) {
  return ref.watch(salesRepositoryProvider).watchAllSales();
});

class ReportProduct {
  const ReportProduct({required this.name, required this.quantity, required this.salesTotal});
  final String name;
  final int quantity;
  final double salesTotal;
}

class ReportData {
  const ReportData({
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalSales,
    required this.salesCount,
    required this.totalItemsSold,
    required this.sales,
    required this.dailySales,
    required this.topProducts,
  });

  final DateTime rangeStart;
  final DateTime rangeEnd;
  final double totalSales;
  final int salesCount;
  final int totalItemsSold;
  final List<Sale> sales;
  final Map<DateTime, double> dailySales;
  final List<ReportProduct> topProducts;

  double get averageSale => salesCount == 0 ? 0 : totalSales / salesCount;
  bool get isEmpty => salesCount == 0;
}

bool _inRange(DateTime date, DateTime start, DateTime end) =>
    !date.isBefore(start) && date.isBefore(end);

(DateTime, DateTime) _resolveRange(ReportPeriodOption period, DateTimeRange? customRange) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  switch (period) {
    case ReportPeriodOption.today:
      return (today, today.add(const Duration(days: 1)));
    case ReportPeriodOption.thisWeek:
      final start = today.subtract(Duration(days: today.weekday - 1));
      return (start, start.add(const Duration(days: 7)));
    case ReportPeriodOption.thisMonth:
      final start = DateTime(now.year, now.month, 1);
      final end = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
      return (start, end);
    case ReportPeriodOption.thisYear:
      return (DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
    case ReportPeriodOption.custom:
      if (customRange == null) return (today, today.add(const Duration(days: 1)));
      final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
      final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day).add(const Duration(days: 1));
      return (start, end);
  }
}

final reportDataProvider = FutureProvider<ReportData>((ref) async {
  final period = ref.watch(reportPeriodProvider);
  final customRange = ref.watch(customReportRangeProvider);
  final (start, end) = _resolveRange(period, customRange);

  final sales = await ref.watch(_allSalesStreamProvider.future);
  final products = await ref.watch(productsProvider.future);
  final filteredSales = sales.where((s) => _inRange(s.saleDate, start, end)).toList()
    ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

  final totalSales = filteredSales.fold<double>(0, (sum, s) => sum + s.total);
  final dailySales = <DateTime, double>{};
  for (final sale in filteredSales) {
    final day = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
    dailySales[day] = (dailySales[day] ?? 0) + sale.total;
  }

  final productsById = {for (final product in products) product.id: product};
  final saleItemsDao = ref.watch(saleItemsDaoProvider);
  final quantityByProduct = <String, int>{};
  final totalByProduct = <String, double>{};
  var totalItemsSold = 0;

  for (final sale in filteredSales) {
    final items = await saleItemsDao.getItemsBySaleId(sale.id);
    for (final item in items) {
      totalItemsSold += item.quantity;
      quantityByProduct[item.productId] = (quantityByProduct[item.productId] ?? 0) + item.quantity;
      totalByProduct[item.productId] = (totalByProduct[item.productId] ?? 0) + item.total;
    }
  }

  final topProducts = quantityByProduct.keys.map((id) {
    final product = productsById[id];
    return ReportProduct(
      name: product?.name ?? id,
      quantity: quantityByProduct[id] ?? 0,
      salesTotal: totalByProduct[id] ?? 0,
    );
  }).toList()
    ..sort((a, b) => b.quantity.compareTo(a.quantity));

  return ReportData(
    rangeStart: start,
    rangeEnd: end,
    totalSales: totalSales,
    salesCount: filteredSales.length,
    totalItemsSold: totalItemsSold,
    sales: filteredSales,
    dailySales: dailySales,
    topProducts: topProducts.take(10).toList(),
  );
});
