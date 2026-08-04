import 'package:drift/drift.dart';
import '../../../core/database/base_table.dart';

class Payments extends BaseTable {
  TextColumn get customerId => text()();

  RealColumn get amount => real()();

  DateTimeColumn get paymentDate => dateTime()();

  TextColumn get paymentMethod => text()();

  TextColumn get notes => text().nullable()();
}