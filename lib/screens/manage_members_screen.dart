import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../models/pending_invite_model.dart';
import '../services/firestore_service.dart';

// Khusus diakses oleh Ketua. Fitur: invite anggota baru via email (termasuk
// yang belum pernah pakai app -> masuk daftar pending, auto-resolve saat
// mereka login pertama kali), assign role Sekretaris, dan tandai anggota
// keluar/mengundurkan diri (dengan catatan wajib, penanganan fleksibel/manual).
class ManageMembersScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  const ManageMembersScreen({super.key, required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola anggota')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, firestore),
        icon: const Icon(Icons.person_add),
        label: const Text('Undang anggota'),
      ),
      body: StreamBuilder<List<GroupMember>>(
        stream: firestore.groupMembers(groupId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final members = snapshot.data!;

          return StreamBuilder<List<PendingInvite>>(
            stream: firestore.pendingInvitesForGroup(groupId),
            builder: (context, pendingSnap) {
              final pending = pendingSnap.data ?? [];

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Anggota aktif', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...members.map((m) => Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(m.userName.isNotEmpty ? m.userName[0] : '?')),
                          title: Text(m.userName),
                          subtitle: Text(
                            m.status == MemberStatus.keluar
                                ? 'Keluar${m.exitNote != null ? ' \u2014 ${m.exitNote}' : ''}'
                                : m.role.name,
                          ),
                          trailing: m.status == MemberStatus.keluar
                              ? null
                              : PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'jadikan_sekretaris') {
                                      firestore.setMemberRole(m.id, MemberRole.sekretaris);
                                    } else if (value == 'jadikan_anggota') {
                                      firestore.setMemberRole(m.id, MemberRole.anggota);
                                    } else if (value == 'keluarkan') {
                                      _showExitDialog(context, firestore, m);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (m.role != MemberRole.sekretaris)
                                      const PopupMenuItem(
                                        value: 'jadikan_sekretaris',
                                        child: Text('Jadikan Sekretaris'),
                                      ),
                                    if (m.role == MemberRole.sekretaris)
                                      const PopupMenuItem(
                                        value: 'jadikan_anggota',
                                        child: Text('Jadikan anggota biasa'),
                                      ),
                                    if (m.role != MemberRole.ketua)
                                      const PopupMenuItem(
                                        value: 'keluarkan',
                                        child: Text('Tandai keluar/mengundurkan diri'),
                                      ),
                                  ],
                                ),
                        ),
                      )),
                  if (pending.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Menunggu (belum pernah login)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...pending.map((p) => Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.hourglass_empty)),
                            title: Text(p.email),
                            subtitle: const Text('Otomatis masuk grup begitu login pertama kali'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: 'Batalkan undangan',
                              onPressed: () => firestore.cancelPendingInvite(p.id),
                            ),
                          ),
                        )),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showInviteDialog(BuildContext context, FirestoreService firestore) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undang anggota'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email anggota',
            helperText: 'Kalau belum pernah pakai app, otomatis masuk grup saat dia login pertama kali',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final error = await firestore.inviteMemberByEmail(
                  groupId, groupName, emailController.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error ?? 'Anggota berhasil ditambahkan')),
                );
              }
            },
            child: const Text('Undang'),
          ),
        ],
      ),
    );
  }

  void _showExitDialog(BuildContext context, FirestoreService firestore, GroupMember member) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Keluarkan ${member.userName}?'),
        content: TextField(
          controller: noteController,
          decoration: const InputDecoration(
            labelText: 'Catatan (wajib)',
            hintText: 'misal: digantikan Rina, atau sisa kewajiban dilunasi di muka',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: noteController.text.trim().isEmpty
                ? null
                : () async {
                    await firestore.setMemberExit(member.id, noteController.text.trim());
                    if (context.mounted) Navigator.pop(context);
                  },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }
}
