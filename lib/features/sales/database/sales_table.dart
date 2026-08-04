import 'package:drift/drift.dart';
import '../../../core/database/base_table.dart';

class Sales extends BaseTable {
  TextColumn get customerId => text()();

  TextColumn get invoiceNumber => text()();

  RealColumn get total => real()();

  DateTimeColumn get saleDate => dateTime()();

  TextColumn get notes => text().nullable()();
}