import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user_model.dart';

class DeviceSessionService {
  DeviceSessionService(this._prefs, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _deviceIdKey = 'compflow_device_id';
  static const _sessionTimeout = Duration(minutes: 10);

  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  String get _deviceId {
    final existing = _prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _uuid.v4();
    _prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  String get _platform {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  CollectionReference<Map<String, dynamic>> _sessions(String uid) {
    return _firestore.collection('users').doc(uid).collection('sessions');
  }

  Future<void> acquire(AppUserModel user) async {
    final sessions = _sessions(user.uid);
    final snapshot = await sessions.get();
    final staleBefore = DateTime.now().subtract(_sessionTimeout);
    final activeSessions = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    for (final doc in snapshot.docs) {
      final lastSeen = (doc.data()['lastSeenAt'] as Timestamp?)?.toDate();
      if (lastSeen == null || lastSeen.isBefore(staleBefore)) {
        await doc.reference.delete();
      } else {
        activeSessions.add(doc);
      }
    }

    final alreadyActive = activeSessions.any((doc) => doc.id == _deviceId);
    final maxDevices = user.role == 'owner' ? 2 : 1;

    if (!alreadyActive && activeSessions.length >= maxDevices) {
      throw DeviceLimitException(maxDevices);
    }

    await sessions.doc(_deviceId).set({
      'deviceId': _deviceId,
      'platform': _platform,
      'lastSeenAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> heartbeat(String uid) async {
    await _sessions(uid).doc(_deviceId).set({
      'deviceId': _deviceId,
      'platform': _platform,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> release(String uid) async {
    await _sessions(uid).doc(_deviceId).delete();
  }
}

class DeviceLimitException implements Exception {
  DeviceLimitException(this.maxDevices);

  final int maxDevices;

  @override
  String toString() =>
      'تم الوصول إلى الحد الأقصى للأجهزة المسموحة لهذا الحساب: $maxDevices.';
}
