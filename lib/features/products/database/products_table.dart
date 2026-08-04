import 'package:drift/drift.dart';

import '../../../core/database/base_table.dart';

class Products extends BaseTable {
  TextColumn get name => text()();

  TextColumn get sku => text()();

  TextColumn get barcode => text().nullable()();

  RealColumn get purchasePrice => real()();

  RealColumn get sellingPrice => real()();

  IntColumn get quantity => integer().withDefault(const Constant(0))();

  IntColumn get minimumQuantity => integer().withDefault(const Constant(0))();

  TextColumn get categoryId => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}