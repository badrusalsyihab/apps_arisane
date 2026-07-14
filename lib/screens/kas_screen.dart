import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/kas_model.dart';
import '../services/firestore_service.dart';

// Sesuai wireframe "halaman_kas_grup" dan "modal_catat_pemasukan_kas".
class KasScreen extends StatelessWidget {
  final String groupId;
  final String userId;
  const KasScreen({super.key, required this.groupId, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Kas grup')),
      body: StreamBuilder<List<KasTransaction>>(
        stream: firestore.groupKas(groupId),
        builder: (context, snapshot) {
          final transactions = snapshot.data ?? [];
          final saldo = transactions.fold<int>(
              0, (sum, t) => sum + (t.type == KasType.masuk ? t.amount : -t.amount));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Saldo kas saat ini'),
                      Text('Rp ${saldo.toString()}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Catat pemasukan'),
                    onPressed: () => _showKasForm(context, firestore, KasType.masuk),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text('Catat pengeluaran'),
                    onPressed: () => _showKasForm(context, firestore, KasType.keluar),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              const Text('Riwayat transaksi', style: TextStyle(fontWeight: FontWeight.w600)),
              ...transactions.map((t) => ListTile(
                    leading: Icon(
                      t.type == KasType.masuk ? Icons.arrow_downward : Icons.arrow_upward,
                      color: t.type == KasType.masuk ? Colors.green : Colors.red,
                    ),
                    title: Text(t.description),
                    subtitle: Text('${t.date.day}/${t.date.month}/${t.date.year}'),
                    trailing: Text(
                      '${t.type == KasType.masuk ? '+' : '-'}Rp ${t.amount}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: t.type == KasType.masuk ? Colors.green : Colors.red,
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _showKasForm(BuildContext context, FirestoreService firestore, KasType type) {
    final descController = TextEditingController();
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type == KasType.masuk ? 'Catat pemasukan' : 'Catat pengeluaran',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Keterangan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text) ?? 0;
                await firestore.addKasTransaction(KasTransaction(
                  id: const Uuid().v4(),
                  groupId: groupId,
                  type: type,
                  description: descController.text,
                  amount: amount,
                  date: DateTime.now(),
                  recordedBy: userId,
                ));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
