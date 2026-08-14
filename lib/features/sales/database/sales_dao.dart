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
  SalesDao(super.db);

  Future<List<Sale>> getAllSales() {
    return select(sales).get();
  }

  Stream<List<Sale>> watchAllSales() {
    return select(sales).watch();
  }

  Future<Sale?> getSaleById(String id) {
    return (select(sales)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertSale(SalesCompanion sale) {
    return into(sales).insert(sale);
  }

  Future<bool> updateSale(Sale sale) {
    return update(sales).replace(sale);
  }

  /// يحذف عملية بيع مع كل عناصرها (SaleItems) المرتبطة بها، ويعيد الكمية
  /// التي خُصمت من المخزون عند إنشاء البيع لكل منتج، داخل transaction واحدة
  /// حفاظاً على تطابق البيانات بين Sales وSaleItems وProducts.
  Future<void> deleteSale(String id) async {
    await db.transaction(() async {
      final List<SaleItem> items = await (select(saleItems)
            ..where((t) => t.saleId.equals(id)))
          .get();

      // تجميع الكمية المُعادة لكل منتج (في حال تكرر نفس المنتج في الفاتورة)
      final Map<String, int> restoredQuantityByProduct = {};
      for (final item in items) {
        restoredQuantityByProduct[item.productId] =
            (restoredQuantityByProduct[item.productId] ?? 0) + item.quantity;
      }

      for (final entry in restoredQuantityByProduct.entries) {
        final product = await (select(products)
              ..where((p) => p.id.equals(entry.key)))
            .getSingleOrNull();

        // إن كان المنتج نفسه محذوفاً مسبقاً، تُتجاهل إعادة مخزونه فقط دون
        // إيقاف حذف الفاتورة.
        if (product != null) {
          await update(products).replace(
            product.copyWith(
              quantity: product.quantity + entry.value,
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      await (delete(saleItems)..where((t) => t.saleId.equals(id))).go();
      await (delete(sales)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<List<Sale>> searchSales(String query) {
    return (select(sales)
          ..where(
            (t) =>
                t.invoiceNumber.like('%$query%') | t.notes.like('%$query%'),
          ))
        .get();
  }

  /// ينفّذ عملية بيع كاملة داخل transaction واحدة:
  /// 1. تجميع الكمية الإجمالية المطلوبة لكل منتج (حتى لو تكرر نفس المنتج
  ///    ضمن نفس الفاتورة) والتحقق من صحة كل عنصر.
  /// 2. التحقق من كفاية المخزون لكل منتج.
  /// 3. تسجيل عملية البيع (Sale).
  /// 4. تسجيل عناصر البيع (SaleItems) كما وردت، سطراً سطراً.
  /// 5. خصم الكميات المباعة من المنتجات (Products).
  /// عند فشل أي خطوة تُلغى العملية بالكامل (rollback) تلقائياً عبر Drift.
  Future<bool> completeSale({
    required Sale sale,
    required List<SaleItemsCompanion> items,
  }) async {
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
      // التأكد من المخزون قبل تسجيل أي شيء، بناءً على الكمية الإجمالية
      // المطلوبة من كل منتج.
      for (final entry in requestedQuantityByProduct.entries) {
        final product = await (select(products)
              ..where((p) => p.id.equals(entry.key)))
            .getSingleOrNull();

        if (product == null) {
          throw Exception('المنتج غير موجود');
        }

        if (product.quantity < entry.value) {
          throw Exception('المخزون غير كافٍ للمنتج: ${product.name}');
        }
      }

      // تسجيل عملية البيع
      await into(sales).insert(sale);

      // تسجيل كل عنصر من عناصر الفاتورة كما هو (بدون دمج) للحفاظ على
      // السجل الفعلي لكل سطر بيع.
      for (final item in items) {
        await into(saleItems).insert(item);
      }

      // خصم المخزون بالكمية الإجمالية المجمّعة لكل منتج
      for (final entry in requestedQuantityByProduct.entries) {
        final product = await (select(products)
              ..where((p) => p.id.equals(entry.key)))
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