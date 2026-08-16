import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UsersRepository {
  UsersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<UserModel>> watchUsers(String tenantId) {
    return _firestore
        .collection('users')
        .where('tenantId', isEqualTo: tenantId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => UserModel(
                  uid: doc.id,
                  tenantId: doc.data()['tenantId'] as String? ?? '',
                  fullName: doc.data()['fullName'] as String? ?? '',
                  email: doc.data()['email'] as String? ?? '',
                  role: doc.data()['role'] as String? ?? '',
                  isActive: doc.data()['isActive'] as bool? ?? false,
                  createdAt:
                      (doc.data()['createdAt'] as Timestamp?)?.toDate() ??
                          DateTime.now(),
                ),
              )
              .toList(),
        );
  }

  Future<void> updateUser(UserModel user) {
    return _firestore
        .collection('users')
        .doc(user.uid)
        .update(user.toFirestore());
  }

  Future<void> deleteUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .delete();
  }
}