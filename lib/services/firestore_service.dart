import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/member_model.dart';
import '../models/round_model.dart';
import '../models/kas_model.dart';
import '../models/notification_model.dart';
import '../models/pending_invite_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ---------- GRUP ----------
  // Sesuai aturan sebelumnya: user biasa hanya lihat grup yang dia ikuti,
  // bukan semua grup di platform (itu khusus dashboard admin/root).
  Stream<List<ArisanGroup>> myGroups(String userId) {
    return _db
        .collection('group_members')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'aktif')
        .snapshots()
        .asyncMap((snap) async {
      final groupIds = snap.docs.map((d) => d['groupId'] as String).toList();
      if (groupIds.isEmpty) return <ArisanGroup>[];
      final groups = await _db
          .collection('arisan_groups')
          .where(FieldPath.documentId, whereIn: groupIds)
          .get();
      return groups.docs
          .map((d) => ArisanGroup.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<String> createGroup(ArisanGroup group, String creatorUserId, String creatorName) async {
    final doc = await _db.collection('arisan_groups').add(group.toMap());
    // Pembuat grup otomatis jadi ketua. ID dokumen dibuat deterministik
    // ("{groupId}_{userId}") supaya Firestore security rules bisa langsung
    // get() tanpa query saat cek role/membership.
    await _db.collection('group_members').doc('${doc.id}_$creatorUserId').set(GroupMember(
      id: '',
      groupId: doc.id,
      userId: creatorUserId,
      userName: creatorName,
      role: MemberRole.ketua,
    ).toMap());
    return doc.id;
  }

  // Grup draft (belum ada transaksi) -> hard delete.
  // Grup aktif -> hanya boleh diarsipkan, tidak dihapus.
  Future<void> archiveGroup(String groupId) =>
      _db.collection('arisan_groups').doc(groupId).update({'status': 'arsip'});

  Future<void> deleteDraftGroup(String groupId) =>
      _db.collection('arisan_groups').doc(groupId).delete();

  Future<ArisanGroup> getGroup(String groupId) async {
    final doc = await _db.collection('arisan_groups').doc(groupId).get();
    return ArisanGroup.fromMap(doc.id, doc.data()!);
  }

  // ---------- ANGGOTA ----------
  Stream<List<GroupMember>> groupMembers(String groupId) {
    return _db
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((s) => s.docs.map((d) => GroupMember.fromMap(d.id, d.data())).toList());
  }

  Future<void> setMemberExit(String memberDocId, String note) =>
      _db.collection('group_members').doc(memberDocId).update({
        'status': 'keluar',
        'exitNote': note,
      });

  // Ketua ubah role anggota jadi Sekretaris (atau balik jadi anggota biasa).
  // Satu akun tetap bisa merangkap Ketua+Sekretaris di grup kecil (tidak dipaksa beda orang).
  Future<void> setMemberRole(String memberDocId, MemberRole role) =>
      _db.collection('group_members').doc(memberDocId).update({'role': role.name});

  // Invite anggota baru berdasarkan email.
  // Kasus 1: user sudah pernah login (ada dokumen di `users`) -> langsung
  //          ditambahkan ke group_members.
  // Kasus 2: user belum pernah login -> disimpan sebagai PendingInvite,
  //          nanti otomatis di-resolve saat dia login pertama kali
  //          (lihat resolvePendingInvites, dipanggil dari AuthService).
  Future<String?> inviteMemberByEmail(String groupId, String groupName, String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    final userQuery =
        await _db.collection('users').where('email', isEqualTo: trimmedEmail).limit(1).get();

    if (userQuery.docs.isEmpty) {
      // Belum pernah login -> simpan sebagai pending invite.
      final already = await _db
          .collection('pending_invites')
          .where('groupId', isEqualTo: groupId)
          .where('email', isEqualTo: trimmedEmail)
          .limit(1)
          .get();
      if (already.docs.isNotEmpty) {
        return 'Email ini sudah diundang sebelumnya, menunggu dia login pertama kali.';
      }
      await _db.collection('pending_invites').add(PendingInvite(
        id: '',
        groupId: groupId,
        groupName: groupName,
        email: trimmedEmail,
        invitedBy: '',
        createdAt: DateTime.now(),
      ).toMap());
      return 'Email belum pernah pakai app ini. Undangan disimpan, otomatis masuk grup begitu dia login pertama kali.';
    }

    final userDoc = userQuery.docs.first;
    final already = await _db
        .collection('group_members')
        .doc('${groupId}_${userDoc.id}')
        .get();
    if (already.exists) {
      return 'User ini sudah jadi anggota grup.';
    }

    await _db.collection('group_members').doc('${groupId}_${userDoc.id}').set(GroupMember(
      id: '',
      groupId: groupId,
      userId: userDoc.id,
      userName: userDoc.data()['name'] ?? trimmedEmail,
      role: MemberRole.anggota,
    ).toMap());
    return null; // sukses
  }

  // Dipanggil sekali oleh AuthService setiap kali user login, untuk cek
  // apakah emailnya punya undangan tertunda, lalu otomatis di-assign ke grup.
  Future<void> resolvePendingInvites(String userId, String userName, String email) async {
    final trimmedEmail = email.trim().toLowerCase();
    final invites = await _db
        .collection('pending_invites')
        .where('email', isEqualTo: trimmedEmail)
        .get();

    for (final inviteDoc in invites.docs) {
      final invite = PendingInvite.fromMap(inviteDoc.id, inviteDoc.data());
      await _db.collection('group_members').doc('${invite.groupId}_$userId').set(GroupMember(
        id: '',
        groupId: invite.groupId,
        userId: userId,
        userName: userName,
        role: MemberRole.anggota,
      ).toMap());
      await inviteDoc.reference.delete(); // sudah di-resolve, hapus dari pending
    }
  }

  Stream<List<PendingInvite>> pendingInvitesForGroup(String groupId) {
    return _db
        .collection('pending_invites')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .map((s) => s.docs.map((d) => PendingInvite.fromMap(d.id, d.data())).toList());
  }

  Future<void> cancelPendingInvite(String inviteId) =>
      _db.collection('pending_invites').doc(inviteId).delete();

  // ---------- RONDE & SETORAN ----------
  Stream<List<ArisanRound>> groupRounds(String groupId) {
    return _db
        .collection('arisan_rounds')
        .where('groupId', isEqualTo: groupId)
        .orderBy('roundNumber')
        .snapshots()
        .map((s) => s.docs.map((d) => ArisanRound.fromMap(d.id, d.data())).toList());
  }

  Stream<List<ArisanTransaction>> roundTransactions(String roundId) {
    return _db
        .collection('arisan_transactions')
        .where('roundId', isEqualTo: roundId)
        .snapshots()
        .map((s) => s.docs.map((d) => ArisanTransaction.fromMap(d.id, d.data())).toList());
  }

  // Saat ronde baru dibuat, generate satu baris transaksi per anggota aktif
  // (status awal 'belumJatuhTempo'), supaya tiap anggota -- termasuk yang
  // sudah pernah menang -- otomatis punya kewajiban setor di ronde ini.
  Future<String> createRoundWithTransactions(
      ArisanRound round, List<GroupMember> members, int nominal) async {
    final roundDoc = await _db.collection('arisan_rounds').add(round.toMap());
    final batch = _db.batch();
    for (final m in members.where((m) => m.status == MemberStatus.aktif)) {
      final txRef = _db.collection('arisan_transactions').doc();
      batch.set(txRef, ArisanTransaction(
        id: '',
        roundId: roundDoc.id,
        memberId: m.id,
        amount: nominal,
      ).toMap());
    }
    await batch.commit();
    return roundDoc.id;
  }

  // Cari 1 transaksi milik member tertentu di ronde tertentu -- dipakai
  // untuk menghubungkan tombol upload/verifikasi ke record yang tepat.
  Stream<ArisanTransaction?> memberTransactionInRound(String roundId, String memberId) {
    return _db
        .collection('arisan_transactions')
        .where('roundId', isEqualTo: roundId)
        .where('memberId', isEqualTo: memberId)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : ArisanTransaction.fromMap(s.docs.first.id, s.docs.first.data()));
  }

  // Override nominal setoran untuk satu anggota di satu ronde tertentu
  // (kasus khusus: anggota baru join di tengah siklus, kesepakatan beda, dll).
  // Hanya mengubah transaksi ini, tidak mempengaruhi nominal standar grup.
  Future<void> overrideTransactionAmount(String transactionId, int newAmount) =>
      _db.collection('arisan_transactions').doc(transactionId).update({'amount': newAmount});

  // Ambil role & id dokumen group_members milik user yang sedang login,
  // untuk tahu tombol/aksi apa yang boleh ditampilkan di UI.
  Future<GroupMember?> myMembership(String groupId, String userId) async {
    final snap = await _db
        .collection('group_members')
        .where('groupId', isEqualTo: groupId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return GroupMember.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  // Anggota upload bukti -> status jadi menunggu verifikasi
  Future<void> submitProof(String transactionId, String proofUrl) =>
      _db.collection('arisan_transactions').doc(transactionId).update({
        'proofUrl': proofUrl,
        'status': 'menungguVerifikasi',
      });

  // Sekretaris verifikasi/tolak bukti
  Future<void> verifyPayment(String transactionId, String secretaryUid, bool approve) =>
      _db.collection('arisan_transactions').doc(transactionId).update({
        'status': approve ? 'lunas' : 'belumLunas',
        'verifiedBy': secretaryUid,
        'paidAt': approve ? DateTime.now().toIso8601String() : null,
      });

  // Ketua jalankan kocok pemenang: pilih random dari anggota yang belum pernah menang
  Future<void> setRoundWinner(String roundId, String winnerMemberId, String method) =>
      _db.collection('arisan_rounds').doc(roundId).update({
        'winnerMemberId': winnerMemberId,
        'winnerMethod': method,
      });

  // ---------- KAS ----------
  Stream<List<KasTransaction>> groupKas(String groupId) {
    return _db
        .collection('kas_transactions')
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => KasTransaction.fromMap(d.id, d.data())).toList());
  }

  Future<void> addKasTransaction(KasTransaction tx) =>
      _db.collection('kas_transactions').add(tx.toMap());

  // ---------- ADMIN/ROOT (monitoring lintas grup) ----------
  Stream<List<ArisanGroup>> allGroupsForAdmin() {
    return _db
        .collection('arisan_groups')
        .snapshots()
        .map((s) => s.docs.map((d) => ArisanGroup.fromMap(d.id, d.data())).toList());
  }

  // ---------- NOTIFIKASI / REMINDER ----------
  // Reminder otomatis (H-3/H-1/telat) ditulis oleh Cloud Function terjadwal
  // (lihat functions/index.js), reminder manual ditulis langsung dari sini.
  Stream<List<AppNotification>> myNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList());
  }

  Future<void> markNotificationRead(String notifId) =>
      _db.collection('notifications').doc(notifId).update({'read': true});

  // Sekretaris kirim reminder manual ke satu anggota tertentu.
  Future<void> sendManualReminder({
    required String groupId,
    required String toUserId,
    required String groupName,
    required String message,
  }) {
    return _db.collection('notifications').add(AppNotification(
      id: '',
      userId: toUserId,
      groupId: groupId,
      title: groupName,
      body: message,
      source: 'manual',
      createdAt: DateTime.now(),
    ).toMap());
  }
}
