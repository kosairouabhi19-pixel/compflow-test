import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db, this.tenantId);

  final String tenantId;

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

  Future<int> insertProduct(ProductsCompanion product) {
    return into(products).insert(product.copyWith(tenantId: Value(tenantId)));
  }

  Future<bool> updateProduct(Product product) {
    if (product.tenantId != tenantId || product.deletedAt != null) {
      return Future.value(false);
    }
    return (update(products)
          ..where((t) => t.id.equals(product.id) & t.tenantId.equals(tenantId)))
        .write(product);
  }

  Future<int> softDeleteProduct(String id) {
    return (update(products)
          ..where((t) => t.id.equals(id) & t.tenantId.equals(tenantId)))
        .write(ProductsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
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
      updatedAt: DateTime.now(),
    );

    return updateProduct(updated);
  }
}