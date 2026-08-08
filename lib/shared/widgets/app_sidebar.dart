import 'package:flutter/material.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelect;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded, "Dashboard"),
      (Icons.point_of_sale_rounded, "POS"),
      (Icons.inventory_2_rounded, "Products"),
      (Icons.receipt_long_rounded, "Sales"),
      (Icons.people_alt_rounded, "Users"),
      (Icons.settings_rounded, "Settings"),
    ];

    return Container(
      width: 90,
      color: const Color(0xFF14343C),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            const Icon(
              Icons.memory_rounded,
              color: Colors.white,
              size: 34,
            ),

            const SizedBox(height: 24),

            for (int i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Tooltip(
                  message: items[i].$2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: selectedIndex == i
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        items[i].$1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            const Spacer(),

            const Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: CircleAvatar(
                radius: 20,
                child: Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
    );
  }
}