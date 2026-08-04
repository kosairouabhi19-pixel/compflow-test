import 'package:drift/drift.dart';
import '../../../core/database/base_table.dart';

class Invoices extends BaseTable {
  TextColumn get customerId => text()();

  TextColumn get invoiceNumber => text()();

  RealColumn get total => real()();

  RealColumn get paid => real().withDefault(const Constant(0))();

  RealColumn get remaining => real()();

  DateTimeColumn get invoiceDate => dateTime()();

  TextColumn get status =>
      text().withDefault(const Constant('unpaid'))();
}