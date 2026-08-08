import 'package:drift/drift.dart';
import '../../../core/database/base_table.dart';

class SaleItems extends BaseTable {
  TextColumn get saleId => text()();

  TextColumn get productId => text()();

  IntColumn get quantity => integer()();

  RealColumn get unitPrice => real()();

  RealColumn get total => real()();
}