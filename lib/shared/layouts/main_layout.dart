import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/products/pages/products_page.dart';
import '../../features/customers/pages/customers_page.dart';
import '../../features/inventory/pages/inventory_page.dart';
import '../../features/sales/pages/sales_page.dart';
import '../../features/purchases/pages/purchases_page.dart';
import '../../features/invoices/pages/invoices_page.dart';
import '../../features/expenses/pages/expenses_page.dart';
import '../../features/payments/pages/payments_page.dart';
import '../../features/reports/pages/reports_page.dart';
import '../../features/settings/pages/settings_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    ProductsPage(),
    CustomersPage(),
    InventoryPage(),
    SalesPage(),
    PurchasesPage(),
    InvoicesPage(),
    ExpensesPage(),
    PaymentsPage(),
    ReportsPage(),
    SettingsPage(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.inventory_2), label: 'Products'),
    NavigationDestination(icon: Icon(Icons.people), label: 'Customers'),
    NavigationDestination(icon: Icon(Icons.warehouse), label: 'Inventory'),
    NavigationDestination(icon: Icon(Icons.point_of_sale), label: 'Sales'),
    NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Purchases'),
    NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Invoices'),
    NavigationDestination(icon: Icon(Icons.money_off), label: 'Expenses'),
    NavigationDestination(icon: Icon(Icons.payments), label: 'Payments'),
    NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: _destinations,
        onDestinationSelected: (index) {
          setState(() {
            _index = index;
          });
        },
      ),
    );
  }
}