// Saat Ketua undang email yang belum pernah login (belum ada dokumen di
// `users`), invitasi disimpan di sini dulu. Begitu user itu login pertama
// kali (lewat Google Sign-In), AuthService cek collection ini berdasarkan
// email dan otomatis assign dia ke grup yang mengundangnya.
class PendingInvite {
  final String id;
  final String groupId;
  final String groupName;
  final String email;
  final String invitedBy;
  final DateTime createdAt;

  PendingInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.email,
    required this.invitedBy,
    required this.createdAt,
  });

  factory PendingInvite.fromMap(String id, Map<String, dynamic> map) {
    return PendingInvite(
      id: id,
      groupId: map['groupId'] ?? '',
      groupName: map['groupName'] ?? '',
      email: map['email'] ?? '',
      invitedBy: map['invitedBy'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'groupName': groupName,
        'email': email,
        'invitedBy': invitedBy,
        'createdAt': createdAt.toIso8601String(),
      };
}
