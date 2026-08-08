import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'products_table.dart';

part 'products_dao.g.dart';

@DriftAccessor(tables: [Products])
class ProductsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductsDaoMixin {
  ProductsDao(super.db);

  Future<List<Product>> getAllProducts() {
    return select(products).get();
  }

  Stream<List<Product>> watchAllProducts() {
    return select(products).watch();
  }

  Future<Product?> getProductById(String id) {
    return (select(products)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  Future<bool> updateProduct(Product product) {
    return update(products).replace(product);
  }

  Future<int> softDeleteProduct(String id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Product>> searchProducts(String query) {
    return (select(products)
          ..where((t) => t.name.like('%$query%')))
        .get();
  }

  Future<bool> decreaseStock(
    String productId,
    int quantity,
  ) async {
    final product = await getProductById(productId);

    if (product == null) {
      return false;
    }

    if (product.quantity < quantity) {
      return false;
    }

    final updated = product.copyWith(
      quantity: product.quantity - quantity,
    );

    return updateProduct(updated);
  }
}