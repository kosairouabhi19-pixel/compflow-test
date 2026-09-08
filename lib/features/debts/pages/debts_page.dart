import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/providers/current_tenant_provider.dart';
import '../../customers/providers/customers_providers.dart';
import '../../invoices/database/invoices_dao.dart';
import '../../payments/database/payments_dao.dart';

final debtsInvoicesDaoProvider = Provider<InvoicesDao>((ref) {
  return InvoicesDao(ref.watch(appDatabaseProvider));
});

final debtsPaymentsDaoProvider = Provider<PaymentsDao>((ref) {
  return PaymentsDao(ref.watch(appDatabaseProvider));
});

class DebtsPage extends ConsumerWidget {
  const DebtsPage({super.key});

  String _tr(String language, String ar, String en, String fr) {
    return language == 'en' ? en : language == 'fr' ? fr : ar;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    final tenantId = ref.watch(currentTenantProvider);
    final customersAsync = ref.watch(customersProvider);

    if (tenantId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_tr(language, 'الديون', 'Debts', 'Dettes'))),
        body: Center(child: Text(_tr(language, 'لا يوجد متجر نشط.', 'No active shop.', 'Aucun magasin actif.'))),
      );
    }

    final customerNames = customersAsync.maybeWhen(
      data: (customers) => {for (final customer in customers) customer.id: customer.fullName},
      orElse: () => const <String, String>{},
    );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_tr(language, 'الديون', 'Debts', 'Dettes')),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: FilledButton.icon(
              onPressed: () => _showAddDebtDialog(context, ref, tenantId, customerNames, language),
              icon: const Icon(Icons.add_card_outlined),
              label: Text(_tr(language, 'تسجيل دين', 'Record debt', 'Enregistrer une dette')),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Invoice>>(
        stream: ref.watch(debtsInvoicesDaoProvider).watchAllInvoices(tenantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(_tr(language, 'تعذر تحميل الديون.', 'Could not load debts.', 'Impossible de charger les dettes.')));
          }

          final debts = (snapshot.data ?? const <Invoice>[])
              .where((invoice) => invoice.remaining > 0.009 && invoice.deletedAt == null)
              .toList()
            ..sort((a, b) => b.invoiceDate.compareTo(a.invoiceDate));

          final total = debts.fold<double>(0, (sum, debt) => sum + debt.remaining);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryCard(
                      icon: Icons.people_alt_outlined,
                      label: _tr(language, 'عملاء عليهم ديون', 'Customers with debt', 'Clients débiteurs'),
                      value: '${debts.map((e) => e.customerId).toSet().length}',
                    ),
                    _SummaryCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: _tr(language, 'إجمالي الديون', 'Total outstanding', 'Total restant'),
                      value: '${total.toStringAsFixed(0)} DZD',
                    ),
                    _SummaryCard(
                      icon: Icons.receipt_long_outlined,
                      label: _tr(language, 'سجلات الديون', 'Debt records', 'Dossiers de dette'),
                      value: '${debts.length}',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: debts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.account_balance_wallet_outlined, size: 56, color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 12),
                              Text(_tr(language, 'لا توجد ديون مستحقة حاليًا.', 'No outstanding debts.', 'Aucune dette impayée.')),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: debts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final debt = debts[index];
                            final customerName = customerNames[debt.customerId] ?? _tr(language, 'عميل غير معروف', 'Unknown customer', 'Client inconnu');
                            return _DebtCard(
                              debt: debt,
                              customerName: customerName,
                              language: language,
                              onPay: () => _showPaymentDialog(context, ref, tenantId, debt, customerName, language),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddDebtDialog(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    Map<String, String> customerNames,
    String language,
  ) async {
    final customerIds = customerNames.keys.toList();
    if (customerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr(language, 'أضف عميلًا أولًا قبل تسجيل الدين.', 'Add a customer before recording a debt.', 'Ajoutez un client avant d’enregistrer une dette.'))),
      );
      return;
    }

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var selectedCustomer = customerIds.first;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(_tr(language, 'تسجيل دين جديد', 'Record new debt', 'Enregistrer une dette')),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedCustomer,
                      decoration: InputDecoration(labelText: _tr(language, 'العميل', 'Customer', 'Client')),
                      items: [
                        for (final id in customerIds)
                          DropdownMenuItem(value: id, child: Text(customerNames[id] ?? id)),
                      ],
                      onChanged: (value) => setState(() => selectedCustomer = value ?? selectedCustomer),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: _tr(language, 'المبلغ', 'Amount', 'Montant'), suffixText: 'DZD'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: _tr(language, 'ملاحظة', 'Note', 'Note')),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(_tr(language, 'إلغاء', 'Cancel', 'Annuler'))),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_tr(language, 'حفظ', 'Save', 'Enregistrer'))),
            ],
          ),
        ),
      );

      if (result != true) return;
      final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
      if (amount == null || amount <= 0) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr(language, 'أدخل مبلغًا صحيحًا.', 'Enter a valid amount.', 'Saisissez un montant valide.'))));
        }
        return;
      }

      final now = DateTime.now().toUtc();
      final id = const Uuid().v4();
      final invoiceNumber = 'DEBT-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      await ref.read(debtsInvoicesDaoProvider).insertInvoice(
        InvoicesCompanion(
          id: Value(id),
          tenantId: Value(tenantId),
          createdAt: Value(now),
          updatedAt: Value(now),
          version: const Value(1),
          syncStatus: const Value('pending'),
          deviceId: const Value(''),
          customerId: Value(selectedCustomer),
          invoiceNumber: Value(invoiceNumber),
          total: Value(amount),
          paid: const Value(0),
          remaining: Value(amount),
          invoiceDate: Value(now),
          status: const Value('unpaid'),
        ),
        tenantId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr(language, 'تم تسجيل الدين.', 'Debt recorded.', 'Dette enregistrée.'))));
      }
    } finally {
      amountController.dispose();
      noteController.dispose();
    }
  }

  Future<void> _showPaymentDialog(
    BuildContext context,
    WidgetRef ref,
    String tenantId,
    Invoice debt,
    String customerName,
    String language,
  ) async {
    final amountController = TextEditingController(text: debt.remaining.toStringAsFixed(0));
    final noteController = TextEditingController();
    var method = 'cash';

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('${_tr(language, 'سداد دين', 'Pay debt', 'Régler la dette')} — $customerName'),
            content: SizedBox(
              width: 460,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_tr(language, 'المتبقي', 'Remaining', 'Restant')}: ${debt.remaining.toStringAsFixed(0)} DZD'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: _tr(language, 'مبلغ السداد', 'Payment amount', 'Montant du paiement'), suffixText: 'DZD'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: InputDecoration(labelText: _tr(language, 'طريقة الدفع', 'Payment method', 'Mode de paiement')),
                    items: [
                      DropdownMenuItem(value: 'cash', child: Text(_tr(language, 'نقدًا', 'Cash', 'Espèces'))),
                      DropdownMenuItem(value: 'card', child: Text(_tr(language, 'بطاقة', 'Card', 'Carte'))),
                      DropdownMenuItem(value: 'transfer', child: Text(_tr(language, 'تحويل', 'Transfer', 'Virement'))),
                    ],
                    onChanged: (value) => setState(() => method = value ?? method),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: noteController, decoration: InputDecoration(labelText: _tr(language, 'ملاحظة', 'Note', 'Note'))),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(_tr(language, 'إلغاء', 'Cancel', 'Annuler'))),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_tr(language, 'تسجيل السداد', 'Record payment', 'Enregistrer le paiement'))),
            ],
          ),
        ),
      );

      if (result != true) return;
      final amount = double.tryParse(amountController.text.trim().replaceAll(',', '.'));
      if (amount == null || amount <= 0 || amount > debt.remaining + 0.009) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr(language, 'مبلغ السداد غير صحيح.', 'Invalid payment amount.', 'Montant de paiement invalide.'))));
        }
        return;
      }

      final now = DateTime.now().toUtc();
      final newPaid = debt.paid + amount;
      final newRemaining = (debt.total - newPaid).clamp(0, debt.total).toDouble();
      final status = newRemaining <= 0.009 ? 'paid' : 'partial';

      await ref.read(debtsPaymentsDaoProvider).insertPayment(
        PaymentsCompanion(
          id: Value(const Uuid().v4()),
          tenantId: Value(tenantId),
          createdAt: Value(now),
          updatedAt: Value(now),
          version: const Value(1),
          syncStatus: const Value('pending'),
          deviceId: const Value(''),
          customerId: Value(debt.customerId),
          amount: Value(amount),
          paymentDate: Value(now),
          paymentMethod: Value(method),
          notes: Value(noteController.text.trim().isEmpty ? null : noteController.text.trim()),
        ),
        tenantId,
      );

      final updated = debt.copyWith(
        paid: newPaid,
        remaining: newRemaining,
        status: status,
        updatedAt: now,
        version: debt.version + 1,
        syncStatus: 'pending',
      );
      await ref.read(debtsInvoicesDaoProvider).updateInvoice(updated, tenantId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tr(language, 'تم تسجيل السداد.', 'Payment recorded.', 'Paiement enregistré.'))));
      }
    } finally {
      amountController.dispose();
      noteController.dispose();
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: SizedBox(
        width: 250,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: colors.primaryContainer, child: Icon(icon, color: colors.onPrimaryContainer)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt, required this.customerName, required this.language, required this.onPay});

  final Invoice debt;
  final String customerName;
  final String language;
  final VoidCallback onPay;

  String _tr(String ar, String en, String fr) => language == 'en' ? en : language == 'fr' ? fr : ar;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paidRatio = debt.total <= 0 ? 0.0 : (debt.paid / debt.total).clamp(0.0, 1.0).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: colors.errorContainer, child: Icon(Icons.account_balance_wallet_outlined, color: colors.onErrorContainer)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(customerName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(debt.invoiceNumber, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                  ]),
                ),
                Text('${debt.remaining.toStringAsFixed(0)} DZD', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.error, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                FilledButton.tonalIcon(onPressed: onPay, icon: const Icon(Icons.payments_outlined), label: Text(_tr('سداد', 'Pay', 'Payer'))),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(value: paidRatio),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('${_tr('الأصل', 'Total', 'Total')}: ${debt.total.toStringAsFixed(0)} DZD')),
                Text('${_tr('مدفوع', 'Paid', 'Payé')}: ${debt.paid.toStringAsFixed(0)} DZD'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
