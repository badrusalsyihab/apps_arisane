// Sesuai tabel `arisan_rounds` di ERD.
class ArisanRound {
  final String id;
  final String groupId;
  final int roundNumber;
  final DateTime dueDate;
  final String? winnerMemberId;
  final String? winnerMethod; // 'kocok' | 'urutan_tetap'

  ArisanRound({
    required this.id,
    required this.groupId,
    required this.roundNumber,
    required this.dueDate,
    this.winnerMemberId,
    this.winnerMethod,
  });

  factory ArisanRound.fromMap(String id, Map<String, dynamic> map) {
    return ArisanRound(
      id: id,
      groupId: map['groupId'] ?? '',
      roundNumber: map['roundNumber'] ?? 0,
      dueDate: DateTime.parse(map['dueDate']),
      winnerMemberId: map['winnerMemberId'],
      winnerMethod: map['winnerMethod'],
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'roundNumber': roundNumber,
        'dueDate': dueDate.toIso8601String(),
        'winnerMemberId': winnerMemberId,
        'winnerMethod': winnerMethod,
      };
}

// Sesuai tabel `arisan_transactions` di ERD.
// Status: belumLunas -> menungguVerifikasi (upload bukti) -> lunas / ditolak.
// telat dihitung otomatis kalau lewat dueDate & belum lunas (tanpa denda).
enum PaymentStatus { belumJatuhTempo, belumLunas, menungguVerifikasi, lunas, telat }

class ArisanTransaction {
  final String id;
  final String roundId;
  final String memberId;
  final int amount;
  final PaymentStatus status;
  final String? proofUrl; // link Google Drive
  final String? verifiedBy; // uid sekretaris
  final DateTime? paidAt;

  ArisanTransaction({
    required this.id,
    required this.roundId,
    required this.memberId,
    required this.amount,
    this.status = PaymentStatus.belumJatuhTempo,
    this.proofUrl,
    this.verifiedBy,
    this.paidAt,
  });

  factory ArisanTransaction.fromMap(String id, Map<String, dynamic> map) {
    return ArisanTransaction(
      id: id,
      roundId: map['roundId'] ?? '',
      memberId: map['memberId'] ?? '',
      amount: map['amount'] ?? 0,
      status: PaymentStatus.values.firstWhere((e) => e.name == map['status'],
          orElse: () => PaymentStatus.belumJatuhTempo),
      proofUrl: map['proofUrl'],
      verifiedBy: map['verifiedBy'],
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'roundId': roundId,
        'memberId': memberId,
        'amount': amount,
        'status': status.name,
        'proofUrl': proofUrl,
        'verifiedBy': verifiedBy,
        'paidAt': paidAt?.toIso8601String(),
      };
}
