import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../customers/providers/customers_providers.dart';
import '../../../products/providers/products_providers.dart';
import '../../../sales/providers/sales_providers.dart';

final _dashboardSalesStreamProvider = StreamProvider<List<Sale>>((ref) {
  return ref.watch(salesRepositoryProvider).watchAllSales();
});

class DashboardChartPoint {
  const DashboardChartPoint({
    required this.label,
    required this.sales,
  });

  final String label;
  final double sales;
}

class DashboardData {
  const DashboardData({
    required this.totalSalesToday,
    required this.salesCountToday,
    required this.averageSaleToday,
    required this.productsCount,
    required this.lowStockProducts,
    required this.recentSales,
    required this.customerNames,
    required this.dailyChart,
    required this.weeklyChart,
    required this.monthlyChart,
    required this.yearlyChart,
  });

  final double totalSalesToday;
  final int salesCountToday;
  final double averageSaleToday;
  final int productsCount;
  final List<Product> lowStockProducts;
  final List<Sale> recentSales;
  final Map<String, String> customerNames;
  final List<DashboardChartPoint> dailyChart;
  final List<DashboardChartPoint> weeklyChart;
  final List<DashboardChartPoint> monthlyChart;
  final List<DashboardChartPoint> yearlyChart;

  bool get isEmpty => salesCountToday == 0 && productsCount == 0;
}

bool _isWithin(DateTime date, DateTime start, DateTime endExclusive) {
  return !date.isBefore(start) && date.isBefore(endExclusive);
}

List<DashboardChartPoint> _buildDailyChart({
  required List<Sale> sales,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  return List.generate(7, (index) {
    final day = today.subtract(Duration(days: 6 - index));
    final nextDay = day.add(const Duration(days: 1));
    final total = sales
        .where((sale) => _isWithin(sale.saleDate, day, nextDay))
        .fold<double>(0, (sum, sale) => sum + sale.total);
    return DashboardChartPoint(
      label: '${day.day}/${day.month}',
      sales: total,
    );
  });
}

List<DashboardChartPoint> _buildWeeklyChart({
  required List<Sale> sales,
  required DateTime now,
}) {
  final currentWeekStart = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1));
  return List.generate(8, (index) {
    final weekStart = currentWeekStart.subtract(Duration(days: (7 - index) * 7));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final total = sales
        .where((sale) => _isWithin(sale.saleDate, weekStart, weekEnd))
        .fold<double>(0, (sum, sale) => sum + sale.total);
    return DashboardChartPoint(
      label: '${weekStart.day}/${weekStart.month}',
      sales: total,
    );
  });
}

List<DashboardChartPoint> _buildMonthlyChart({
  required List<Sale> sales,
  required DateTime now,
}) {
  return List.generate(12, (index) {
    final monthOffset = 11 - index;
    final firstMonth = DateTime(now.year, now.month - monthOffset);
    final nextMonth = DateTime(firstMonth.year, firstMonth.month + 1);
    final total = sales
        .where((sale) => _isWithin(sale.saleDate, firstMonth, nextMonth))
        .fold<double>(0, (sum, sale) => sum + sale.total);
    return DashboardChartPoint(
      label: '${firstMonth.month}/${firstMonth.year}',
      sales: total,
    );
  });
}

List<DashboardChartPoint> _buildYearlyChart({
  required List<Sale> sales,
  required DateTime now,
}) {
  return List.generate(5, (index) {
    final year = now.year - (4 - index);
    final yearStart = DateTime(year);
    final yearEnd = DateTime(year + 1);
    final total = sales
        .where((sale) => _isWithin(sale.saleDate, yearStart, yearEnd))
        .fold<double>(0, (sum, sale) => sum + sale.total);
    return DashboardChartPoint(label: '$year', sales: total);
  });
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final sales = await ref.watch(_dashboardSalesStreamProvider.future);
  final products = await ref.watch(productsProvider.future);
  final customers = await ref.watch(customersProvider.future);

  final salesToday = sales
      .where((sale) => _isWithin(sale.saleDate, todayStart, todayEnd))
      .toList();

  final totalSalesToday = salesToday.fold<double>(
    0,
    (sum, sale) => sum + sale.total,
  );

  final averageSaleToday = salesToday.isEmpty
      ? 0.0
      : totalSalesToday / salesToday.length;

  final lowStockProducts = products
      .where(
        (product) =>
            product.isActive &&
            product.quantity <= product.minimumQuantity,
      )
      .toList()
    ..sort((a, b) => a.quantity.compareTo(b.quantity));

  final sortedSales = [...sales]
    ..sort((a, b) => b.saleDate.compareTo(a.saleDate));

  return DashboardData(
    totalSalesToday: totalSalesToday,
    salesCountToday: salesToday.length,
    averageSaleToday: averageSaleToday,
    productsCount: products.length,
    lowStockProducts: lowStockProducts,
    recentSales: sortedSales.take(5).toList(),
    customerNames: {
      for (final customer in customers) customer.id: customer.fullName,
    },
    dailyChart: _buildDailyChart(sales: sales, now: now),
    weeklyChart: _buildWeeklyChart(sales: sales, now: now),
    monthlyChart: _buildMonthlyChart(sales: sales, now: now),
    yearlyChart: _buildYearlyChart(sales: sales, now: now),
  );
});