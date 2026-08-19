// lib/features/sales/database/sales_dao.dart
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_writer.dart';
import '../../products/database/products_table.dart';
import 'sale_items_table.dart';
import 'sales_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales, SaleItems, Products])
class SalesDao extends DatabaseAccessor<AppDatabase> with _$SalesDaoMixin {
  SalesDao(super.db, this.tenantId);

  final String tenantId;

  Future<List<Sale>> getAllSales() =>
      (select(sales)..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull())).get();

  Stream<List<Sale>> watchAllSales() =>
      (select(sales)..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull())).watch();

  Future<Sale?> getSaleById(String id) =>
      (select(sales)..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId) & t.deletedAt.isNull())).getSingleOrNull();

  Future<int> insertSale(SalesCompanion sale) async {
    final id = sale.id.value;
    if (id.isEmpty) throw StateError('A sale id is required before insertion.');
    final inserted = await into(sales).insert(sale.copyWith(tenantId: Value(tenantId)));
    await _enqueueSale(await (select(sales)..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId))).getSingle());
    return inserted;
  }

  Future<bool> updateSale(Sale sale) async {
    if (sale.tenantId != tenantId || sale.deletedAt != null) return false;
    final updated = await (update(sales)..where((t) => t.id.equals(sale.id) & t.tenantId.equals(tenantId))).write(sale);
    if (updated == 0) return false;
    await _enqueueSale(sale);
    return true;
  }

  Future<void> deleteSale(String id) async {
    await db.transaction(() async {
      final sale = await getSaleById(id);
      if (sale == null) return;
      final items = await (select(saleItems)..where((t) => t.saleId.equals(id) & t.tenantId.equals(tenantId))).get();
      final restored = <String, int>{};
      for (final item in items) {
        restored[item.productId] = (restored[item.productId] ?? 0) + item.quantity;
      }
      final changedProducts = <Product>[];
      for (final entry in restored.entries) {
        final product = await (select(products)..where((p) => p.id.equals(entry.key) & p.tenantId.equals(tenantId) & p.deletedAt.isNull())).getSingleOrNull();
        if (product != null) {
          final updated = product.copyWith(quantity: product.quantity + entry.value, updatedAt: DateTime.now().toUtc());
          await update(products).replace(updated);
          changedProducts.add(updated);
        }
      }
      await (delete(saleItems)..where((t) => t.saleId.equals(id) & t.tenantId.equals(tenantId))).go();
      await (delete(sales)..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId))).go();
      final writer = SyncQueueWriter(db);
      await writer.enqueueDelete(tenantId: tenantId, entityType: 'sale', entityId: sale.id);
      for (final item in items) {
        await writer.enqueueDelete(tenantId: tenantId, entityType: 'sale_item', entityId: item.id);
      }
      for (final product in changedProducts) await _enqueueProduct(product);
    });
  }

  Future<List<Sale>> searchSales(String query) =>
      (select(sales)..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull() & (t.invoiceNumber.like('%$query%') | t.notes.like('%$query%')))).get();

  Future<bool> completeSale({required Sale sale, required List<SaleItemsCompanion> items}) async {
    if (sale.id.isEmpty) throw ArgumentError('معرّف عملية البيع مطلوب');
    if (items.isEmpty) throw ArgumentError('يجب أن تحتوي عملية البيع على منتج واحد على الأقل');
    if (sale.total < 0) throw ArgumentError('إجمالي عملية البيع غير صالح');

    final requested = <String, int>{};
    for (final item in items) {
      if (item.id.value.isEmpty) throw ArgumentError('معرّف عنصر البيع مطلوب');
      if (item.quantity.value <= 0) throw ArgumentError('الكمية يجب أن تكون أكبر من صفر');
      if (item.unitPrice.value < 0 || item.total.value < 0) throw ArgumentError('سعر أو إجمالي العنصر غير صالح');
      requested[item.productId.value] = (requested[item.productId.value] ?? 0) + item.quantity.value;
    }

    final normalizedSale = sale.copyWith(tenantId: tenantId);

    return db.transaction(() async {
      final changedProducts = <Product>[];
      for (final entry in requested.entries) {
        final product = await (select(products)..where((p) => p.id.equals(entry.key) & p.tenantId.equals(tenantId) & p.deletedAt.isNull())).getSingleOrNull();
        if (product == null) throw Exception('المنتج غير موجود');
        if (product.quantity < entry.value) throw Exception('المخزون غير كافٍ للمنتج: ${product.name}');
      }
      await into(sales).insert(normalizedSale);
      for (final item in items) await into(saleItems).insert(item.copyWith(tenantId: Value(tenantId)));
      for (final entry in requested.entries) {
        final product = await (select(products)..where((p) => p.id.equals(entry.key) & p.tenantId.equals(tenantId) & p.deletedAt.isNull())).getSingle();
        final updated = product.copyWith(quantity: product.quantity - entry.value, updatedAt: DateTime.now().toUtc());
        await update(products).replace(updated);
        changedProducts.add(updated);
      }
      final persistedSale = await (select(sales)..where((t) => t.id.equals(normalizedSale.id) & t.tenantId.equals(tenantId))).getSingle();
      final persistedItems = await (select(saleItems)..where((t) => t.saleId.equals(normalizedSale.id) & t.tenantId.equals(tenantId))).get();
      await _enqueueSale(persistedSale);
      for (final item in persistedItems) await _enqueueSaleItem(item);
      for (final product in changedProducts) await _enqueueProduct(product);
      return true;
    });
  }

  Future<void> _enqueueSale(Sale sale) => SyncQueueWriter(db).enqueueUpsert(
        tenantId: tenantId,
        entityType: 'sale',
        entityId: sale.id,
        payload: {
          'id': sale.id,
          'tenantId': sale.tenantId,
          'createdAt': sale.createdAt.toUtc().toIso8601String(),
          'updatedAt': sale.updatedAt.toUtc().toIso8601String(),
          'deletedAt': sale.deletedAt?.toUtc().toIso8601String(),
          'version': sale.version,
          'syncStatus': sale.syncStatus,
          'deviceId': sale.deviceId,
          'customerId': sale.customerId,
          'invoiceNumber': sale.invoiceNumber,
          'total': sale.total,
          'saleDate': sale.saleDate.toUtc().toIso8601String(),
          'notes': sale.notes,
        },
      );

  Future<void> _enqueueSaleItem(SaleItem item) => SyncQueueWriter(db).enqueueUpsert(
        tenantId: tenantId,
        entityType: 'sale_item',
        entityId: item.id,
        payload: {
          'id': item.id,
          'tenantId': item.tenantId,
          'createdAt': item.createdAt.toUtc().toIso8601String(),
          'updatedAt': item.updatedAt.toUtc().toIso8601String(),
          'deletedAt': item.deletedAt?.toUtc().toIso8601String(),
          'version': item.version,
          'syncStatus': item.syncStatus,
          'deviceId': item.deviceId,
          'saleId': item.saleId,
          'productId': item.productId,
          'quantity': item.quantity,
          'unitPrice': item.unitPrice,
          'total': item.total,
        },
      );

  Future<void> _enqueueProduct(Product product) => SyncQueueWriter(db).enqueueUpsert(
        tenantId: tenantId,
        entityType: 'product',
        entityId: product.id,
        payload: {
          'id': product.id,
          'tenantId': product.tenantId,
          'createdAt': product.createdAt.toUtc().toIso8601String(),
          'updatedAt': product.updatedAt.toUtc().toIso8601String(),
          'deletedAt': product.deletedAt?.toUtc().toIso8601String(),
          'version': product.version,
          'syncStatus': product.syncStatus,
          'deviceId': product.deviceId,
          'name': product.name,
          'sku': product.sku,
          'barcode': product.barcode,
          'purchasePrice': product.purchasePrice,
          'sellingPrice': product.sellingPrice,
          'quantity': product.quantity,
          'minimumQuantity': product.minimumQuantity,
          'categoryId': product.categoryId,
          'isActive': product.isActive,
        },
      );
}
