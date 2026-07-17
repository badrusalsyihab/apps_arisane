import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/group_model.dart';
import '../services/firestore_service.dart';
import 'group_detail_screen.dart';
import 'create_group_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  static const _green = Color(0xFF00A884);

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: StreamBuilder<List<ArisanGroup>>(
        stream: firestore.myGroups(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Gagal memuat data',
                      style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data!;

          if (groups.isEmpty) {
            return _EmptyState(userId: userId);
          }

          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: groups.length,
            separatorBuilder: (_, __) => Divider(
              height: 0,
              indent: 72,
              color: Colors.grey.shade200,
            ),
            itemBuilder: (context, i) =>
                _GroupTile(group: groups[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => CreateGroupScreen(userId: userId)),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─── WhatsApp-style chat tile ────────────────────────────────────────────
class _GroupTile extends StatelessWidget {
  final ArisanGroup group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(group.status);
    final statusLabel = _statusLabel(group.status);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => GroupDetailScreen(groupId: group.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor:
                    const Color(0xFF00A884).withValues(alpha: 0.15),
                backgroundImage: group.photoUrl != null
                    ? CachedNetworkImageProvider(group.photoUrl!)
                    : null,
                child: group.photoUrl == null
                    ? Text(
                        group.name.isNotEmpty
                            ? group.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Color(0xFF00A884),
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                              color: Color(0xFF111B21),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.group_outlined,
                            size: 13,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${group.totalMembers} anggota',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.payments_outlined,
                            size: 13,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Rp ${_formatNominal(group.nominal)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(GroupStatus s) {
    switch (s) {
      case GroupStatus.aktif:
        return const Color(0xFF00A884);
      case GroupStatus.draft:
        return Colors.orange;
      case GroupStatus.selesai:
        return Colors.blue;
      case GroupStatus.arsip:
        return Colors.grey;
    }
  }

  String _statusLabel(GroupStatus s) {
    switch (s) {
      case GroupStatus.aktif:
        return 'Aktif';
      case GroupStatus.draft:
        return 'Draft';
      case GroupStatus.selesai:
        return 'Selesai';
      case GroupStatus.arsip:
        return 'Arsip';
    }
  }

  String _formatNominal(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)}jt';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}rb';
    return '$n';
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String userId;
  const _EmptyState({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF00A884).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              size: 38,
              color: Color(0xFF00A884),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada grup arisan',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111B21),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Buat grup baru atau minta\nketua untuk mengundangmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat Grup'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreateGroupScreen(userId: userId)),
            ),
          ),
        ],
      ),
    );
  }
}
