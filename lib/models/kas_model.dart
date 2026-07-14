// Sesuai tabel `kas_transactions` di ERD. Terpisah dari setoran arisan
// karena saldo kas mengendap, tidak dibagi rutin ke pemenang.
enum KasType { masuk, keluar }

class KasTransaction {
  final String id;
  final String groupId;
  final KasType type;
  final String description;
  final int amount;
  final DateTime date;
  final String recordedBy; // uid sekretaris
  final String? proofUrl;

  KasTransaction({
    required this.id,
    required this.groupId,
    required this.type,
    required this.description,
    required this.amount,
    required this.date,
    required this.recordedBy,
    this.proofUrl,
  });

  factory KasTransaction.fromMap(String id, Map<String, dynamic> map) {
    return KasTransaction(
      id: id,
      groupId: map['groupId'] ?? '',
      type: KasType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => KasType.masuk),
      description: map['description'] ?? '',
      amount: map['amount'] ?? 0,
      date: DateTime.parse(map['date']),
      recordedBy: map['recordedBy'] ?? '',
      proofUrl: map['proofUrl'],
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'type': type.name,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'recordedBy': recordedBy,
        'proofUrl': proofUrl,
      };
}
