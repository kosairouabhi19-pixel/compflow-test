// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchases_dao.dart';

// ignore_for_file: type=lint
mixin _$PurchasesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PurchasesTable get purchases => attachedDatabase.purchases;
  PurchasesDaoManager get managers => PurchasesDaoManager(this);
}

class PurchasesDaoManager {
  final _$PurchasesDaoMixin _db;
  PurchasesDaoManager(this._db);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db.attachedDatabase, _db.purchases);
}
