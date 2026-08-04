import 'package:drift/drift.dart';
import '../../../core/database/base_table.dart';

class Purchases extends BaseTable {
  TextColumn get supplierId => text()();

  TextColumn get invoiceNumber => text()();

  RealColumn get total => real()();

  DateTimeColumn get purchaseDate => dateTime()();

  TextColumn get notes => text().nullable()();
}