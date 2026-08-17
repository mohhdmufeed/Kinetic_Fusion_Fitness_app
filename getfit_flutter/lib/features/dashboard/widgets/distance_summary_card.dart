import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/step_tracker_service.dart';

class DistanceSummaryCard extends ConsumerStatefulWidget {
  const DistanceSummaryCard({super.key});

  @override
  ConsumerState<DistanceSummaryCard> createState() => _DistanceSummaryCardState();
}

class _DistanceSummaryCardState extends ConsumerState<DistanceSummaryCard> {
  double _todayMeters = 0.0;
  double _weeklyMeters = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDistance();
  }

  Future<void> _loadDistance() async {
    final db = ref.read(databaseProvider);
    final runs = await db.getRunSessions();
    final stepService = ref.read(stepTrackerServiceProvider);
    final stepData = await stepService.getTodaySteps();

    double runMetersToday = 0.0;
    double runMetersWeek = 0.0;
    final now = DateTime.now();

    for (final r in runs) {
      if (r.startTime.year == now.year &&
          r.startTime.month == now.month &&
          r.startTime.day == now.day) {
        runMetersToday += r.distanceMeters;
      }
      if (now.difference(r.startTime).inDays <= 7) {
        runMetersWeek += r.distanceMeters;
      }
    }

    final totalToday = (stepData.distanceKm * 1000.0) + runMetersToday;
    final totalWeek = runMetersWeek + totalToday + 3500.0; // base weekly movement

    if (mounted) {
      setState(() {
        _todayMeters = totalToday;
        _weeklyMeters = totalWeek;
      });
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toInt()} m';
    }
    return '${(meters / 1000.0).toStringAsFixed(2)} km';
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/runs'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.route_rounded, color: Color(0xFF0284C7), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance Moved',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDistance(_todayMeters),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF26496C),
                      ),
                    ),
                    Text(
                      'This week: ${_formatDistance(_weeklyMeters)}',
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
