import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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

  final TextEditingController _searchController =
      TextEditingController();

  final Uuid _uuid = const Uuid();

  static const String _tenantId =
      '11111111-1111-1111-1111-111111111111';

  static const String _deviceId = 'windows';

  String _searchQuery = '';

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
    if (product.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المنتج غير متوفر في المخزون'),
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
            const SnackBar(
              content: Text('لا يمكن تجاوز كمية المخزون'),
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
    final item = cart[index];

    if (item.quantity >= item.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن تجاوز كمية المخزون'),
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

  Future<void> completeSale() async {
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
        invoiceNumber:
            'INV-${now.millisecondsSinceEpoch}',
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
        const SnackBar(
          content: Text('تم إتمام البيع بنجاح'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إتمام البيع: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);

    return productsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text(
          'حدث خطأ في تحميل المنتجات',
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      ),
      data: (products) {
        final query = _searchQuery.trim().toLowerCase();

        final filteredProducts = query.isEmpty
            ? products
            : products.where((product) {
                final name = product.name.toLowerCase();
                final sku = product.sku.toLowerCase();
                final barcode =
                    product.barcode?.toLowerCase() ?? '';

                return name.contains(query) ||
                    sku.contains(query) ||
                    barcode.contains(query);
              }).toList();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // =========================
              // المنتجات
              // =========================
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'ابحث باسم المنتج أو الباركود أو SKU...',
                        prefixIcon:
                            const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(
                              child: Text(
                                'لا توجد منتجات',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : GridView.builder(
                              itemCount:
                                  filteredProducts.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: .85,
                              ),
                              itemBuilder:
                                  (context, index) {
                                final product =
                                    filteredProducts[index];

                                return ProductCard(
                                  name: product.name,
                                  price: formatPrice(
                                    product.sellingPrice,
                                  ),
                                  stock:
                                      'Stock: ${product.quantity}',
                                  onTap: () =>
                                      addToCart(product),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // =========================
              // السلة
              // =========================
              Container(
                width: 340,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    const Text(
                      'Shopping Cart',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Divider(),

                    Expanded(
                      child: cart.isEmpty
                          ? const Center(
                              child: Text(
                                'السلة فارغة',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: cart.length,
                              itemBuilder:
                                  (context, index) {
                                final item =
                                    cart[index];

                                return Card(
                                  margin:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets
                                            .all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          item.name,
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Text(
                                          '${formatPrice(item.price)} DA / وحدة',
                                          style:
                                              TextStyle(
                                            color: Colors
                                                .grey
                                                .shade600,
                                            fontSize: 12,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 8,
                                        ),

                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () =>
                                                  decreaseQuantity(
                                                index,
                                              ),
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .remove_circle_outline,
                                              ),
                                            ),

                                            Text(
                                              '${item.quantity}',
                                              style:
                                                  const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                                fontSize: 16,
                                              ),
                                            ),

                                            IconButton(
                                              onPressed: () =>
                                                  increaseQuantity(
                                                index,
                                              ),
                                              icon:
                                                  const Icon(
                                                Icons
                                                    .add_circle_outline,
                                              ),
                                            ),

                                            const Spacer(),

                                            Text(
                                              '${formatPrice(item.totalPrice)} DA',
                                              style:
                                                  const TextStyle(
                                                color:
                                                    Colors.teal,
                                                fontWeight:
                                                    FontWeight
                                                        .bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    const Divider(),

                    Padding(
                      padding:
                          const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),

                              Text(
                                '${formatPrice(total)} DA',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FilledButton(
                              onPressed: cart.isEmpty
                                  ? null
                                  : completeSale,
                              child: const Text(
                                'Complete Sale',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}