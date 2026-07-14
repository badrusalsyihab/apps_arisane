const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Jalan tiap hari jam 08:00 WIB. Scan semua ronde yang jatuh temponya
// H-3, H-1, atau sudah lewat (telat) dan masih ada anggota yang belum lunas,
// lalu tulis dokumen ke collection `notifications` untuk tiap anggota tsb.
// Dedup pakai deterministic doc ID supaya tidak double-kirim di hari yang sama.
exports.dailyPaymentReminders = onSchedule(
  { schedule: '0 8 * * *', timeZone: 'Asia/Jakarta' },
  async () => {
    const today = startOfDay(new Date());
    const roundsSnap = await db.collection('arisan_rounds').get();

    for (const roundDoc of roundsSnap.docs) {
      const round = roundDoc.data();
      const dueDate = startOfDay(new Date(round.dueDate));
      const dayDiff = Math.round((dueDate - today) / (1000 * 60 * 60 * 24));

      let source = null;
      if (dayDiff === 3) source = 'auto_h3';
      else if (dayDiff === 1) source = 'auto_h1';
      else if (dayDiff < 0) source = 'auto_telat';
      if (!source) continue; // bukan hari yang relevan untuk reminder

      const groupSnap = await db.collection('arisan_groups').doc(round.groupId).get();
      const groupName = groupSnap.exists ? groupSnap.data().name : 'Arisan';

      const txSnap = await db
        .collection('arisan_transactions')
        .where('roundId', '==', roundDoc.id)
        .where('status', 'in', ['belumJatuhTempo', 'belumLunas', 'telat'])
        .get();

      for (const txDoc of txSnap.docs) {
        const tx = txDoc.data();
        const memberSnap = await db.collection('group_members').doc(tx.memberId).get();
        if (!memberSnap.exists) continue;
        const member = memberSnap.data();
        if (member.status !== 'aktif') continue;

        const dedupId = `${roundDoc.id}_${tx.memberId}_${source}_${today.toISOString().slice(0, 10)}`;
        const notifRef = db.collection('notifications').doc(dedupId);
        const already = await notifRef.get();
        if (already.exists) continue; // sudah dikirim hari ini, skip

        await notifRef.set({
          userId: member.userId,
          groupId: round.groupId,
          title: groupName,
          body: messageFor(source, round.roundNumber, dueDate),
          source,
          createdAt: new Date().toISOString(),
          read: false,
        });

        // Kirim push notification asli lewat FCM kalau device token tersimpan.
        // Kalau user belum pernah buka app dengan versi yang sudah pasang
        // firebase_messaging (token kosong), reminder tetap masuk sebagai
        // dokumen notifikasi in-app di atas -- push ini cuma tambahan.
        const userSnap = await db.collection('users').doc(member.userId).get();
        const fcmToken = userSnap.data()?.fcmToken;
        if (fcmToken) {
          try {
            await admin.messaging().send({
              token: fcmToken,
              notification: { title: groupName, body: messageFor(source, round.roundNumber, dueDate) },
            });
          } catch (err) {
            // Token kadaluarsa/invalid -> jangan sampai gagalkan seluruh loop,
            // cukup log supaya kelihatan di firebase functions:log.
            console.error(`Gagal kirim FCM ke ${member.userId}:`, err.message);
          }
        }
      }

      // Update status transaksi jadi 'telat' otomatis kalau sudah lewat jatuh tempo.
      if (source === 'auto_telat') {
        const batch = db.batch();
        txSnap.docs.forEach((txDoc) => {
          if (txDoc.data().status !== 'telat') {
            batch.update(txDoc.ref, { status: 'telat' });
          }
        });
        await batch.commit();
      }
    }
  }
);

function startOfDay(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function messageFor(source, roundNumber, dueDate) {
  const dateStr = `${dueDate.getDate()}/${dueDate.getMonth() + 1}`;
  if (source === 'auto_h3') {
    return `Jangan lupa, setoran ronde ${roundNumber} jatuh tempo 3 hari lagi (${dateStr}).`;
  }
  if (source === 'auto_h1') {
    return `Setoran ronde ${roundNumber} jatuh tempo besok (${dateStr}).`;
  }
  return `Setoran ronde ${roundNumber} sudah lewat jatuh tempo. Segera setor dan unggah bukti.`;
}

// Dipanggil dari client (Sekretaris klik tombol reminder manual) untuk kirim
// push notification asli ke satu anggota, sebagai tambahan dari dokumen
// notifikasi in-app yang sudah ditulis langsung oleh client lewat
// FirestoreService.sendManualReminder. Dipisah jadi callable function karena
// client Flutter tidak boleh punya akses langsung ke admin.messaging().
exports.sendManualReminderPush = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Harus login untuk kirim reminder.');
  }
  const { toUserId, title, body } = request.data;
  if (!toUserId || !title || !body) {
    throw new HttpsError('invalid-argument', 'toUserId, title, dan body wajib diisi.');
  }

  const userSnap = await db.collection('users').doc(toUserId).get();
  const fcmToken = userSnap.data()?.fcmToken;
  if (!fcmToken) {
    return { sent: false, reason: 'Anggota belum punya device token (belum pernah buka app versi terbaru).' };
  }

  await admin.messaging().send({
    token: fcmToken,
    notification: { title, body },
  });
  return { sent: true };
});
