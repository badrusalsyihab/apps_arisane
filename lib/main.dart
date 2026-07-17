import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';
import 'screens/home_shell.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ArisanApp());
}

class ArisanApp extends StatelessWidget {
  const ArisanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arisan app',
      debugShowCheckedModeBanner: false,
      // Material 3 + layout adaptif otomatis mengikuti lebar layar,
      // jadi satu codebase ini jalan di Android, iOS, dan web (termasu mobile web).
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(onSignIn: auth.signInWithGoogle);
        }
        // Simpan/refresh device token FCM begitu user terdeteksi login,
        // supaya Cloud Function bisa kirim push notification asli ke device ini.
        PushNotificationService().initAndSaveToken(user.uid);

        // Cek platformRole di Firestore untuk tentukan tujuan setelah login.
        // Admin/Root dapat dashboard monitoring lintas grup, user biasa
        // dapat dashboard grup yang dia ikuti sendiri.
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userDocSnap) {
            if (!userDocSnap.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final data = userDocSnap.data!.data() as Map<String, dynamic>?;
            final platformRole = data?['platformRole'] ?? 'user';
            if (platformRole == 'admin') {
              return const AdminDashboardScreen();
            }
            return HomeShell(userId: user.uid);
          },
        );
      },
    );
  }
}
