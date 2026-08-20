import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key, this.onNavigateToIndex});

  final ValueChanged<int>? onNavigateToIndex;

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _chartMode = 0;

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(dashboardDataProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _DashboardErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(dashboardDataProvider),
          ),
          data: (data) => _DashboardContent(
            data: data,
            chartMode: _chartMode,
            onChartModeChanged: (value) => setState(() => _chartMode = value),
            onNavigateToIndex: widget.onNavigateToIndex,
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(double value, AppLocalizations l10n) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return '${buffer.toString()} ${l10n.currencyDzd}';
}

String _averageInvoiceLabel(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'fr' => 'Panier moyen',
    'en' => 'Average invoice',
    _ => 'متوسط الفاتورة',
  };
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.chartMode,
    required this.onChartModeChanged,
    required this.onNavigateToIndex,
  });

  final DashboardData data;
  final int chartMode;
  final ValueChanged<int> onChartModeChanged;
  final ValueChanged<int>? onNavigateToIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(desktop ? 32 : 16, 20, desktop ? 32 : 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DashboardHeader(onNavigateToIndex: onNavigateToIndex),
                  const SizedBox(height: 22),
                  _MetricsGrid(data: data),
                  const SizedBox(height: 22),
                  _SalesChartCard(
                    data: data,
                    selectedMode: chartMode,
                    onModeChanged: onChartModeChanged,
                  ),
                  const SizedBox(height: 22),
                  if (desktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _RecentSalesSection(
                            sales: data.recentSales,
                            customerNames: data.customerNames,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 2,
                          child: _LowStockSection(products: data.lowStockProducts),
                        ),
                      ],
                    )
                  else ...[
                    _RecentSalesSection(
                      sales: data.recentSales,
                      customerNames: data.customerNames,
                    ),
                    const SizedBox(height: 18),
                    _LowStockSection(products: data.lowStockProducts),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onNavigateToIndex});

  final ValueChanged<int>? onNavigateToIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboardTitle,
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.dashboardSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        );

        final button = FilledButton.icon(
          onPressed: onNavigateToIndex == null ? null : () => onNavigateToIndex!(1),
          icon: const Icon(Icons.point_of_sale_rounded),
          label: Text(l10n.dashboardNewSale),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 14),
              Align(alignment: AlignmentDirectional.centerStart, child: button),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            button,
          ],
        );
      },
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final metrics = [
      _Metric(Icons.point_of_sale_rounded, l10n.dashboardSalesToday, _formatCurrency(data.totalSalesToday, l10n)),
      _Metric(Icons.receipt_long_rounded, l10n.dashboardSalesCountToday, data.salesCountToday.toString()),
      _Metric(Icons.shopping_cart_checkout_rounded, _averageInvoiceLabel(context), _formatCurrency(data.averageSaleToday, l10n), emphasize: true),
      _Metric(Icons.inventory_2_rounded, l10n.dashboardProductsCount, data.productsCount.toString()),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900 ? 4 : constraints.maxWidth >= 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 145,
          ),
          itemBuilder: (context, index) => _MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class _Metric {
  const _Metric(this.icon, this.label, this.value, {this.emphasize = false});
  final IconData icon;
  final String label;
  final String value;
  final bool emphasize;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});
  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: metric.emphasize ? colors.primary : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: metric.emphasize ? colors.primary : colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: metric.emphasize ? colors.onPrimary.withOpacity(.12) : colors.primary.withOpacity(.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: metric.emphasize ? colors.onPrimary : colors.primary),
          ),
          const Spacer(),
          Text(
            metric.value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: metric.emphasize ? colors.onPrimary : colors.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            metric.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: metric.emphasize ? colors.onPrimary.withOpacity(.8) : colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  const _SalesChartCard({
    required this.data,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final DashboardData data;
  final int selectedMode;
  final ValueChanged<int> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final points = switch (selectedMode) {
      1 => data.weeklyChart,
      2 => data.monthlyChart,
      3 => data.yearlyChart,
      _ => data.dailyChart,
    };

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final header = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardChartTitle,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                switch (Localizations.localeOf(context).languageCode) {
                  'fr' => 'Évolution du chiffre d’affaires',
                  'en' => 'Sales trend over time',
                  _ => 'تطور المبيعات مع مرور الوقت',
                },
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                header,
                const SizedBox(height: 16),
                _ChartRangeSelector(
                  selectedMode: selectedMode,
                  onChanged: onModeChanged,
                  labels: [
                    l10n.dashboardDaily,
                    l10n.dashboardWeekly,
                    l10n.dashboardMonthly,
                    l10n.dashboardYearly,
                  ],
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: header),
                    const SizedBox(width: 16),
                    SegmentedButton<int>(
                      segments: [
                        ButtonSegment<int>(value: 0, label: Text(l10n.dashboardDaily)),
                        ButtonSegment<int>(value: 1, label: Text(l10n.dashboardWeekly)),
                        ButtonSegment<int>(value: 2, label: Text(l10n.dashboardMonthly)),
                        ButtonSegment<int>(value: 3, label: Text(l10n.dashboardYearly)),
                      ],
                      selected: {selectedMode},
                      onSelectionChanged: (value) => onModeChanged(value.first),
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              SizedBox(
                height: compact ? 250 : 300,
                child: points.isEmpty
                    ? Center(child: Text(l10n.dashboardChartEmpty))
                    : CustomPaint(
                        painter: _SalesLineChartPainter(
                          points: points,
                          colors: colors,
                          textStyle: theme.textTheme.bodySmall!,
                        ),
                        child: const SizedBox.expand(),
                      ),
              ),
              const SizedBox(height: 10),
              _ChartLegend(color: colors.primary, label: l10n.dashboardSalesLegend),
            ],
          );
        },
      ),
    );
  }
}

class _ChartRangeSelector extends StatelessWidget {
  const _ChartRangeSelector({required this.selectedMode, required this.onChanged, required this.labels});

  final int selectedMode;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (int i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedMode == i ? colors.primary : Colors.transparent,
                    border: i == 0 ? null : BorderDirectional(start: BorderSide(color: colors.outlineVariant)),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: selectedMode == i ? FontWeight.w700 : FontWeight.w500,
                      color: selectedMode == i ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(label),
      ],
    );
  }
}

class _SalesLineChartPainter extends CustomPainter {
  _SalesLineChartPainter({required this.points, required this.colors, required this.textStyle});

  final List<DashboardChartPoint> points;
  final ColorScheme colors;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const left = 58.0;
    const right = 18.0;
    const top = 18.0;
    const bottom = 40.0;
    final width = math.max(1, size.width - left - right);
    final height = math.max(1, size.height - top - bottom);
    final maxValue = points.fold<double>(0, (max, point) => math.max(max, point.sales));
    final safeMax = maxValue <= 0 ? 1.0 : maxValue * 1.15;
    final gridPaint = Paint()
      ..color = colors.outlineVariant.withOpacity(.65)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = colors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()..color = colors.primary;
    final areaPaint = Paint()
      ..color = colors.primary.withOpacity(.10)
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= 4; i++) {
      final y = top + height - height * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), gridPaint);
      final value = safeMax * i / 4;
      final label = value.round().toString();
      final painter = TextPainter(
        text: TextSpan(text: label, style: textStyle.copyWith(color: colors.onSurfaceVariant)),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(left - painter.width - 8, y - painter.height / 2));
    }

    final path = Path();
    final pointsOnCanvas = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? left + width / 2
          : left + width * i / (points.length - 1);
      final y = top + height - height * points[i].sales / safeMax;
      final offset = Offset(x, y);
      pointsOnCanvas.add(offset);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final area = Path.from(path)
      ..lineTo(pointsOnCanvas.last.dx, top + height)
      ..lineTo(pointsOnCanvas.first.dx, top + height)
      ..close();
    canvas.drawPath(area, areaPaint);
    canvas.drawPath(path, linePaint);

    final labelStep = points.length <= 8 ? 1 : (points.length / 7).ceil();
    for (int i = 0; i < points.length; i += labelStep) {
      final point = pointsOnCanvas[i];
      canvas.drawCircle(point, 5, pointPaint);
      final painter = TextPainter(
        text: TextSpan(text: points[i].label, style: textStyle.copyWith(color: colors.onSurfaceVariant)),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(point.dx - painter.width / 2, size.height - 24));
    }
    if (points.length > 1 && (points.length - 1) % labelStep != 0) {
      final i = points.length - 1;
      final point = pointsOnCanvas[i];
      canvas.drawCircle(point, 5, pointPaint);
      final painter = TextPainter(
        text: TextSpan(text: points[i].label, style: textStyle.copyWith(color: colors.onSurfaceVariant)),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(point.dx - painter.width / 2, size.height - 24));
    }
  }

  @override
  bool shouldRepaint(covariant _SalesLineChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.colors != colors;
}

class _RecentSalesSection extends StatelessWidget {
  const _RecentSalesSection({required this.sales, required this.customerNames});
  final List<Sale> sales;
  final Map<String, String> customerNames;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashboardRecentSalesTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (sales.isEmpty)
              Text(l10n.dashboardRecentSalesEmpty)
            else
              for (final sale in sales)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(Icons.receipt_long_rounded, color: colors.onPrimaryContainer),
                  ),
                  title: Text(sale.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${customerNames[sale.customerId] ?? l10n.dashboardUnknownCustomer} • ${_formatDateTime(sale.saleDate)}'),
                  trailing: Text(
                    _formatCurrency(sale.total, l10n),
                    style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _LowStockSection extends StatelessWidget {
  const _LowStockSection({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.dashboardLowStockTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (products.isEmpty)
              Text(l10n.dashboardLowStockEmpty)
            else
              for (final product in products.take(8))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colors.errorContainer,
                    child: Icon(Icons.inventory_2_outlined, color: colors.onErrorContainer),
                  ),
                  title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(l10n.dashboardLowStockQuantity(product.quantity, product.minimumQuantity)),
                ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(l10n.dashboardErrorTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}