# Project Brief: Aplikasi Arisan Online

Gunakan dokumen ini sebagai instruksi awal untuk melanjutkan development project
Flutter yang sudah ada di folder ini. Semua keputusan produk di bawah sudah final
hasil diskusi sebelumnya — ikuti persis, jangan asumsikan ulang.

## Konteks & Tujuan Produk

Bangun aplikasi web + mobile (Android & iOS) untuk mengelola **arisan** (sistem
tabungan/gotong-royong bergilir khas Indonesia) secara digital, menggantikan
pencatatan manual di grup WhatsApp + Excel. Tujuan bisnis: produk yang dibutuhkan
banyak orang (jutaan pengguna arisan di Indonesia), dipakai berulang tiap
siklus setoran, dan punya jalur monetisasi (freemium + subscription untuk Ketua/bandar).

## Tech Stack (wajib diikuti)

- **Frontend**: Flutter (satu codebase untuk Android, iOS, dan Web/mobile-web responsif)
- **Backend & Database**: Firebase — Firestore (data), Firebase Auth (login via Google Sign-In)
- **Upload gambar** (bukti transfer, foto grup, nota kas): **Google Drive API**
  (bukan Firebase Storage) — file disimpan di Drive akun user, hanya link-nya yang
  disimpan di Firestore (kolom `proofUrl` / `photoUrl`)

## Struktur Role (4 level, sudah final)

| Level | Role | Scope | Dibuat oleh |
|---|---|---|---|
| Platform | **Admin/Root** | Monitoring semua grup lintas user, TIDAK bisa lihat detail bukti transfer per anggota (privasi) | Ditentukan manual di Firestore (`users.platformRole = 'admin'`) |
| Grup | **Ketua** | Kelola aturan grup, jalankan kocok pemenang, undang/keluarkan anggota | Otomatis jadi Ketua saat membuat grup |
| Grup | **Sekretaris** | Verifikasi/tolak bukti setoran, catat pemasukan & pengeluaran kas, kirim reminder manual | Ditunjuk oleh Ketua (bisa merangkap Ketua di grup kecil) |
| Grup | **Anggota** | Upload bukti setor milik sendiri, lihat status semua orang (read-only) | Join via invite |

## Aturan Bisnis Kunci (jangan diubah tanpa konfirmasi user)

1. **Tidak ada sistem denda.** Keterlambatan hanya ditangani lewat *social
   accountability*: reminder otomatis bertingkat (H-3, H-1, lewat jatuh tempo)
   + dashboard status publik yang terlihat semua anggota (Lunas/Telat/Menunggu
   verifikasi/Belum jatuh tempo).
2. **Pemenang tetap wajib setor** sampai siklus arisan tuntas — status
   "sudah menang" dan status "sudah setor ronde ini" adalah dua hal terpisah,
   jangan digabung.
3. **Kas terpisah dari setoran arisan.** Kas mengendap (tidak dibagi rutin,
   dipakai untuk kado/konsumsi/dana darurat grup), sedangkan setoran arisan
   muter ke satu pemenang tiap ronde. Dua tabel/collection terpisah.
4. **Anggota keluar di tengah siklus**: tidak ada alur otomatis (cari
   pengganti/refund) karena aturannya beda-beda tiap grup. Sistem hanya
   sediakan pencatatan fleksibel: Ketua ubah status jadi "keluar" +
   catatan wajib, riwayat kemenangan sebelumnya tetap tersimpan untuk transparansi.
5. **Visibilitas per user**: user biasa (Ketua/Sekretaris/Anggota) hanya bisa
   lihat grup yang dia ikuti sendiri — TIDAK bisa lihat daftar semua grup di
   platform. Hanya Admin/Root yang punya akses lintas-grup itu.
6. **Aturan hapus grup**:
   - Status `draft` (belum ada transaksi) → Ketua boleh hard delete kapan saja.
   - Status `aktif` (siklus berjalan) → Ketua hanya boleh **arsipkan**, tidak hard delete.
   - Status `selesai` (siklus tuntas) → boleh hard delete dengan warning "riwayat akan hilang".
   - Admin/Root bisa override semua kondisi di atas untuk kasus moderasi/pelanggaran.
7. **Verifikasi setoran**: alur wajib adalah Anggota upload bukti → status
   `menungguVerifikasi` → Sekretaris approve (jadi `lunas`) atau reject
   (balik ke `belumLunas` + anggota upload ulang). Anggota tidak bisa
   self-verify.

## Struktur Data (Firestore collections, sesuai ERD yang sudah disepakati)

- `users` — id, name, email, phone, photoUrl, platformRole ('user'|'admin')
- `arisan_groups` — id, name, photoUrl (nullable → UI pakai placeholder ikon),
  createdBy, totalMembers, nominal, period ('mingguan'|'bulanan'), startDate,
  status ('draft'|'aktif'|'selesai'|'arsip')
- `group_members` — id, groupId, userId, userName, role ('ketua'|'sekretaris'|'anggota'),
  status ('aktif'|'keluar'), exitNote (nullable)
- `arisan_rounds` — id, groupId, roundNumber, dueDate, winnerMemberId (nullable),
  winnerMethod ('kocok'|'urutan_tetap')
- `arisan_transactions` — id, roundId, memberId, amount, status
  ('belumJatuhTempo'|'belumLunas'|'menungguVerifikasi'|'lunas'|'telat'),
  proofUrl (nullable, link Google Drive), verifiedBy (nullable, uid sekretaris), paidAt
- `kas_transactions` — id, groupId, type ('masuk'|'keluar'), description, amount,
  date, recordedBy (uid sekretaris), proofUrl (nullable, opsional tidak wajib)

## Status Project Saat Ini (sudah dikerjakan di folder ini)

```
lib/
  models/        -> user, group, member, round+transaction, kas (SUDAH LENGKAP)
  services/
    auth_service.dart          -> Google Sign-In + auto-create user doc (SUDAH)
    google_drive_service.dart  -> upload gambar ke folder "ArisanApp Uploads" di Drive (SUDAH)
    firestore_service.dart     -> CRUD lengkap + createRoundWithTransactions,
                                   memberTransactionInRound, myMembership,
                                   setMemberRole, inviteMemberByEmail, getGroup (SUDAH)
  screens/
    dashboard_screen.dart        -> grid grup milik user, foto/placeholder (SUDAH)
    group_detail_screen.dart     -> status setoran per anggota (terhubung transaksi asli,
                                     bukan placeholder lagi), verifikasi, kocok (exclude
                                     pemenang sebelumnya), mulai ronde baru, tombol ke
                                     Kas & Kelola Anggota di app bar (SUDAH)
    kas_screen.dart               -> saldo + form pemasukan/pengeluaran (SUDAH)
    create_group_screen.dart      -> form buat grup baru (SUDAH)
    admin_dashboard_screen.dart   -> monitoring lintas grup untuk admin (SUDAH)
    manage_members_screen.dart    -> invite via email, assign Sekretaris, tandai
                                      keluar dengan catatan wajib (SUDAH)
    notifications_screen.dart     -> daftar reminder diterima user (SUDAH)
  main.dart        -> entry point + auth gate + routing admin/user berdasarkan
                       platformRole di Firestore (SUDAH)

functions/
  index.js          -> Cloud Function terjadwal harian (08:00 WIB): scan ronde
                        H-3/H-1/telat, tulis dokumen notifikasi per anggota yang
                        belum lunas, auto-update status jadi 'telat'. FCM push
                        asli masih di-comment, perlu fcmToken (SUDAH, belum di-deploy)

firestore.rules      -> role-based security rules (ketua/sekretaris/anggota/admin)
                        (SUDAH, belum di-deploy)
```

## Yang Masih Harus Dikerjakan

Semua fitur/halaman/fungsi dari perencanaan produk sudah diimplementasikan.
Sisanya murni langkah **setup & deployment**, bukan fitur baru:

1. **Setup Firebase project nyata**: jalankan `flutterfire configure` untuk
   generate `firebase_options.dart`, lalu:
   ```
   cd functions && npm install
   firebase deploy --only functions
   firebase deploy --only firestore:rules
   ```
   Semua butuh kredensial akun Google/Firebase milik user, tidak bisa
   dijalankan di sandbox ini.
2. **Testing** — sengaja belum dikerjakan sesuai instruksi user saat ini.
3. **Validasi kompilasi nyata** — kode belum pernah di-compile karena sandbox
   ini tidak punya Flutter SDK. Jalankan `flutter pub get` lalu `flutter analyze`
   di komputer sendiri untuk cek typo/error import sebelum run.
4. **Perketat rule `arisan_transactions`** (opsional, lanjutan) — saat ini
   masih `isSignedIn()` saja karena collection ini tidak simpan `groupId`
   langsung (hanya `roundId`). Kalau butuh validasi role sekretaris ketat di
   level database, tambahkan Cloud Function `onWrite` trigger yang lookup
   `roundId` -> `groupId` -> cek role, lalu revert perubahan tidak sah.

## Fitur yang Sudah Lengkap (ringkasan)

- Auth Google Sign-In + auto-resolve pending invite saat login pertama kali
- Upload gambar apapun ke Google Drive (bukti transfer, foto grup, nota kas)
- Dashboard grup (user) & dashboard monitoring lintas grup (admin/root)
- Buat grup, mulai ronde baru (auto-generate transaksi per anggota aktif)
- Kocok pemenang (exclude yang sudah pernah menang), override nominal per
  anggota untuk kasus khusus (tekan lama pada baris anggota)
- Verifikasi/tolak bukti setoran oleh Sekretaris
- Kelola anggota: invite via email (termasuk yang belum pernah login, via
  pending invite), assign/copot role Sekretaris, tandai keluar dengan catatan
- Modul kas terpisah (saldo, catat pemasukan/pengeluaran)
- Reminder otomatis (H-3/H-1/telat) via Cloud Function terjadwal harian +
  reminder manual dari Sekretaris, keduanya masuk sebagai notifikasi in-app
  DAN push notification asli (FCM) kalau device token tersimpan
- Firestore Security Rules berbasis role (ketua/sekretaris/anggota/admin)

## Cara Kerja yang Diharapkan

- Ikuti struktur file & penamaan yang sudah ada, jangan restrukturisasi folder tanpa alasan kuat.
- Setiap keputusan bisnis baru yang belum tercakup di atas (misal: aturan baru
  soal denda, atau ubah cara kocok) — konfirmasi ke user dulu sebelum implementasi,
  karena beberapa keputusan (contoh: tidak ada denda) sengaja dipilih dan final.
- Jalankan `flutter analyze` setelah perubahan untuk pastikan tidak ada error kompilasi.
- README.md di root project berisi instruksi setup Firebase & Google Drive API
  lengkap — baca itu dulu sebelum minta user setup ulang sesuatu yang sudah dijelaskan.
