// lib/features/sales/database/sales_dao.dart
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../products/database/products_table.dart';
import 'sale_items_table.dart';
import 'sales_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(
  tables: [
    Sales,
    SaleItems,
    Products,
  ],
)
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db, this.tenantId);

  final String tenantId;

  Future<List<Sale>> getAllSales() {
    return (select(sales)
          ..where((t) =>
              t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .get();
  }

  Stream<List<Sale>> watchAllSales() {
    return (select(sales)
          ..where((t) =>
              t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<Sale?> getSaleById(String id) {
    return (select(sales)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> insertSale(SalesCompanion sale) {
    return into(sales).insert(sale.copyWith(tenantId: Value(tenantId)));
  }

  Future<bool> updateSale(Sale sale) {
    if (sale.tenantId != tenantId || sale.deletedAt != null) {
      return Future.value(false);
    }
    return (update(sales)
          ..where((t) => t.id.equals(sale.id) & t.tenantId.equals(tenantId)))
        .write(sale);
  }

  Future<void> deleteSale(String id) async {
    await db.transaction(() async {
      final sale = await getSaleById(id);
      if (sale == null) return;

      final List<SaleItem> items = await (select(saleItems)
            ..where((t) =>
                t.saleId.equals(id) & t.tenantId.equals(tenantId)))
          .get();

      final Map<String, int> restoredQuantityByProduct = {};
      for (final item in items) {
        restoredQuantityByProduct[item.productId] =
            (restoredQuantityByProduct[item.productId] ?? 0) + item.quantity;
      }

      for (final entry in restoredQuantityByProduct.entries) {
        final product = await (select(products)
              ..where((p) =>
                  p.id.equals(entry.key) &
                  p.tenantId.equals(tenantId) &
                  p.deletedAt.isNull()))
            .getSingleOrNull();

        if (product != null) {
          await update(products).replace(
            product.copyWith(
              quantity: product.quantity + entry.value,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      await (delete(saleItems)
            ..where((t) =>
                t.saleId.equals(id) & t.tenantId.equals(tenantId)))
          .go();
      await (delete(sales)
            ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
          .go();
    });
  }

  Future<List<Sale>> searchSales(String query) {
    return (select(sales)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              (t.invoiceNumber.like('%$query%') |
                  t.notes.like('%$query%'))))
        .get();
  }

  Future<bool> completeSale({
    required Sale sale,
    required List<SaleItemsCompanion> items,
  }) async {
    if (sale.tenantId != tenantId) {
      throw ArgumentError('عملية البيع لا تنتمي إلى المتجر الحالي');
    }

    if (items.isEmpty) {
      throw ArgumentError('يجب أن تحتوي عملية البيع على منتج واحد على الأقل');
    }

    if (sale.total < 0) {
      throw ArgumentError('إجمالي عملية البيع غير صالح');
    }

    final Map<String, int> requestedQuantityByProduct = {};
    for (final item in items) {
      final int quantity = item.quantity.value;
      final double unitPrice = item.unitPrice.value;
      final double total = item.total.value;

      if (item.tenantId.value != tenantId) {
        throw ArgumentError('عنصر البيع لا ينتمي إلى المتجر الحالي');
      }
      if (quantity <= 0) {
        throw ArgumentError('الكمية يجب أن تكون أكبر من صفر');
      }
      if (unitPrice < 0 || total < 0) {
        throw ArgumentError('سعر أو إجمالي العنصر غير صالح');
      }

      final String productId = item.productId.value;
      requestedQuantityByProduct[productId] =
          (requestedQuantityByProduct[productId] ?? 0) + quantity;
    }

    return db.transaction(() async {
      for (final entry in requestedQuantityByProduct.entries) {
        final product = await (select(products)
              ..where((p) =>
                  p.id.equals(entry.key) &
                  p.tenantId.equals(tenantId) &
                  p.deletedAt.isNull()))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('المنتج غير موجود');
        }

        if (product.quantity < entry.value) {
          throw Exception('المخزون غير كافٍ للمنتج: ${product.name}');
        }
      }

      await into(sales).insert(sale.copyWith(tenantId: tenantId));

      for (final item in items) {
        await into(saleItems).insert(
          item.copyWith(tenantId: Value(tenantId)),
        );
      }

      for (final entry in requestedQuantityByProduct.entries) {
        final product = await (select(products)
              ..where((p) =>
                  p.id.equals(entry.key) &
                  p.tenantId.equals(tenantId) &
                  p.deletedAt.isNull()))
            .getSingle();

        await update(products).replace(
          product.copyWith(
            quantity: product.quantity - entry.value,
            updatedAt: DateTime.now(),
          ),
        );
      }

      return true;
    });
  }
}
