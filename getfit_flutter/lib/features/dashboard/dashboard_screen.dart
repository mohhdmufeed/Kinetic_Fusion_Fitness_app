import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import '../../core/auth/auth_service.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/main_shell.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOnline = true;
  bool _syncing = false;
  int _pendingSync = 0;
  List<WeightEntry> _recentWeight = [];
  List<WorkoutLog> _recentLogs = [];
  List<NutritionDiaryData> _todayDiary = [];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadData();
    _triggerSync();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (mounted) setState(() => _isOnline = !results.contains(ConnectivityResult.none));
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final now = DateTime.now();
    final weights = await db.getWeightEntries(limit: 1);
    final logs = await db.getWorkoutLogs(
        from: now.subtract(const Duration(days: 7)));
    final diary = await db.getDiaryForDate(now);
    final pending = await db.getPendingSyncCount();
    if (mounted) {
      setState(() {
        _recentWeight = weights;
        _recentLogs = logs;
        _todayDiary = diary;
        _pendingSync = pending;
      });
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _syncing = true);
    try {
      await ref.read(syncServiceProvider).sync();
      await _loadData();
    } catch (_) {}
    if (mounted) setState(() => _syncing = false);
  }

  double get _todayCalories {
    // We'd need ingredient data; simplified here
    return _todayDiary.length * 200.0;
  }

  @override
  Widget build(BuildContext context) {
    final username = ref.watch(authServiceProvider).getUsername();
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _triggerSync,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppColors.navBarDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.navBarDark,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FutureBuilder<String?>(
                          future: username,
                          builder: (_, snap) => Text(
                            'Hi, ${snap.data ?? 'Athlete'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(today,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (_syncing)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.sync_rounded, color: Colors.white),
                    onPressed: _triggerSync,
                    tooltip: 'Sync now',
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (!_isOnline) const OfflineBanner(),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats row
                        Row(
                          children: [
                            Expanded(
                              child: _statCard(
                                context,
                                icon: Icons.local_fire_department_rounded,
                                color: AppColors.warning,
                                value: '${_todayCalories.toInt()}',
                                unit: 'kcal',
                                label: 'Today',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                context,
                                icon: Icons.monitor_weight_rounded,
                                color: AppColors.primary,
                                value: _recentWeight.isNotEmpty
                                    ? '${_recentWeight.first.weight}'
                                    : '--',
                                unit: 'kg',
                                label: 'Weight',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                context,
                                icon: Icons.fitness_center_rounded,
                                color: AppColors.accent,
                                value: '${_recentLogs.length}',
                                unit: 'sets',
                                label: 'This week',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Quick actions
                        const SectionHeader(title: 'Quick Actions'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _quickAction(
                                context,
                                icon: Icons.fitness_center_rounded,
                                label: 'Log\nWorkout',
                                color: AppColors.primary,
                                onTap: () => context.go('/workouts'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _quickAction(
                                context,
                                icon: Icons.restaurant_rounded,
                                label: 'Log\nMeal',
                                color: AppColors.accent,
                                onTap: () => context.go('/nutrition/diary'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _quickAction(
                                context,
                                icon: Icons.monitor_weight_rounded,
                                label: 'Log\nWeight',
                                color: AppColors.warning,
                                onTap: () => context.go('/measurements'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Recent workouts
                        SectionHeader(
                          title: 'Recent Activity',
                          action: 'See All',
                          onAction: () => context.go('/workouts/history'),
                        ),
                        const SizedBox(height: 12),
                        if (_recentLogs.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Icon(Icons.sports_gymnastics_rounded,
                                      size: 40,
                                      color: Colors.grey.withOpacity(0.5)),
                                  const SizedBox(height: 8),
                                  const Text('No workouts this week',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          )
                        else
                          ...(_recentLogs.take(5).map((log) =>
                              _recentLogTile(context, log))),

                        if (_pendingSync > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cloud_upload_outlined,
                                    color: AppColors.accent, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                    '$_pendingSync item${_pendingSync > 1 ? 's' : ''} pending sync',
                                    style: const TextStyle(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context,
      {required IconData icon,
      required Color color,
      required String value,
      required String unit,
      required String label}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _recentLogTile(BuildContext context, WorkoutLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center_rounded,
              color: AppColors.primary, size: 20),
        ),
        title: Text(
            'Exercise #${log.exerciseId}',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${log.sets} sets × ${log.reps} reps @ ${log.weight}kg'),
        trailing: Text(
          DateFormat('MMM d').format(log.date),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5)),
        ),
      ),
    );
  }
}
