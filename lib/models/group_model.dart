// Sesuai tabel `arisan_groups` di ERD.
// status menentukan aturan hapus: draft (hard delete bebas),
// aktif (hanya bisa arsip), selesai (boleh hard delete dengan warning).
enum GroupStatus { draft, aktif, selesai, arsip }

class ArisanGroup {
  final String id;
  final String name;
  final String? photoUrl; // null -> UI pakai placeholder ikon
  final String createdBy; // uid ketua/pembuat
  final int totalMembers;
  final int nominal; // nominal setoran per ronde
  final String period; // 'mingguan' | 'bulanan'
  final DateTime startDate;
  final GroupStatus status;

  ArisanGroup({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.createdBy,
    required this.totalMembers,
    required this.nominal,
    required this.period,
    required this.startDate,
    this.status = GroupStatus.draft,
  });

  factory ArisanGroup.fromMap(String id, Map<String, dynamic> map) {
    return ArisanGroup(
      id: id,
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      createdBy: map['createdBy'] ?? '',
      totalMembers: map['totalMembers'] ?? 0,
      nominal: map['nominal'] ?? 0,
      period: map['period'] ?? 'bulanan',
      startDate: DateTime.parse(map['startDate']),
      status: GroupStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'draft'),
        orElse: () => GroupStatus.draft,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'photoUrl': photoUrl,
        'createdBy': createdBy,
        'totalMembers': totalMembers,
        'nominal': nominal,
        'period': period,
        'startDate': startDate.toIso8601String(),
        'status': status.name,
      };
}
