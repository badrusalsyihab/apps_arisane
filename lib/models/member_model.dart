// Sesuai tabel `group_members` di ERD.
enum MemberRole { ketua, sekretaris, anggota }

enum MemberStatus { aktif, keluar }

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String userName; // denormalized untuk tampilan cepat
  final MemberRole role;
  final MemberStatus status;
  final String? exitNote; // catatan kalau keluar/diganti

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.role,
    this.status = MemberStatus.aktif,
    this.exitNote,
  });

  factory GroupMember.fromMap(String id, Map<String, dynamic> map) {
    return GroupMember(
      id: id,
      groupId: map['groupId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      role: MemberRole.values.firstWhere((e) => e.name == map['role'],
          orElse: () => MemberRole.anggota),
      status: MemberStatus.values.firstWhere((e) => e.name == map['status'],
          orElse: () => MemberStatus.aktif),
      exitNote: map['exitNote'],
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'userId': userId,
        'userName': userName,
        'role': role.name,
        'status': status.name,
        'exitNote': exitNote,
      };
}
