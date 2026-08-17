import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/main_shell.dart';

class MeasurementsScreen extends ConsumerStatefulWidget {
  const MeasurementsScreen({super.key});
  @override
  ConsumerState<MeasurementsScreen> createState() =>
      _MeasurementsScreenState();
}

class _MeasurementsScreenState extends ConsumerState<MeasurementsScreen> {
  List<WeightEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final e = await ref.read(databaseProvider).getWeightEntries();
    if (mounted) setState(() { _entries = e; _loading = false; });
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Weight',
                suffixText: 'kg',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final w = double.tryParse(ctrl.text);
              if (w == null || w <= 0) return;
              await ref.read(databaseProvider).insertWeightEntry(
                    WeightEntriesCompanion(
                      weight: drift.Value(w),
                      date: drift.Value(DateTime.now()),
                      pendingSync: const drift.Value(true),
                    ),
                  );
              if (!mounted) return;
              Navigator.pop(context);
              await _load();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Weight logged ✓'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Weight')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_entries.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        StatChip(
                          value: '${_entries.first.weight}',
                          label: 'Latest (kg)',
                          color: Colors.white,
                        ),
                        StatChip(
                          value: _entries.length > 1
                              ? '${(_entries.first.weight - _entries.last.weight).toStringAsFixed(1)}'
                              : '--',
                          label: 'Change (kg)',
                          color: Colors.white70,
                        ),
                        StatChip(
                          value: '${_entries.length}',
                          label: 'Entries',
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _entries.isEmpty
                      ? EmptyState(
                          icon: Icons.monitor_weight_rounded,
                          title: 'No weight logged',
                          subtitle: 'Tap + to log your weight',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _entries.length,
                          itemBuilder: (_, i) {
                            final e = _entries[i];
                            double? delta;
                            if (i < _entries.length - 1) {
                              delta = e.weight - _entries[i + 1].weight;
                            }
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${e.weight}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: AppColors.primary),
                                  ),
                                ),
                                title: Text(
                                    DateFormat('EEE, MMM d · h:mm a')
                                        .format(e.date),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                trailing: delta != null
                                    ? Text(
                                        '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          color: delta > 0
                                              ? AppColors.warning
                                              : AppColors.success,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
