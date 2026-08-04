import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  const AppUserModel({
    required this.uid,
    required this.tenantId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  final String uid;
  final String tenantId;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  factory AppUserModel.fromFirestore(
    Map<String, dynamic> data,
    String uid,
  ) {
    return AppUserModel(
      uid: uid,
      tenantId: data['tenantId'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tenantId': tenantId,
      'fullName': fullName,
      'email': email,
      'role': role,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUserModel copyWith({
    String? uid,
    String? tenantId,
    String? fullName,
    String? email,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return AppUserModel(
      uid: uid ?? this.uid,
      tenantId: tenantId ?? this.tenantId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}