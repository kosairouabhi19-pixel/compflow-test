import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'sales_table.dart';

part 'sales_dao.g.dart';

@DriftAccessor(tables: [Sales])
class SalesDao extends DatabaseAccessor<AppDatabase>
    with _$SalesDaoMixin {
  SalesDao(super.db);

  Future<List<Sale>> getAllSales() {
    return select(sales).get();
  }

  Stream<List<Sale>> watchAllSales() {
    return select(sales).watch();
  }

  Future<Sale?> getSaleById(String id) {
    return (select(sales)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertSale(SalesCompanion sale) {
    return into(sales).insert(sale);
  }

  Future<bool> updateSale(Sale sale) {
    return update(sales).replace(sale);
  }

  Future<int> deleteSale(String id) {
    return (delete(sales)..where((t) => t.id.equals(id))).go();
  }
}