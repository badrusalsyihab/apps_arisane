import 'package:flutter/material.dart';
import '../models/group_model.dart';
import '../services/firestore_service.dart';

// Pembuat grup otomatis jadi Ketua (lihat FirestoreService.createGroup).
class CreateGroupScreen extends StatefulWidget {
  final String userId;
  const CreateGroupScreen({super.key, required this.userId});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _nominalController = TextEditingController();
  String _period = 'bulanan';
  int _totalMembers = 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat grup arisan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nama grup'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nominalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal setoran per ronde'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _period,
            decoration: const InputDecoration(labelText: 'Periode'),
            items: const [
              DropdownMenuItem(value: 'mingguan', child: Text('Mingguan')),
              DropdownMenuItem(value: 'bulanan', child: Text('Bulanan')),
            ],
            onChanged: (v) => setState(() => _period = v ?? 'bulanan'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Jumlah anggota:'),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: _totalMembers.toDouble(),
                  min: 2, max: 30, divisions: 28,
                  label: '$_totalMembers',
                  onChanged: (v) => setState(() => _totalMembers = v.round()),
                ),
              ),
              Text('$_totalMembers'),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Text('Buat grup'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final group = ArisanGroup(
      id: '',
      name: _nameController.text,
      createdBy: widget.userId,
      totalMembers: _totalMembers,
      nominal: int.tryParse(_nominalController.text) ?? 0,
      period: _period,
      startDate: DateTime.now(),
      status: GroupStatus.draft,
    );
    // TODO: ambil nama user asli dari AuthService/Firestore, bukan placeholder
    await FirestoreService().createGroup(group, widget.userId, 'Kamu');
    if (mounted) Navigator.pop(context);
  }
}
