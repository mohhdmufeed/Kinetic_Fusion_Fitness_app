import 'dart:convert';
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
import 'widgets/daily_challenge_card.dart';
import 'widgets/activity_ring_card.dart';
import 'widgets/steps_summary_card.dart';
import 'widgets/distance_summary_card.dart';
import 'widgets/sessions_summary_card.dart';
import 'widgets/awards_summary_card.dart';
import 'widgets/gym_quote_card.dart';
import 'widgets/dashboard_layout_editor_dialog.dart';

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
  UserProfileData? _userProfile;
  List<String> _layoutOrder = ['challenges', 'ring', 'steps', 'distance', 'sessions', 'awards', 'quote'];

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
    final profile = await db.getUserProfile();

    List<String> layout = ['challenges', 'ring', 'steps', 'distance', 'sessions', 'awards', 'quote'];
    if (profile?.summaryLayout != null && profile!.summaryLayout.isNotEmpty) {
      try {
        final decoded = jsonDecode(profile.summaryLayout) as List<dynamic>;
        layout = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _recentWeight = weights;
        _recentLogs = logs;
        _todayDiary = diary;
        _pendingSync = pending;
        _userProfile = profile;
        _layoutOrder = layout;
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

  void _openLayoutEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DashboardLayoutEditorDialog(
        currentOrder: _layoutOrder,
        onSaved: () {
          _loadData();
        },
      ),
    );
  }

  double get _todayCalories {
    return _todayDiary.length * 200.0;
  }

  Widget _buildSummaryCard(String id) {
    switch (id) {
      case 'challenges':
        return const DailyChallengeCard();
      case 'ring':
        return const ActivityRingCard();
      case 'steps':
        return const StepsSummaryCard();
      case 'distance':
        return const DistanceSummaryCard();
      case 'sessions':
        return const SessionsSummaryCard();
      case 'awards':
        return const AwardsSummaryCard();
      case 'quote':
        return const GymQuoteCard();
      default:
        return const SizedBox.shrink();
    }
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
                IconButton(
                  icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                  onPressed: () => context.push('/account'),
                  tooltip: 'Account & Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.dashboard_customize_rounded, color: Colors.white),
                  onPressed: _openLayoutEditor,
                  tooltip: 'Customize Summary Cards',
                ),
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
                        // Quick Stats Row
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
                        const SizedBox(height: 20),

                        // Quick Actions Header & Row
                        const SectionHeader(title: 'Quick Actions'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _quickAction(
                                context,
                                icon: Icons.directions_run_rounded,
                                label: 'Start\nRun',
                                color: const Color(0xFF0284C7),
                                onTap: () => context.push('/run-tracker'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickAction(
                                context,
                                icon: Icons.fitness_center_rounded,
                                label: 'Log\nWorkout',
                                color: AppColors.primary,
                                onTap: () => context.go('/workouts'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _quickAction(
                                context,
                                icon: Icons.restaurant_rounded,
                                label: 'Log\nMeal',
                                color: AppColors.accent,
                                onTap: () => context.go('/nutrition/diary'),
                              ),
                            ),
                            const SizedBox(width: 10),
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
                        const SizedBox(height: 24),

                        // Section Header with Customize button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SectionHeader(title: 'Activity Summary'),
                            TextButton.icon(
                              onPressed: _openLayoutEditor,
                              icon: const Icon(Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                              label: const Text('Customize', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Dynamically Rendered Summary Cards
                        ..._layoutOrder.map((id) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildSummaryCard(id),
                          );
                        }),
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

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String value,
    required String unit,
    required String label,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
