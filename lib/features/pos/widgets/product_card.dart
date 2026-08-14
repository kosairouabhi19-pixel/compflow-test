import 'package:flutter/material.dart';

/// بطاقة عرض المنتج في صفحة نقطة البيع (POS).
class ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String stock;
  final bool isOutOfStock;
  final bool isLowStock;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.stock,
    this.isOutOfStock = false,
    this.isLowStock = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color badgeBg = isOutOfStock
        ? colorScheme.errorContainer
        : isLowStock
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHigh;

    final Color badgeFg = isOutOfStock
        ? colorScheme.onErrorContainer
        : isLowStock
            ? colorScheme.onTertiaryContainer
            : colorScheme.onSurfaceVariant;

    return Card(
      elevation: 0,
      color: isOutOfStock
          ? colorScheme.surfaceContainerLow.withValues(alpha: 0.6)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOutOfStock
              ? colorScheme.error.withValues(alpha: 0.2)
              : colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isOutOfStock ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // صورة / أيقونة المنتج مع شارة المخزون
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.devices_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stock,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: badgeFg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // اسم المنتج
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.2,
                  color: isOutOfStock
                      ? colorScheme.onSurface.withValues(alpha: 0.5)
                      : colorScheme.onSurface,
                ),
              ),

              const SizedBox(height: 8),

              // السعر وزر الإضافة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      price,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isOutOfStock
                            ? colorScheme.onSurface.withValues(alpha: 0.4)
                            : colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isOutOfStock ? Icons.block_rounded : Icons.add_rounded,
                      color: isOutOfStock
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onPrimary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}