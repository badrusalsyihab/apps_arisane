import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/group_model.dart';
import '../services/firestore_service.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';
import 'notifications_screen.dart';

// Sesuai wireframe "dashboard_arisan_group_list":
// grid kartu grup, foto/placeholder, nama, jumlah anggota, status ronde.
// Hanya menampilkan grup milik user ini (bukan semua grup di platform).
class DashboardScreen extends StatelessWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grup arisan saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifikasi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotificationsScreen(userId: userId)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreateGroupScreen(userId: userId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Buat grup'),
      ),
      body: StreamBuilder<List<ArisanGroup>>(
        stream: firestore.myGroups(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data!;
          if (groups.isEmpty) {
            return const Center(child: Text('Belum ada grup arisan. Buat atau minta diundang.'));
          }
          // Grid responsif: 1 kolom di mobile sempit, 2+ di layar lebar (web/tablet).
          return LayoutBuilder(builder: (context, constraints) {
            final crossAxisCount = (constraints.maxWidth / 320).floor().clamp(1, 4);
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.6,
              ),
              itemCount: groups.length,
              itemBuilder: (context, i) => _GroupCard(group: groups[i]),
            );
          });
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final ArisanGroup group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Foto grup, kalau kosong pakai placeholder ikon
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: group.photoUrl != null
                    ? CachedNetworkImageProvider(group.photoUrl!)
                    : null,
                child: group.photoUrl == null
                    ? const Icon(Icons.groups_outlined)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${group.totalMembers} anggota',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
