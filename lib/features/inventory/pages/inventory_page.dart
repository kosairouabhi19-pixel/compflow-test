import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Text(l10n.pageInventory),
      ),
    );
  }
}