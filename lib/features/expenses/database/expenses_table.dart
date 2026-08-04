import 'package:drift/drift.dart';
import '../../../core/database/base_table.dart';

class Expenses extends BaseTable {
  TextColumn get title => text()();

  RealColumn get amount => real()();

  DateTimeColumn get expenseDate => dateTime()();

  TextColumn get category => text().nullable()();

  TextColumn get notes => text().nullable()();
}