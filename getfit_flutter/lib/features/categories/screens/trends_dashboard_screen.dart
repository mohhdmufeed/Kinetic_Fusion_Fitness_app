import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class TrendsDashboardScreen extends ConsumerStatefulWidget {
  const TrendsDashboardScreen({super.key});

  @override
  ConsumerState<TrendsDashboardScreen> createState() => _TrendsDashboardScreenState();
}

class _TrendsDashboardScreenState extends ConsumerState<TrendsDashboardScreen> {
  double? _initialWeight;
  double? _latestWeight;
  int _moveGoalTarget = 400;
  int _workoutCountMonth = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    final db = ref.read(databaseProvider);
    final weights = await db.getWeightEntries(limit: 10);
    final profile = await db.getUserProfile();
    final logs = await db.getWorkoutLogs(
      from: DateTime.now().subtract(const Duration(days: 30)),
    );

    if (mounted) {
      setState(() {
        if (weights.isNotEmpty) {
          _latestWeight = weights.first.weight;
          _initialWeight = weights.last.weight;
        }
        _moveGoalTarget = profile?.dailyMoveGoalCalories ?? 400;
        _workoutCountMonth = logs.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final weightDiff = (_latestWeight != null && _initialWeight != null)
        ? (_latestWeight! - _initialWeight!)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trends & Long-Term Health'),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // "Am I Improving?" Hero Diagnosis
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          navyColor,
                          const Color(0xFF1b3550),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text('📈', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              'Overall Trajectory',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Consistent & Progressing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your 30-day activity volume and move goal consistency are trending in the top tier.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Trend Grid Cards
                _trendCard(
                  title: 'Body Weight (30 Days)',
                  icon: Icons.monitor_weight_rounded,
                  color: AppColors.primary,
                  mainStat: _latestWeight != null ? '${_latestWeight!.toStringAsFixed(1)} kg' : '-- kg',
                  deltaText: weightDiff == 0
                      ? 'Steady / No change'
                      : '${weightDiff > 0 ? '+' : ''}${weightDiff.toStringAsFixed(1)} kg over 30d',
                  isPositive: weightDiff <= 0,
                ),
                const SizedBox(height: 12),

                _trendCard(
                  title: 'Move Goal Consistency',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.warning,
                  mainStat: '86% Met',
                  deltaText: '24 of last 28 days above $_moveGoalTarget kcal',
                  isPositive: true,
                ),
                const SizedBox(height: 12),

                _trendCard(
                  title: 'Workout Sessions Volume',
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.accent,
                  mainStat: '$_workoutCountMonth Sets Logged',
                  deltaText: '+14% volume vs previous 30-day period',
                  isPositive: true,
                ),
                const SizedBox(height: 12),

                _trendCard(
                  title: 'Daily Step Average',
                  icon: Icons.directions_walk_rounded,
                  color: const Color(0xFF0284C7),
                  mainStat: '7,840 steps / day',
                  deltaText: '+620 steps/day weekly moving average',
                  isPositive: true,
                ),
              ],
            ),
    );
  }

  Widget _trendCard({
    required String title,
    required IconData icon,
    required Color color,
    required String mainStat,
    required String deltaText,
    required bool isPositive,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mainStat,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF26496C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up_rounded : Icons.trending_flat_rounded,
                        size: 16,
                        color: isPositive ? AppColors.success : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          deltaText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isPositive ? AppColors.success : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
