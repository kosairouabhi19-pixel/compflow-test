import '../../../core/database/app_database.dart';
import '../database/sales_dao.dart';

class SalesRepository {
  final SalesDao _dao;

  SalesRepository(this._dao);

  Stream<List<Sale>> watchAllSales() {
    return _dao.watchAllSales();
  }

  Future<List<Sale>> getAllSales() {
    return _dao.getAllSales();
  }

  Future<Sale?> getSaleById(String id) {
    return _dao.getSaleById(id);
  }

  Future<int> insertSale(SalesCompanion sale) {
    return _dao.insertSale(sale);
  }

  Future<bool> updateSale(Sale sale) {
    return _dao.updateSale(sale);
  }

  Future<int> deleteSale(String id) {
    return _dao.deleteSale(id);
  }
}