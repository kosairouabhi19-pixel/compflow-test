import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_repository.dart';
import 'products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db, this.tenantId);

  final String tenantId;
  final Uuid _uuid = const Uuid();

  Future<List<Product>> getAllProducts() {
    return (select(products)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .get();
  }

  Stream<List<Product>> watchAllProducts() {
    return (select(products)
          ..where((t) => t.tenantId.equals(tenantId) & t.deletedAt.isNull()))
        .watch();
  }

  Future<Product?> getProductById(String id) {
    return (select(products)
          ..where((t) =>
              t.id.equals(id) &
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  Future<int> insertProduct(ProductsCompanion product) async {
    final id = product.id.value;
    if (id.isEmpty) {
      throw StateError('A product id is required before insertion.');
    }

    final inserted = await into(products).insert(
      product.copyWith(tenantId: Value(tenantId)),
    );

    final created = await (select(products)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .getSingle();
    await _enqueueUpsert(created);
    return inserted;
  }

  Future<bool> updateProduct(Product product) async {
    if (product.tenantId != tenantId || product.deletedAt != null) {
      return false;
    }

    final updated = await (update(products)
          ..where((t) => t.id.equals(product.id) & t.tenantId.equals(tenantId)))
        .write(product);

    if (updated == 0) {
      return false;
    }

    await _enqueueUpsert(product);
    return true;
  }

  Future<int> softDeleteProduct(String id) async {
    final now = DateTime.now().toUtc();
    final affected = await (update(products)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(ProductsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
        ));

    if (affected > 0) {
      final deleted = await (select(products)
            ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
          .getSingleOrNull();
      if (deleted != null) {
        await _enqueueUpsert(deleted);
      }
    }

    return affected;
  }

  Future<List<Product>> searchProducts(String query) {
    return (select(products)
          ..where((t) =>
              t.tenantId.equals(tenantId) &
              t.deletedAt.isNull() &
              t.name.like('%$query%')))
        .get();
  }

  Future<bool> decreaseStock(
    String productId,
    int quantity,
  ) async {
    final product = await getProductById(productId);

    if (product == null || product.quantity < quantity) {
      return false;
    }

    final updated = product.copyWith(
      quantity: product.quantity - quantity,
      updatedAt: DateTime.now().toUtc(),
    );

    return updateProduct(updated);
  }

  Future<void> _enqueueUpsert(Product product) async {
    final queue = SyncQueueRepository(db);
    await queue.enqueue(
      id: _uuid.v4(),
      tenantId: tenantId,
      entityType: 'product',
      entityId: product.id,
      operationType: 'upsert',
      payload: _productPayload(product),
    );
  }

  Map<String, dynamic> _productPayload(Product product) {
    return {
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
    };
  }
}
