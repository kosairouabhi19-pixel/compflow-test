// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sale_items_dao.dart';

// ignore_for_file: type=lint
mixin _$SaleItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SaleItemsTable get saleItems => attachedDatabase.saleItems;
  SaleItemsDaoManager get managers => SaleItemsDaoManager(this);
}

class SaleItemsDaoManager {
  final _$SaleItemsDaoMixin _db;
  SaleItemsDaoManager(this._db);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db.attachedDatabase, _db.saleItems);
}
