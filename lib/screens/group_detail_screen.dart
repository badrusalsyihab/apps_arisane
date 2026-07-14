import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';
import '../models/round_model.dart';
import '../services/firestore_service.dart';
import '../services/google_drive_service.dart';
import 'manage_members_screen.dart';
import 'kas_screen.dart';

// Sesuai wireframe "detail_grup_arisan_dengan_aksi" dan "detail_grup_sisi_anggota".
// Role diambil dari data asli (FirestoreService.myMembership), bukan hardcode,
// sehingga tombol yang tampil otomatis berbeda untuk ketua/sekretaris/anggota.
class GroupDetailScreen extends StatelessWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<ArisanGroup>(
          future: firestore.getGroup(groupId),
          builder: (context, snap) => Text(snap.data?.name ?? 'Detail grup'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Kas grup',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => KasScreen(groupId: groupId, userId: myUid)),
            ),
          ),
          FutureBuilder<GroupMember?>(
            future: firestore.myMembership(groupId, myUid),
            builder: (context, snap) {
              if (snap.data?.role != MemberRole.ketua) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.group_outlined),
                tooltip: 'Kelola anggota',
                onPressed: () async {
                  final group = await firestore.getGroup(groupId);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageMembersScreen(groupId: groupId, groupName: group.name),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<GroupMember?>(
        future: firestore.myMembership(groupId, myUid),
        builder: (context, myMembershipSnap) {
          if (!myMembershipSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final myMembership = myMembershipSnap.data;
          if (myMembership == null) {
            return const Center(child: Text('Kamu bukan anggota grup ini.'));
          }

          return StreamBuilder<List<GroupMember>>(
            stream: firestore.groupMembers(groupId),
            builder: (context, memberSnap) {
              if (!memberSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = memberSnap.data!;

              return StreamBuilder<List<ArisanRound>>(
                stream: firestore.groupRounds(groupId),
                builder: (context, roundSnap) {
                  final rounds = roundSnap.data ?? [];

                  // Belum ada ronde sama sekali -> Ketua bisa mulai ronde 1.
                  if (rounds.isEmpty) {
                    if (myMembership.role != MemberRole.ketua) {
                      return const Center(child: Text('Menunggu Ketua memulai ronde pertama.'));
                    }
                    return Center(
                      child: FilledButton.icon(
                        onPressed: () => _startNewRound(context, firestore, groupId, members, 1),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Mulai ronde 1'),
                      ),
                    );
                  }

                  final currentRound = rounds.last;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Ronde ${currentRound.roundNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        currentRound.winnerMemberId == null
                            ? 'Pemenang: belum dikocok'
                            : 'Pemenang: ${members.firstWhere((m) => m.id == currentRound.winnerMemberId, orElse: () => members.first).userName}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      if (myMembership.role == MemberRole.ketua && currentRound.winnerMemberId == null)
                        FilledButton.icon(
                          onPressed: () => _pickWinner(context, firestore, currentRound, members, rounds),
                          icon: const Icon(Icons.shuffle),
                          label: const Text('Kocok pemenang ronde ini'),
                        ),
                      // Ronde ini sudah ada pemenangnya & belum semua anggota kebagian
                      // menang -> Ketua bisa lanjut buka ronde berikutnya.
                      if (myMembership.role == MemberRole.ketua &&
                          currentRound.winnerMemberId != null &&
                          rounds.length < members.where((m) => m.status == MemberStatus.aktif).length)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: OutlinedButton.icon(
                            onPressed: () => _startNewRound(
                                context, firestore, groupId, members, currentRound.roundNumber + 1),
                            icon: const Icon(Icons.navigate_next),
                            label: Text('Mulai ronde ${currentRound.roundNumber + 1}'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text('Status setoran anggota', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...members.map((m) => _MemberStatusTile(
                            member: m,
                            roundId: currentRound.id,
                            groupId: groupId,
                            groupName: '', // diisi otomatis dari getGroup saat kirim reminder
                            isMe: m.userId == myUid,
                            canVerify: myMembership.role == MemberRole.sekretaris,
                          )),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Buat ronde baru + auto-generate transaksi kosong untuk semua anggota aktif,
  // sesuai FirestoreService.createRoundWithTransactions. dueDate dihitung dari
  // periode grup (mingguan = +7 hari, bulanan = +1 bulan dari hari ini).
  Future<void> _startNewRound(BuildContext context, FirestoreService firestore,
      String groupId, List<GroupMember> members, int roundNumber) async {
    final group = await firestore.getGroup(groupId);
    final now = DateTime.now();
    final dueDate = group.period == 'mingguan'
        ? now.add(const Duration(days: 7))
        : DateTime(now.year, now.month + 1, now.day);

    await firestore.createRoundWithTransactions(
      ArisanRound(id: '', groupId: groupId, roundNumber: roundNumber, dueDate: dueDate),
      members,
      group.nominal,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ronde $roundNumber dimulai, jatuh tempo ${dueDate.day}/${dueDate.month}/${dueDate.year}')),
      );
    }
  }

  // Kocok acak dari anggota aktif yang BELUM PERNAH menang ronde manapun
  // sebelumnya -- ini yang membedakan dari versi awal yang random dari semua anggota.
  Future<void> _pickWinner(BuildContext context, FirestoreService firestore,
      ArisanRound round, List<GroupMember> members, List<ArisanRound> allRounds) async {
    final previousWinnerIds = allRounds
        .where((r) => r.winnerMemberId != null)
        .map((r) => r.winnerMemberId)
        .toSet();

    final eligible = members
        .where((m) => m.status == MemberStatus.aktif && !previousWinnerIds.contains(m.id))
        .toList();

    if (eligible.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua anggota sudah pernah menang.')),
        );
      }
      return;
    }

    final winner = eligible[Random().nextInt(eligible.length)];
    await firestore.setRoundWinner(round.id, winner.id, 'kocok');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${winner.userName} menang ronde ${round.roundNumber}')),
      );
    }
  }
}

class _MemberStatusTile extends StatelessWidget {
  final GroupMember member;
  final String roundId;
  final String groupId;
  final String groupName;
  final bool isMe;
  final bool canVerify;

  const _MemberStatusTile({
    required this.member,
    required this.roundId,
    required this.groupId,
    required this.groupName,
    required this.isMe,
    required this.canVerify,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    // Setiap baris dengar transaksi milik anggota ini secara spesifik,
    // bukan lagi placeholder -- inilah koneksi yang sebelumnya kosong.
    return StreamBuilder(
      stream: firestore.memberTransactionInRound(roundId, member.id),
      builder: (context, snapshot) {
        final tx = snapshot.data;
        final status = tx?.status ?? PaymentStatus.belumJatuhTempo;

        return Container(
          decoration: BoxDecoration(
            color: isMe ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            leading: CircleAvatar(child: Text(member.userName.isNotEmpty ? member.userName[0] : '?')),
            title: Text(isMe ? '${member.userName} (kamu)' : member.userName),
            subtitle: Text(tx == null
                ? _statusLabel(status)
                : '${_statusLabel(status)} \u00b7 Rp ${tx.amount}${canVerify ? ' (tekan lama untuk ubah)' : ''}'),
            // Tekan lama untuk override nominal (kasus khusus), hanya untuk
            // yang berwenang catat keuangan (sekretaris) atau ketua.
            onLongPress: (canVerify && tx != null)
                ? () => _showEditAmountDialog(context, firestore, tx)
                : null,
            trailing: _buildTrailing(context, firestore, tx, status),
          ),
        );
      },
    );
  }

  void _showEditAmountDialog(BuildContext context, FirestoreService firestore, ArisanTransaction tx) {
    final amountController = TextEditingController(text: tx.amount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah nominal ${member.userName}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal',
            helperText: 'Hanya untuk kasus khusus, tidak mengubah standar nominal grup',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () async {
              final newAmount = int.tryParse(amountController.text) ?? tx.amount;
              await firestore.overrideTransactionAmount(tx.id, newAmount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _statusLabel(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.lunas: return 'Lunas';
      case PaymentStatus.telat: return 'Telat';
      case PaymentStatus.menungguVerifikasi: return 'Menunggu verifikasi';
      case PaymentStatus.belumLunas: return 'Belum lunas';
      case PaymentStatus.belumJatuhTempo: return 'Belum jatuh tempo';
    }
  }

  Widget? _buildTrailing(BuildContext context, FirestoreService firestore,
      ArisanTransaction? tx, PaymentStatus status) {
    if (tx == null) return null;

    // Sekretaris: kalau ada bukti masuk & menunggu verifikasi -> aksi approve/reject.
    if (canVerify && status == PaymentStatus.menungguVerifikasi) {
      final secretaryUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      return Wrap(spacing: 4, children: [
        IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.green),
          tooltip: 'Verifikasi',
          onPressed: () => firestore.verifyPayment(tx.id, secretaryUid, true),
        ),
        IconButton(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red),
          tooltip: 'Tolak',
          onPressed: () => firestore.verifyPayment(tx.id, secretaryUid, false),
        ),
      ]);
    }

    // Anggota (diri sendiri): kalau belum lunas -> tombol upload bukti.
    if (isMe && (status == PaymentStatus.belumLunas ||
        status == PaymentStatus.belumJatuhTempo ||
        status == PaymentStatus.telat)) {
      return ElevatedButton(
        onPressed: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image == null) return;
          final url = await GoogleDriveService()
              .uploadImage(image, fileNamePrefix: 'bukti_${member.userId}');
          await firestore.submitProof(tx.id, url);
        },
        child: const Text('Unggah bukti'),
      );
    }

    // Telat: Sekretaris bisa kirim reminder manual langsung ke anggota ini.
    if (canVerify && status == PaymentStatus.telat) {
      return IconButton(
        icon: const Icon(Icons.notifications_active_outlined),
        tooltip: 'Kirim reminder',
        onPressed: () async {
          final group = await firestore.getGroup(groupId);
          final message = 'Halo ${member.userName}, tolong segera lunasi setoran arisan ya.';

          // 1) Tulis dokumen notifikasi in-app (selalu berhasil, tidak butuh device token)
          await firestore.sendManualReminder(
            groupId: groupId,
            toUserId: member.userId,
            groupName: group.name,
            message: message,
          );

          // 2) Coba kirim push notification asli lewat Cloud Function (opsional,
          // gagal dengan tenang kalau anggota belum punya device token tersimpan).
          try {
            await FirebaseFunctions.instance.httpsCallable('sendManualReminderPush').call({
              'toUserId': member.userId,
              'title': group.name,
              'body': message,
            });
          } catch (_) {
            // abaikan -- notifikasi in-app tetap terkirim meski push gagal
          }

          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Reminder terkirim')));
          }
        },
      );
    }

    // Default: badge status saja
    return Chip(label: Text(_statusLabel(status)));
  }
}
