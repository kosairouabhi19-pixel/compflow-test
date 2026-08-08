import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/pos/pages/pos_page.dart';
import '../../features/products/pages/products_page.dart';
import '../../features/users/pages/users_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/app_header.dart';
import '../../features/sales/pages/sales_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    PosPage(),
    ProductsPage(),
    SalesPage(),
    UsersPage(),
    SettingsPage(),
  ];

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.point_of_sale_rounded),
      label: 'POS',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_rounded),
      label: 'Products',
    ),
    NavigationDestination(
      icon: Icon(Icons.receipt_long_rounded),
      label: 'Sales',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_alt_rounded),
      label: 'Users',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                AppSidebar(
                  selectedIndex: _index,
                  onSelect: (index) {
                    setState(() {
                      _index = index;
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    children: [
                      const AppHeader(),
                      Expanded(
                        child: _pages[_index],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

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
      },
    );
  }
}