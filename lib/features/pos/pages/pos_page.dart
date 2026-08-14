import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/database/app_database.dart';
import '../../products/providers/products_providers.dart';
import '../../sales/providers/sales_providers.dart';
import '../widgets/product_card.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final int stock;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final List<CartItem> cart = [];

  final TextEditingController _searchController = TextEditingController();

  final Uuid _uuid = const Uuid();

  static const String _tenantId = '11111111-1111-1111-1111-111111111111';

  static const String _deviceId = 'windows';

  String _searchQuery = '';
  bool _onlyInStock = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get total {
    return cart.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
  }

  int get totalItemsCount {
    return cart.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
  }

  String formatPrice(double price) {
    final value = price.round().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < value.length; i++) {
      final reverseIndex = value.length - i;

      buffer.write(value[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }

  void addToCart(Product product) {
    final l10n = AppLocalizations.of(context);
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.posOutOfStock),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final index = cart.indexWhere(
      (item) => item.id == product.id,
    );

    setState(() {
      if (index != -1) {
        if (cart[index].quantity < cart[index].stock) {
          cart[index].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.posStockExceeded),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        cart.add(
          CartItem(
            id: product.id,
            name: product.name,
            price: product.sellingPrice,
            stock: product.quantity,
          ),
        );
      }
    });
  }

  void increaseQuantity(int index) {
    final l10n = AppLocalizations.of(context);
    final item = cart[index];

    if (item.quantity >= item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.posStockExceeded),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      item.quantity++;
    });
  }

  void decreaseQuantity(int index) {
    setState(() {
      if (cart[index].quantity > 1) {
        cart[index].quantity--;
      } else {
        cart.removeAt(index);
      }
    });
  }

  void removeFromCart(int index) {
    setState(() {
      cart.removeAt(index);
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  Future<void> completeSale() async {
    final l10n = AppLocalizations.of(context);
    if (cart.isEmpty) return;

    try {
      final repository = ref.read(
        salesRepositoryProvider,
      );

      final now = DateTime.now();

      final sale = Sale(
        id: _uuid.v4(),
        tenantId: _tenantId,
        customerId: '',
        invoiceNumber: 'INV-${now.millisecondsSinceEpoch}',
        total: total,
        saleDate: now,
        notes: null,
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        version: 1,
        syncStatus: 'pending',
        deviceId: _deviceId,
      );

      final items = cart.map((item) {
        return SaleItemsCompanion.insert(
          id: _uuid.v4(),
          tenantId: _tenantId,
          createdAt: now,
          updatedAt: now,
          deviceId: _deviceId,
          saleId: sale.id,
          productId: item.id,
          quantity: item.quantity,
          unitPrice: item.price,
          total: item.totalPrice,
        );
      }).toList();

      await repository.completeSale(
        sale: sale,
        items: items,
      );

      if (!mounted) return;

      setState(() {
        cart.clear();
      });

      // تحديث المنتجات بعد خصم المخزون
      ref.invalidate(productsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.posSaleSuccess),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.posCompleteSaleError(e)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openMobileCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCartPanel(isMobileSheet: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bool isDesktop = mediaQuery.size.width >= 900;

    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.posLoadProductsError,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => ref.invalidate(productsProvider),
                  child: Text(l10n.commonRetry),
                ),
              ],
            ),
          ),
        ),
        data: (products) {
          final query = _searchQuery.trim().toLowerCase();

          final filteredProducts = products.where((product) {
            if (_onlyInStock && product.quantity <= 0) {
              return false;
            }

            if (query.isEmpty) return true;

            final name = product.name.toLowerCase();
            final sku = product.sku.toLowerCase();
            final barcode = product.barcode?.toLowerCase() ?? '';

            return name.contains(query) ||
                sku.contains(query) ||
                barcode.contains(query);
          }).toList();

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 20 : 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================
                      // قسم المنتجات (الجهة الرئيسية)
                      // =========================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // شريط البحث والفلترة
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                    decoration: InputDecoration(
                                      hintText: l10n.posSearchHint,
                                      prefixIcon: const Icon(Icons.search_rounded),
                                      suffixIcon: _searchQuery.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.clear_rounded),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {
                                                  _searchQuery = '';
                                                });
                                              },
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                FilterChip(
                                  selected: _onlyInStock,
                                  showCheckmark: false,
                                  avatar: Icon(
                                    _onlyInStock
                                        ? Icons.check_circle_rounded
                                        : Icons.inventory_2_outlined,
                                    size: 18,
                                    color: _onlyInStock
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  label: Text(
                                    l10n.navProducts,
                                    style: TextStyle(
                                      fontWeight: _onlyInStock
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _onlyInStock = selected;
                                    });
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // شبكة المنتجات
                            Expanded(
                              child: filteredProducts.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.search_off_rounded,
                                            size: 48,
                                            color: colorScheme.outline,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            l10n.posNoProducts,
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        final crossAxisCount = (constraints.maxWidth / 180)
                                            .floor()
                                            .clamp(2, 6);

                                        return GridView.builder(
                                          itemCount: filteredProducts.length,
                                          gridDelegate:
                                              SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: crossAxisCount,
                                            mainAxisSpacing: 12,
                                            crossAxisSpacing: 12,
                                            childAspectRatio: 0.82,
                                          ),
                                          itemBuilder: (context, index) {
                                            final product = filteredProducts[index];
                                            final bool isOutOfStock = product.quantity <= 0;
                                            final bool isLowStock = product.quantity > 0 &&
                                                product.quantity <= product.minimumQuantity;

                                            return ProductCard(
                                              name: product.name,
                                              price: '${formatPrice(product.sellingPrice)} ${l10n.currencyDzd}',
                                              stock: l10n.posStock(product.quantity),
                                              isOutOfStock: isOutOfStock,
                                              isLowStock: isLowStock,
                                              onTap: () => addToCart(product),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // =========================
                      // لوحة السلة (في العرض الكبـير Desktop)
                      // =========================
                      if (isDesktop) ...[
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 380,
                          child: _buildCartPanel(isMobileSheet: false),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // =========================
              // شريط السلة السفلي للموبايل (Mobile Docked Bar)
              // =========================
              if (!isDesktop) _buildMobileCartDockBar(context, l10n, colorScheme),
            ],
          );
        },
      ),
    );
  }

  /// بناء لوحة السلة الإحترافية
  Widget _buildCartPanel({required bool isMobileSheet}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          // ترويسة السلة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.posCartTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                if (cart.isNotEmpty)
                  Badge(
                    label: Text('$totalItemsCount'),
                    backgroundColor: colorScheme.primary,
                    textColor: colorScheme.onPrimary,
                  ),
                const Spacer(),
                if (cart.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.delete_sweep_outlined,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    tooltip: l10n.commonClear,
                    onPressed: clearCart,
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // قائمة عناصر السلة
          Expanded(
            child: cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 44,
                          color: colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.posCartEmpty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: cart.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = cart[index];

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: colorScheme.error,
                                  ),
                                  onPressed: () => removeFromCart(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.posPerUnit(formatPrice(item.price)),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                // أزرار التحكم بالكمية
                                Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () => decreaseQuantity(index),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.remove_rounded,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10),
                                        child: Text(
                                          '${item.quantity}',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () => increaseQuantity(index),
                                        child: Padding(
                                          padding: const EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.add_rounded,
                                            size: 16,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // المجموع الجزئي
                                Text(
                                  '${formatPrice(item.totalPrice)} ${l10n.currencyDzd}',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // قسم الإجمالي وزر إتمام البيع
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.posTotal,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${formatPrice(total)} ${l10n.currencyDzd}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: cart.isEmpty
                        ? null
                        : () async {
                            await completeSale();
                            if (isMobileSheet && mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      l10n.posCompleteSale,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// شريط إحصائيات وإتمام البيع السفلي للموبايل
  Widget _buildMobileCartDockBar(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${cart.length} ${l10n.navProducts}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                '${formatPrice(total)} ${l10n.currencyDzd}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
              ),
            ],
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: cart.isEmpty
                ? null
                : () => _openMobileCartSheet(context),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(l10n.posCartTitle),
          ),
        ],
      ),
    );
  }
}