import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Simpan device token FCM di users/{uid}.fcmToken supaya Cloud Function
// (lihat functions/index.js) bisa kirim push notification asli, bukan cuma
// tulis dokumen di collection `notifications` yang cuma muncul saat app terbuka.
class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> initAndSaveToken(String userId) async {
    // Minta izin notifikasi (wajib di iOS, opsional tapi disarankan di Android 13+/web).
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(userId, token);
    }

    // Token bisa berubah (reinstall app, dsb) -> selalu update kalau berubah.
    _messaging.onTokenRefresh.listen((newToken) => _saveToken(userId, newToken));
  }

  Future<void> _saveToken(String userId, String token) {
    return FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }

  // Panggil saat logout supaya device ini tidak lagi terima push untuk akun tersebut.
  Future<void> clearToken(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).set(
      {'fcmToken': FieldValue.delete()},
      SetOptions(merge: true),
    );
  }
}
