import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../providers/reports_providers.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? currentRange = ref.read(customReportRangeProvider);
    final DateTime now = DateTime.now();

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: currentRange,
    );

    if (picked != null) {
      ref.read(customReportRangeProvider.notifier).state = picked;
      ref.read(reportPeriodProvider.notifier).state =
          ReportPeriodOption.custom;
    }
  }

  String _periodLabel(AppLocalizations l10n, ReportPeriodOption option) {
    switch (option) {
      case ReportPeriodOption.today:
        return l10n.reportsToday;
      case ReportPeriodOption.thisWeek:
        return l10n.reportsWeek;
      case ReportPeriodOption.thisMonth:
        return l10n.reportsMonth;
      case ReportPeriodOption.custom:
        return l10n.reportsCustom;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ReportPeriodOption selectedPeriod = ref.watch(reportPeriodProvider);
    final AsyncValue<ReportData> reportAsync = ref.watch(reportDataProvider);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isWide = mediaQuery.size.width >= 600;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reportsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 24 : 16,
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 900 : double.infinity,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in ReportPeriodOption.values)
                        ChoiceChip(
                          label: Text(_periodLabel(l10n, option)),
                          selected: selectedPeriod == option,
                          onSelected: (selected) {
                            if (!selected) return;
                            if (option == ReportPeriodOption.custom) {
                              _pickCustomRange(context, ref);
                            } else {
                              ref.read(reportPeriodProvider.notifier).state =
                                  option;
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: reportAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ReportsErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(reportDataProvider),
                ),
                data: (report) => report.isEmpty
                    ? const _ReportsEmptyState()
                    : _ReportsContent(report: report, isWide: isWide),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(double value) => value.toStringAsFixed(2);

String _formatDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

class _ReportsContent extends StatelessWidget {
  const _ReportsContent({required this.report, required this.isWide});

  final ReportData report;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final DateTime lastDayInclusive =
        report.rangeEnd.subtract(const Duration(days: 1));
    final String rangeLabel = _formatDate(report.rangeStart) ==
            _formatDate(lastDayInclusive)
        ? _formatDate(report.rangeStart)
        : '${_formatDate(report.rangeStart)} → ${_formatDate(lastDayInclusive)}';

    final List<_ReportMetric> metrics = [
      _ReportMetric(
        icon: Icons.point_of_sale_outlined,
        label: l10n.reportsTotalSales,
        value: _formatCurrency(report.totalSales),
      ),
      _ReportMetric(
        icon: Icons.shopping_cart_outlined,
        label: l10n.reportsTotalPurchases,
        value: _formatCurrency(report.totalPurchases),
      ),
      _ReportMetric(
        icon: Icons.receipt_long_outlined,
        label: l10n.reportsTotalExpenses,
        value: _formatCurrency(report.totalExpenses),
      ),
      _ReportMetric(
        icon: Icons.trending_up_outlined,
        label: l10n.reportsNetProfit,
        value: _formatCurrency(report.netProfitApprox),
        emphasize: true,
      ),
      _ReportMetric(
        icon: Icons.confirmation_number_outlined,
        label: l10n.reportsSalesCount,
        value: report.salesCount.toString(),
      ),
      _ReportMetric(
        icon: Icons.local_shipping_outlined,
        label: l10n.reportsPurchasesCount,
        value: report.purchasesCount.toString(),
      ),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 24 : 16,
        vertical: 8,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1000 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.reportsPeriod(rangeLabel),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final int crossAxisCount =
                      (constraints.maxWidth / 260).floor().clamp(1, 3);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 110,
                    ),
                    itemCount: metrics.length,
                    itemBuilder: (context, index) =>
                        _ReportMetricCard(metric: metrics[index]),
                  );
                },
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.reportsProfitDetails,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _DetailRow(
                        label: l10n.reportsSales,
                        value: _formatCurrency(report.totalSales),
                      ),
                      _DetailRow(
                        label: l10n.reportsCogs,
                        value: _formatCurrency(report.approxCostOfGoodsSold),
                      ),
                      _DetailRow(
                        label: l10n.reportsExpenses,
                        value: _formatCurrency(report.totalExpenses),
                      ),
                      const Divider(),
                      _DetailRow(
                        label: l10n.reportsNetProfit,
                        value: _formatCurrency(report.netProfitApprox),
                        bold: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.reportsNote,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportMetric {
  const _ReportMetric({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({required this.metric});

  final _ReportMetric metric;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: metric.emphasize ? colors.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              metric.icon,
              color: metric.emphasize
                  ? colors.onPrimaryContainer
                  : colors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              metric.value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: metric.emphasize ? colors.onPrimaryContainer : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              metric.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: metric.emphasize
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = bold
        ? Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _ReportsErrorState extends StatelessWidget {
  const _ReportsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                l10n.reportsLoadError,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(l10n.commonRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bar_chart_outlined,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reportsEmpty,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.reportsEmptyHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}