import 'package:drift/drift.dart';
import '../../../core/database/base_table.dart';

class Inventory extends BaseTable {
  TextColumn get productId => text()();

  IntColumn get quantity => integer().withDefault(const Constant(0))();

  IntColumn get reservedQuantity =>
      integer().withDefault(const Constant(0))();

  IntColumn get minimumQuantity =>
      integer().withDefault(const Constant(0))();

  TextColumn get warehouse => text().nullable()();
}