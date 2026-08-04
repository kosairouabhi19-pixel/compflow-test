import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  const ProductModel({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.sku,
    this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.minimumQuantity,
    this.categoryId,
    required this.isActive,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.syncStatus,
    required this.deviceId,
  });

  final String id;
  final String tenantId;

  final String name;
  final String sku;
  final String? barcode;

  final double purchasePrice;
  final double sellingPrice;

  final int quantity;
  final int minimumQuantity;

  final String? categoryId;

  final bool isActive;

  final int version;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  final String syncStatus;
  final String deviceId;

  ProductModel copyWith({
    String? id,
    String? tenantId,
    String? name,
    String? sku,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    int? minimumQuantity,
    String? categoryId,
    bool? isActive,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? syncStatus,
    String? deviceId,
  }) {
    return ProductModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      minimumQuantity: minimumQuantity ?? this.minimumQuantity,
      categoryId: categoryId ?? this.categoryId,
      isActive: isActive ?? this.isActive,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        name,
        sku,
        barcode,
        purchasePrice,
        sellingPrice,
        quantity,
        minimumQuantity,
        categoryId,
        isActive,
        version,
        createdAt,
        updatedAt,
        deletedAt,
        syncStatus,
        deviceId,
      ];
}