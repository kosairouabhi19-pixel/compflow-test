import '../../../core/database/app_database.dart';
import '../database/products_dao.dart';

class ProductsRepository {
  const ProductsRepository(this._dao);

  final ProductsDao _dao;

  Stream<List<Product>> watchProducts() {
    return _dao.watchAllProducts();
  }

  Future<List<Product>> getProducts() {
    return _dao.getAllProducts();
  }

  Future<Product?> getProductById(String id) {
    return _dao.getProductById(id);
  }

  Future<void> addProduct(ProductsCompanion product) {
    return _dao.insertProduct(product);
  }

  Future<void> updateProduct(Product product) {
    return _dao.updateProduct(product);
  }

  Future<void> deleteProduct(String id) {
    return _dao.softDeleteProduct(id);
  }

  Future<List<Product>> searchProducts(String query) {
    return _dao.searchProducts(query);
  }
}