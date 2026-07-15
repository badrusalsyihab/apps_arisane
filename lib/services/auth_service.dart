import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'firestore_service.dart';

// Login pakai akun Google, sekaligus dipakai sebagai token akses
// ke Google Drive API (scope drive.file) untuk upload bukti transfer/foto grup.
// Web: pakai signInWithPopup (tidak butuh clientId).
// Mobile: pakai google_sign_in (butuh untuk Drive API access).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Hanya dipakai di mobile — Drive upload tidak support web (dart:io).
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    User? user;

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email');
      final result = await _auth.signInWithPopup(provider);
      user = result.user;
    } else {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      user = result.user;
    }

    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'platformRole': 'user',
      }, SetOptions(merge: true));

      await FirestoreService().resolvePendingInvites(
        user.uid,
        user.displayName ?? user.email ?? '',
        user.email ?? '',
      );
    }
    return user;
  }

  Future<void> signOut() async {
    if (!kIsWeb) await googleSignIn.signOut();
    await _auth.signOut();
  }
}
