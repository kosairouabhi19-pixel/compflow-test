import 'package:flutter/material.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/pos/pages/pos_page.dart';
import '../../features/products/pages/products_page.dart';
import '../../features/reports/pages/reports_page.dart';
import '../../features/sales/pages/sales_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/users/pages/users_page.dart';
import '../../shared/widgets/app_sidebar.dart';
import '../../l10n/app_localizations.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _index = 0;

  List<Widget> _buildPages() {
    return [
      DashboardPage(
        onNavigateToIndex: (index) {
          if (index >= 0 && index < 6) {
            setState(() => _index = index);
          }
        },
      ),
      const PosPage(),
      const ProductsPage(),
      const SalesPage(),
      const UsersPage(),
      const SettingsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _buildPages();

    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_rounded),
        label: l10n.navDashboard,
      ),
      NavigationDestination(
        icon: const Icon(Icons.point_of_sale_rounded),
        label: l10n.navPos,
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_rounded),
        label: l10n.navProducts,
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_rounded),
        label: l10n.navSales,
      ),
      NavigationDestination(
        icon: const Icon(Icons.people_alt_rounded),
        label: l10n.navUsers,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_rounded),
        label: l10n.navSettings,
      ),
    ];

    final reportsButton = PositionedDirectional(
      top: 18,
      end: 24,
      child: FilledButton.tonalIcon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ReportsPage()),
          );
        },
        icon: const Icon(Icons.analytics_outlined),
        label: const Text('تحليل وتقارير'),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Scaffold(
            body: Row(
              children: [
                AppSidebar(
                  selectedIndex: _index,
                  onSelect: (index) {
                    if (index >= 0 && index < pages.length) {
                      setState(() => _index = index);
                    }
                  },
                ),
                Expanded(
                  child: Stack(
                    children: [
                      pages[_index],
                      if (_index == 0) reportsButton,
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              pages[_index],
              if (_index == 0)
                PositionedDirectional(
                  top: 12,
                  end: 16,
                  child: FloatingActionButton.small(
                    tooltip: 'تحليل وتقارير',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ReportsPage()),
                      );
                    },
                    child: const Icon(Icons.analytics_outlined),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            destinations: destinations,
            onDestinationSelected: (index) {
              setState(() => _index = index);
            },
          ),
        );
      },
    );
  }
}
