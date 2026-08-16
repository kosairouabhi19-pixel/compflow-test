import '../../auth/models/app_user_model.dart';

class UserModel extends AppUserModel {
  const UserModel({
    required super.uid,
    required super.tenantId,
    required super.fullName,
    required super.email,
    required super.role,
    required super.isActive,
    required super.createdAt,
  });

  factory UserModel.fromAppUser(AppUserModel user) {
    return UserModel(
      uid: user.uid,
      tenantId: user.tenantId,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      isActive: user.isActive,
      createdAt: user.createdAt,
    );
  }
}