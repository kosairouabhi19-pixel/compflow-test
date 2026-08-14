import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../customers/providers/customers_providers.dart';
import '../../../expenses/providers/expenses_providers.dart';
import '../../../products/providers/products_providers.dart';
import '../../../purchases/providers/purchases_providers.dart';
import '../../../sales/providers/sales_providers.dart';

final _dashboardSalesStreamProvider = StreamProvider<List<Sale>>((ref) {
  return ref.watch(salesRepositoryProvider).watchAllSales();
});

final _dashboardPurchasesStreamProvider = StreamProvider<List<Purchase>>((ref) {
  return ref.watch(purchasesRepositoryProvider).watchAllPurchases();
});

final _dashboardExpensesStreamProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expensesRepositoryProvider).watchAllExpenses();
});

class DashboardChartPoint {
  const DashboardChartPoint({
    required this.label,
    required this.sales,
    required this.expenses,
  });

  final String label;
  final double sales;
  final double expenses;
}

class DashboardData {
  const DashboardData({
    required this.totalSalesToday,
    required this.salesCountToday,
    required this.totalPurchasesToday,
    required this.totalExpensesToday,
    required this.approxCostOfGoodsSoldToday,
    required this.netProfitApproxToday,
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
  final double totalPurchasesToday;
  final double totalExpensesToday;

  final double approxCostOfGoodsSoldToday;
  final double netProfitApproxToday;

  final int productsCount;

  final List<Product> lowStockProducts;

  final List<Sale> recentSales;

  final Map<String, String> customerNames;

  final List<DashboardChartPoint> dailyChart;
  final List<DashboardChartPoint> weeklyChart;
  final List<DashboardChartPoint> monthlyChart;
  final List<DashboardChartPoint> yearlyChart;

  bool get isEmpty =>
      salesCountToday == 0 &&
      totalPurchasesToday == 0 &&
      totalExpensesToday == 0 &&
      productsCount == 0;
}

bool _isWithin(
  DateTime date,
  DateTime start,
  DateTime endExclusive,
) {
  return !date.isBefore(start) && date.isBefore(endExclusive);
}

List<DashboardChartPoint> _buildDailyChart({
  required List<Sale> sales,
  required List<Expense> expenses,
  required DateTime now,
}) {
  final DateTime today = DateTime(now.year, now.month, now.day);

  return List.generate(7, (index) {
    final DateTime day = today.subtract(Duration(days: 6 - index));
    final DateTime nextDay = day.add(const Duration(days: 1));

    final double salesTotal = sales
        .where((sale) => _isWithin(sale.saleDate, day, nextDay))
        .fold<double>(0, (sum, sale) => sum + sale.total);

    final double expensesTotal = expenses
        .where((expense) => _isWithin(expense.expenseDate, day, nextDay))
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    return DashboardChartPoint(
      label: '${day.day}/${day.month}',
      sales: salesTotal,
      expenses: expensesTotal,
    );
  });
}

List<DashboardChartPoint> _buildWeeklyChart({
  required List<Sale> sales,
  required List<Expense> expenses,
  required DateTime now,
}) {
  final DateTime currentWeekStart =
      DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1));

  return List.generate(8, (index) {
    final DateTime weekStart =
        currentWeekStart.subtract(Duration(days: (7 - index) * 7));

    final DateTime weekEnd = weekStart.add(const Duration(days: 7));

    final double salesTotal = sales
        .where((sale) => _isWithin(sale.saleDate, weekStart, weekEnd))
        .fold<double>(0, (sum, sale) => sum + sale.total);

    final double expensesTotal = expenses
        .where(
          (expense) => _isWithin(
            expense.expenseDate,
            weekStart,
            weekEnd,
          ),
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    return DashboardChartPoint(
      label: '${weekStart.day}/${weekStart.month}',
      sales: salesTotal,
      expenses: expensesTotal,
    );
  });
}

List<DashboardChartPoint> _buildMonthlyChart({
  required List<Sale> sales,
  required List<Expense> expenses,
  required DateTime now,
}) {
  return List.generate(12, (index) {
    final int monthOffset = 11 - index;

    final DateTime firstMonth = DateTime(now.year, now.month - monthOffset);
    final DateTime nextMonth =
        DateTime(firstMonth.year, firstMonth.month + 1);

    final double salesTotal = sales
        .where(
          (sale) => _isWithin(
            sale.saleDate,
            firstMonth,
            nextMonth,
          ),
        )
        .fold<double>(0, (sum, sale) => sum + sale.total);

    final double expensesTotal = expenses
        .where(
          (expense) => _isWithin(
            expense.expenseDate,
            firstMonth,
            nextMonth,
          ),
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    return DashboardChartPoint(
      label: '${firstMonth.month}/${firstMonth.year}',
      sales: salesTotal,
      expenses: expensesTotal,
    );
  });
}

List<DashboardChartPoint> _buildYearlyChart({
  required List<Sale> sales,
  required List<Expense> expenses,
  required DateTime now,
}) {
  return List.generate(5, (index) {
    final int year = now.year - (4 - index);

    final DateTime yearStart = DateTime(year);
    final DateTime yearEnd = DateTime(year + 1);

    final double salesTotal = sales
        .where(
          (sale) => _isWithin(
            sale.saleDate,
            yearStart,
            yearEnd,
          ),
        )
        .fold<double>(0, (sum, sale) => sum + sale.total);

    final double expensesTotal = expenses
        .where(
          (expense) => _isWithin(
            expense.expenseDate,
            yearStart,
            yearEnd,
          ),
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    return DashboardChartPoint(
      label: year.toString(),
      sales: salesTotal,
      expenses: expensesTotal,
    );
  });
}

final dashboardDataProvider = FutureProvider<DashboardData>((ref) async {
  final DateTime now = DateTime.now();

  final DateTime todayStart =
      DateTime(now.year, now.month, now.day);

  final DateTime todayEnd =
      todayStart.add(const Duration(days: 1));

  final List<Sale> sales =
      await ref.watch(_dashboardSalesStreamProvider.future);

  final List<Purchase> purchases =
      await ref.watch(_dashboardPurchasesStreamProvider.future);

  final List<Expense> expenses =
      await ref.watch(_dashboardExpensesStreamProvider.future);

  final List<Product> products =
      await ref.watch(productsProvider.future);

  final List<Customer> customers =
      await ref.watch(customersProvider.future);

  final List<Sale> salesToday = sales
      .where(
        (sale) => _isWithin(
          sale.saleDate,
          todayStart,
          todayEnd,
        ),
      )
      .toList();

  final List<Purchase> purchasesToday = purchases
      .where(
        (purchase) => _isWithin(
          purchase.purchaseDate,
          todayStart,
          todayEnd,
        ),
      )
      .toList();

  final List<Expense> expensesToday = expenses
      .where(
        (expense) => _isWithin(
          expense.expenseDate,
          todayStart,
          todayEnd,
        ),
      )
      .toList();

  final double totalSalesToday = salesToday.fold<double>(
    0,
    (sum, sale) => sum + sale.total,
  );

  final double totalPurchasesToday = purchasesToday.fold<double>(
    0,
    (sum, purchase) => sum + purchase.total,
  );

  final double totalExpensesToday = expensesToday.fold<double>(
    0,
    (sum, expense) => sum + expense.amount,
  );

  final Map<String, Product> productsById = {
    for (final product in products) product.id: product,
  };

  final saleItemsDao = ref.watch(saleItemsDaoProvider);

  double approxCogsToday = 0;

  for (final sale in salesToday) {
    final items =
        await saleItemsDao.getItemsBySaleId(sale.id);

    for (final item in items) {
      final Product? product =
          productsById[item.productId];

      if (product != null) {
        approxCogsToday +=
            product.purchasePrice * item.quantity;
      }
    }
  }

  final double netProfitApproxToday =
      totalSalesToday -
      approxCogsToday -
      totalExpensesToday;

  final List<Product> lowStockProducts = products
      .where(
        (product) =>
            product.isActive &&
            product.quantity <= product.minimumQuantity,
      )
      .toList()
    ..sort(
      (a, b) => a.quantity.compareTo(b.quantity),
    );

  final List<Sale> sortedSales = [...sales]
    ..sort(
      (a, b) => b.saleDate.compareTo(a.saleDate),
    );

  final List<Sale> recentSales =
      sortedSales.take(5).toList();

  final Map<String, String> customerNames = {
    for (final customer in customers)
      customer.id: customer.fullName,
  };

  return DashboardData(
    totalSalesToday: totalSalesToday,
    salesCountToday: salesToday.length,
    totalPurchasesToday: totalPurchasesToday,
    totalExpensesToday: totalExpensesToday,
    approxCostOfGoodsSoldToday: approxCogsToday,
    netProfitApproxToday: netProfitApproxToday,
    productsCount: products.length,
    lowStockProducts: lowStockProducts,
    recentSales: recentSales,
    customerNames: customerNames,
    dailyChart: _buildDailyChart(
      sales: sales,
      expenses: expenses,
      now: now,
    ),
    weeklyChart: _buildWeeklyChart(
      sales: sales,
      expenses: expenses,
      now: now,
    ),
    monthlyChart: _buildMonthlyChart(
      sales: sales,
      expenses: expenses,
      now: now,
    ),
    yearlyChart: _buildYearlyChart(
      sales: sales,
      expenses: expenses,
      now: now,
    ),
  );
});