// Sesuai tabel `users` di ERD.
// platformRole membedakan user biasa vs admin/root platform (untuk monitoring).
class AppUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoUrl;
  final String platformRole; // 'user' | 'admin'

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.photoUrl,
    this.platformRole = 'user',
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      platformRole: map['platformRole'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'platformRole': platformRole,
      };

  bool get isAdmin => platformRole == 'admin';
}
