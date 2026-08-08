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

  Future<List<Sale>> searchSales(String query) {
    return (select(sales)
          ..where(
            (t) =>
                t.invoiceNumber.like('%$query%') |
                t.notes.like('%$query%'),
          ))
        .get();
  }

  Future<bool> completeSale({
    required Sale sale,
    required List<SaleItemsCompanion> items,
  }) async {
    return db.transaction(() async {
      // التأكد من المخزون قبل تسجيل أي شيء
      for (final item in items) {
        final product = await (select(products)
              ..where(
                (p) => p.id.equals(item.productId.value),
              ))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('المنتج غير موجود');
        }

        if (product.quantity < item.quantity.value) {
          throw Exception(
            'المخزون غير كافٍ للمنتج: ${product.name}',
          );
        }
      }

      // تسجيل عملية البيع
      await into(sales).insert(sale);

      // تسجيل المنتجات المباعة + خصم المخزون
      for (final item in items) {
        await into(saleItems).insert(item);

        final product = await (select(products)
              ..where(
                (p) => p.id.equals(item.productId.value),
              ))
            .getSingle();

        await update(products).replace(
          product.copyWith(
            quantity:
                product.quantity - item.quantity.value,
            updatedAt: DateTime.now(),
          ),
        );
      }

      return true;
    });
  }
}