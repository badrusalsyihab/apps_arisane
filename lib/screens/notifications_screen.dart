import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';

// Sesuai wireframe "notifikasi_reminder_anggota": tiga jenis reminder
// (H-3/H-1 otomatis, lewat jatuh tempo otomatis, manual dari Sekretaris)
// tampil dalam satu daftar, dibedakan lewat warna ikon berdasarkan `source`.
class NotificationsScreen extends StatelessWidget {
  final String userId;
  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: StreamBuilder<List<AppNotification>>(
        stream: firestore.myNotifications(userId),
        builder: (context, snapshot) {
          final notifs = snapshot.data ?? [];
          if (notifs.isEmpty) {
            return const Center(child: Text('Belum ada notifikasi.'));
          }
          return ListView.builder(
            itemCount: notifs.length,
            itemBuilder: (context, i) {
              final n = notifs[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _colorFor(n.source).withValues(alpha: 0.15),
                  child: Icon(Icons.notifications, color: _colorFor(n.source)),
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.w600)),
                subtitle: Text(n.body),
                trailing: Text(_relativeTime(n.createdAt), style: Theme.of(context).textTheme.bodySmall),
                onTap: () => firestore.markNotificationRead(n.id),
              );
            },
          );
        },
      ),
    );
  }

  Color _colorFor(String source) {
    switch (source) {
      case 'auto_telat':
        return Colors.red;
      case 'auto_h1':
        return Colors.orange;
      case 'auto_h3':
        return Colors.amber;
      default:
        return Colors.blue; // manual dari sekretaris
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
