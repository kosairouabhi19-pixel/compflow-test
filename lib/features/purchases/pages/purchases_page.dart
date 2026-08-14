import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class PurchasesPage extends StatelessWidget {
  const PurchasesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Text(l10n.pagePurchases),
      ),
    );
  }
}