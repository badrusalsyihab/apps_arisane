// Reminder manual (dari Sekretaris) dan otomatis (dari Cloud Function)
// sama-sama masuk ke collection ini, dibedakan lewat kolom `source`.
class AppNotification {
  final String id;
  final String userId; // penerima
  final String groupId;
  final String title;
  final String body;
  final String source; // 'manual' | 'auto_h3' | 'auto_h1' | 'auto_telat'
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.userId,
    required this.groupId,
    required this.title,
    required this.body,
    required this.source,
    required this.createdAt,
    this.read = false,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      groupId: map['groupId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      source: map['source'] ?? 'manual',
      createdAt: DateTime.parse(map['createdAt']),
      read: map['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'groupId': groupId,
        'title': title,
        'body': body,
        'source': source,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };
}
