import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class SessionsSummaryCard extends ConsumerStatefulWidget {
  const SessionsSummaryCard({super.key});

  @override
  ConsumerState<SessionsSummaryCard> createState() => _SessionsSummaryCardState();
}

class _SessionsSummaryCardState extends ConsumerState<SessionsSummaryCard> {
  int _weeklySessions = 0;
  WorkoutLog? _latestLog;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final logs = await db.getWorkoutLogs(from: now.subtract(const Duration(days: 7)));

    if (mounted) {
      setState(() {
        _weeklySessions = logs.length;
        if (logs.isNotEmpty) _latestLog = logs.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.go('/workouts/history'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Workout Sessions',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_weeklySessions ${_weeklySessions == 1 ? 'session' : 'sessions'} this week',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF26496C),
                      ),
                    ),
                    if (_latestLog != null)
                      Text(
                        'Latest: ${_latestLog!.reps} reps @ ${_latestLog!.weight}kg (${DateFormat('MMM d').format(_latestLog!.date)})',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      )
                    else
                      Text(
                        'No workouts logged this week yet',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
