import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/firestore_service.dart';

// Khusus user dengan platformRole == 'admin'. Berbeda dari DashboardScreen:
// ini nampilkan SEMUA grup di seluruh platform (lintas user), untuk
// keperluan monitoring/moderasi, bukan untuk ikut arisan.
// Admin sengaja TIDAK diberi akses lihat detail bukti transfer per anggota
// di sini, supaya privasi finansial user tetap terjaga secara default.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin - monitoring platform')),
      body: StreamBuilder<List<ArisanGroup>>(
        stream: firestore.allGroupsForAdmin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          final activeCount = groups.where((g) => g.status == GroupStatus.aktif).length;
          final draftCount = groups.where((g) => g.status == GroupStatus.draft).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Metrics agregat
              Row(children: [
                Expanded(child: _MetricCard(label: 'Total grup', value: '${groups.length}')),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(label: 'Grup aktif', value: '$activeCount')),
                const SizedBox(width: 12),
                Expanded(child: _MetricCard(label: 'Draft', value: '$draftCount')),
              ]),
              const SizedBox(height: 20),
              const Text('Semua grup', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...groups.map((g) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            g.photoUrl != null ? NetworkImage(g.photoUrl!) : null,
                        child: g.photoUrl == null ? const Icon(Icons.groups_outlined) : null,
                      ),
                      title: Text(g.name),
                      subtitle: Text('${g.totalMembers} anggota \u00b7 dibuat oleh ${g.createdBy}'),
                      trailing: Chip(
                        label: Text(g.status.name),
                        backgroundColor: _statusColor(context, g.status),
                      ),
                      onTap: () {
                        // Buka detail read-only untuk investigasi/support,
                        // bukan detail transaksi finansial per anggota.
                      },
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  Color _statusColor(BuildContext context, GroupStatus status) {
    switch (status) {
      case GroupStatus.aktif:
        return Colors.green.withValues(alpha: 0.15);
      case GroupStatus.draft:
        return Colors.orange.withValues(alpha: 0.15);
      case GroupStatus.selesai:
        return Colors.blue.withValues(alpha: 0.15);
      case GroupStatus.arsip:
        return Colors.grey.withValues(alpha: 0.15);
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
