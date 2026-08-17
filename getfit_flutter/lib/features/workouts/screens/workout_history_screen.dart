import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});
  @override
  ConsumerState<WorkoutHistoryScreen> createState() =>
      _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  List<WorkoutLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await ref.read(databaseProvider).getWorkoutLogs();
    if (mounted) setState(() { _logs = logs; _loading = false; });
  }

  Map<String, List<WorkoutLog>> get _grouped {
    final map = <String, List<WorkoutLog>>{};
    for (final log in _logs) {
      final key = DateFormat('yyyy-MM-dd').format(log.date);
      (map[key] ??= []).add(log);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(
                  child: Text('No workouts logged yet',
                      style: TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _grouped.entries.map((entry) {
                    final date = DateTime.parse(entry.key);
                    final label = DateFormat('EEEE, MMMM d').format(date);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primary)),
                        ),
                        ...entry.value.map((log) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const Icon(
                                    Icons.fitness_center_rounded,
                                    color: AppColors.primary),
                                title: Text(
                                    'Exercise #${log.exerciseId}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    '${log.reps} reps @ ${log.weight}kg'),
                                trailing: log.pendingSync
                                    ? const Tooltip(
                                        message: 'Pending sync',
                                        child: Icon(
                                            Icons.cloud_upload_outlined,
                                            size: 16,
                                            color: AppColors.accent),
                                      )
                                    : const Icon(Icons.cloud_done_outlined,
                                        size: 16,
                                        color: AppColors.success),
                              ),
                            )),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
