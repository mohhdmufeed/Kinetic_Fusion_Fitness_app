import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class WorkoutLoggerScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  const WorkoutLoggerScreen({super.key, required this.exerciseId});
  @override
  ConsumerState<WorkoutLoggerScreen> createState() =>
      _WorkoutLoggerScreenState();
}

class _WorkoutLoggerScreenState extends ConsumerState<WorkoutLoggerScreen> {
  Exercise? _exercise;
  final List<_SetEntry> _sets = [_SetEntry()];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    final db = ref.read(databaseProvider);
    final ex = await (db.select(db.exercises)
          ..where((t) => t.id.equals(widget.exerciseId)))
        .getSingleOrNull();
    if (mounted) setState(() => _exercise = ex);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    for (final set in _sets) {
      await db.insertWorkoutLog(WorkoutLogsCompanion(
        exerciseId: drift.Value(widget.exerciseId),
        weight: drift.Value(set.weight),
        reps: drift.Value(set.reps),
        sets: const drift.Value(1),
        date: drift.Value(DateTime.now()),
        pendingSync: const drift.Value(true),
      ));
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Workout saved locally ✓'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    context.go('/workouts');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_exercise?.name ?? 'Log Workout'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/workouts'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d').format(DateTime.now()),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sets', style: Theme.of(context).textTheme.titleLarge),
                    IconButton.filled(
                      onPressed: () =>
                          setState(() => _sets.add(_SetEntry())),
                      icon: const Icon(Icons.add_rounded),
                      style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Set headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: const [
                      SizedBox(width: 36),
                      Expanded(
                          child: Text('Weight (kg)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12))),
                      Expanded(
                          child: Text('Reps',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12))),
                      SizedBox(width: 36),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ..._sets.asMap().entries.map((e) => _setRow(e.key, e.value)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _saving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sets.isNotEmpty ? _save : null,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save Workout'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _setRow(int index, _SetEntry set) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${index + 1}',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _numField(
              value: set.weight,
              onChanged: (v) => setState(() => set.weight = v),
              hint: '0',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _numField(
              value: set.reps.toDouble(),
              onChanged: (v) =>
                  setState(() => set.reps = v.toInt()),
              hint: '0',
              isInt: true,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded,
                color: AppColors.error, size: 20),
            onPressed: _sets.length > 1
                ? () => setState(() => _sets.removeAt(index))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _numField({
    required double value,
    required ValueChanged<double> onChanged,
    required String hint,
    bool isInt = false,
  }) {
    final ctrl = TextEditingController(
        text: isInt
            ? value == 0 ? '' : '${value.toInt()}'
            : value == 0 ? '' : '$value');
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
    );
  }
}

class _SetEntry {
  double weight = 0;
  int reps = 0;
}
