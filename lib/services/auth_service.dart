import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

// Login pakai akun Google, sekaligus dipakai sebagai token akses
// ke Google Drive API (scope drive.file) untuk upload bukti transfer/foto grup.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // user batal login

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;

    if (user != null) {
      // Buat/update dokumen user di Firestore kalau baru pertama login
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL,
        'platformRole': 'user',
      }, SetOptions(merge: true));

      // Cek apakah email ini punya undangan tertunda (di-invite sebelum
      // pernah login) -> otomatis masuk ke grup yang mengundangnya.
      await FirestoreService().resolvePendingInvites(
        user.uid,
        user.displayName ?? user.email ?? '',
        user.email ?? '',
      );
    }
    return user;
  }

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await _auth.signOut();
  }
}
