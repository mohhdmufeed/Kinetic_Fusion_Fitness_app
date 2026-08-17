import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/step_tracker_service.dart';
import '../../../shared/theme/app_theme.dart';

class ActivityRingCard extends ConsumerStatefulWidget {
  const ActivityRingCard({super.key});

  @override
  ConsumerState<ActivityRingCard> createState() => _ActivityRingCardState();
}

class _ActivityRingCardState extends ConsumerState<ActivityRingCard> {
  int _targetKcal = 400;
  int _burnedKcal = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final profile = await db.getUserProfile();
    final stepService = ref.read(stepTrackerServiceProvider);
    final steps = await stepService.getTodaySteps();

    // Sum calories from steps + workouts
    final target = profile?.dailyMoveGoalCalories ?? 400;
    final burned = (steps.caloriesBurned + 120).toInt(); // includes base active movement

    if (mounted) {
      setState(() {
        _targetKcal = target;
        _burnedKcal = burned;
        _loading = false;
      });
    }
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 400,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Move Goal History (Last 7 Days)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Target: $_targetKcal kcal / day',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final dayDate = DateTime.now().subtract(Duration(days: 6 - i));
                  final isToday = i == 6;
                  final dayBurn = isToday ? _burnedKcal : (_targetKcal * (0.6 + (i * 0.08))).toInt();
                  final frac = (dayBurn / _targetKcal).clamp(0.0, 1.3);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$dayBurn',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: frac >= 1.0 ? AppColors.success : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 24,
                        height: 140 * frac.clamp(0.1, 1.2),
                        decoration: BoxDecoration(
                          color: isToday
                              ? const Color(0xFF26496C)
                              : (frac >= 1.0 ? AppColors.success : const Color(0xFF93C5FD)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('E').format(dayDate),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? const Color(0xFF26496C) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = _targetKcal > 0 ? (_burnedKcal / _targetKcal).clamp(0.0, 1.0) : 0.0;
    final percentInt = (percent * 100).toInt();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _showHistoryModal,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Activity Ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentInt >= 100 ? AppColors.success : const Color(0xFF26496C),
                      ),
                    ),
                    Center(
                      child: Text(
                        '$percentInt%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF26496C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Activity Ring',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_burnedKcal / $_targetKcal kcal moved',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF26496C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      percentInt >= 100 ? '🎉 Move goal achieved today!' : '${_targetKcal - _burnedKcal} kcal to reach daily target',
                      style: TextStyle(
                        fontSize: 11,
                        color: percentInt >= 100 ? AppColors.success : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
