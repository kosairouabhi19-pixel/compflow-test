import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class InvoicesPage extends StatelessWidget {
  const InvoicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Text(l10n.pageInvoices),
      ),
    );
  }
}