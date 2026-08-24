import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/motion_widgets.dart';
import 'widgets/why_summary_sheet.dart';
import '../../kinetic/kinetic_core.dart';
import '../ai_assistant/ai_assistant_sheet.dart';
import '../schedule/screens/schedule_sheet.dart';
import '../notifications/screens/notifications_sheet.dart';

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
  TodayViewModel? _kineticToday;
  int _trackedSteps = 8420;
  final int _stepGoal = 10000;
  double _trackedSleepHours = 8.25;
  int _trackedSleepScore = 92;
  int _workoutsCompleted = 4;
  final int _workoutsGoal = 5;

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

    // Kinetic Intelligence Engine
    final store = KineticStore.instance;
    if (store.getMeasurements().isEmpty) {
      final sim = KineticSimulator.generateHistory(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 30,
        seed: 42,
      );
      store.recordMeasurementsBatch(sim.measurements);
      final hrvHistory = store.getMeasurements(metric: 'hrv_rmssd').map((m) => m.value).toList();
      final rhrHistory = store.getMeasurements(metric: 'rhr').map((m) => m.value).toList();
      final sleepHistory = store.getMeasurements(metric: 'sleep_duration_hrs').map((m) => m.value).toList();
      store.setBaseline(BaselineEngine.computeBaseline('hrv_rmssd', hrvHistory));
      store.setBaseline(BaselineEngine.computeBaseline('rhr', rhrHistory));
      store.setBaseline(BaselineEngine.computeBaseline('sleep_duration_hrs', sleepHistory));
    }

    final todayService = TodayService(store: store);
    final kineticToday = await todayService.getToday();

    if (mounted) {
      setState(() {
        _recentWeight = weights;
        _recentLogs = logs;
        _todayDiary = diary;
        _pendingSync = pending;
        _userProfile = profile;
        _kineticToday = kineticToday;
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

  void _showWorkoutsTrackerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0E0F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Color(0xFF222326), width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.deepOrangeAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center_rounded, color: Colors.deepOrangeAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Workouts Tracker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('$_workoutsCompleted of $_workoutsGoal sessions completed', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141517),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF222326)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _sheetStat('Tonnage', '28,450 kg'),
                      _sheetStat('Sets Logged', '48 sets'),
                      _sheetStat('Active Time', '3h 45m'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Recent Completed Sessions', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _sessionRow('Chest & Triceps Hypertrophy', 'Today • 45 min • 320 kcal'),
                _sessionRow('Legs & Core Power', 'Yesterday • 60 min • 480 kcal'),
                _sessionRow('Back & Biceps Volume', '2 days ago • 50 min • 390 kcal'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/workouts/active');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text('Start Workout #${_workoutsCompleted + 1} Now', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/workouts');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF222326)),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Browse All Workout Routines', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStepsTrackerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final progress = (_trackedSteps / _stepGoal).clamp(0.0, 1.0);
          final km = (_trackedSteps * 0.00078).toStringAsFixed(1);
          final kcal = (_trackedSteps * 0.045).round();

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0E0F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Color(0xFF222326), width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                      ),
                      child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Step Tracker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('${(progress * 100).round()}% of daily $_stepGoal step goal', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text('$_trackedSteps', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                      const Text('steps recorded today', style: TextStyle(color: Color(0xFF8E9094), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFF1E2024),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141517),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF222326)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _sheetStat('Distance', '$km km'),
                      _sheetStat('Energy Burn', '$kcal kcal'),
                      _sheetStat('Active Time', '${(_trackedSteps / 115).round()} min'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Quick Add Steps', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _stepAddButton('+500', 500, setSheetState),
                    const SizedBox(width: 8),
                    _stepAddButton('+1,000', 1000, setSheetState),
                    const SizedBox(width: 8),
                    _stepAddButton('+2,500', 2500, setSheetState),
                    const SizedBox(width: 8),
                    _stepAddButton('+5,000', 5000, setSheetState),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/run-tracker');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.gps_fixed_rounded),
                    label: const Text('Start Live GPS Walk / Run', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSleepTrackerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final hours = _trackedSleepHours.floor();
          final mins = ((_trackedSleepHours - hours) * 60).round();

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0E0F),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: Color(0xFF222326), width: 1.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.bedtime_rounded, color: Colors.purpleAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Daily Sleep & Recovery Monitor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('Quality Score: $_trackedSleepScore% • Optimal Rest', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Text('${hours}h ${mins}m', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                      const Text('Total Duration Last Night', style: TextStyle(color: Color(0xFF8E9094), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141517),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF222326)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _sheetStat('Deep Sleep', '1h 48m'),
                      _sheetStat('REM Sleep', '2h 10m'),
                      _sheetStat('Efficiency', '92%'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Adjust Sleep Duration', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Slider(
                  value: _trackedSleepHours,
                  min: 4.0,
                  max: 12.0,
                  divisions: 32,
                  activeColor: Colors.purpleAccent,
                  inactiveColor: const Color(0xFF222326),
                  label: '${hours}h ${mins}m',
                  onChanged: (val) {
                    setSheetState(() => _trackedSleepHours = val);
                    setState(() => _trackedSleepHours = val);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF161719),
                          content: Text('Sleep logged: ${hours}h ${mins}m (Recovery Score: $_trackedSleepScore%)', style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Sleep Log', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetStat(String label, String val) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
      ],
    );
  }

  Widget _sessionRow(String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161719),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222326)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                Text(sub, style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepAddButton(String label, int amount, StateSetter setSheetState) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setSheetState(() => _trackedSteps += amount);
          setState(() => _trackedSteps += amount);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF222326)),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('EEEE, d MMMM').format(DateTime.now());
    final workoutHeadline = _kineticToday?.primaryRecommendation.headline ?? 'Upper-body\nstrength';
    final rationale = _kineticToday?.primaryRecommendation.rationale ??
        'Recovery and training trajectory support a normal progressive push today.';
    final recoveryScore = _kineticToday?.currentState.recoveryScore.round() ?? 88;
    final targetCals = _kineticToday?.nutritionTarget.energyKcal.round() ?? 2370;
    final targetSleepHours = _kineticToday?.sleepTarget.targetDurationHours ?? 7.5;
    final sleepHours = targetSleepHours.floor();
    final sleepMinutes = ((targetSleepHours - sleepHours) * 60).round();

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/gym_panoramic.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.bgDark,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ─── 1. TOP HEADER (Profile, Notifications, Schedule) ──────────────
              FadeSlideTransition(
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/profile'),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF1E293B),
                          child: Text(
                            (_userProfile?.username.isNotEmpty ?? false)
                                ? _userProfile!.username.substring(0, 1).toUpperCase()
                                : 'N',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'KINETIC',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            todayStr,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Schedule Button
                    IconButton(
                      onPressed: () => ScheduleSheet.show(context),
                      icon: const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 22),
                      tooltip: 'Schedule',
                    ),
                    // Notifications Button
                    IconButton(
                      onPressed: () => NotificationsSheet.show(context),
                      icon: const Stack(
                        children: [
                          Icon(Icons.notifications_outlined, color: Colors.white70, size: 23),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
                          ),
                        ],
                      ),
                      tooltip: 'Notifications',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── 2. KEEP WORKING ON YOUR PROGRAM ────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B2A3E), Color(0xFF0F1826)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF2C405B), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 13),
                                SizedBox(width: 4),
                                Text(
                                  'ACTIVE PROGRAM',
                                  style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Week 3 / 8',
                            style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Keep working on your program',
                        style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workoutHeadline.replaceAll('\n', ' '),
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rationale,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: 0.65,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => context.push('/workouts/active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: const Text('Resume Workout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (_) => WhySummarySheet(
                                  headline: workoutHeadline,
                                  rationale: rationale,
                                  recoveryScore: recoveryScore,
                                  sleepHours: targetSleepHours,
                                  targetCalories: targetCals,
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Why this?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── 3. YOUR ACTIVITY (Workout completed, Steps, Sleep) ───────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your activity',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        InkWell(
                          onTap: () => context.go('/activity'),
                          child: const Text(
                            'See all',
                            style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // 1. Workout completed card (Clickable & Trackable)
                        Expanded(
                          child: InkWell(
                            onTap: () => _showWorkoutsTrackerSheet(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141517),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF222326)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrangeAccent.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.fitness_center_rounded, color: Colors.deepOrangeAccent, size: 18),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Workouts', style: TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text('$_workoutsCompleted / $_workoutsGoal', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 2),
                                  const Text('Completed this wk', style: TextStyle(color: Color(0xFF8E9094), fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 2. Daily steps card (Clickable & Trackable)
                        Expanded(
                          child: InkWell(
                            onTap: () => _showStepsTrackerSheet(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141517),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF222326)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 18),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Daily steps', style: TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    NumberFormat('#,###').format(_trackedSteps),
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Goal ${NumberFormat('#,###').format(_stepGoal)}', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // 3. Daily sleep card (Clickable & Trackable)
                        Expanded(
                          child: InkWell(
                            onTap: () => _showSleepTrackerSheet(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141517),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF222326)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.purpleAccent.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.bedtime_rounded, color: Colors.purpleAccent, size: 18),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('Daily sleep', style: TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_trackedSleepHours.floor()}h ${((_trackedSleepHours - _trackedSleepHours.floor()) * 60).round()}m',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Score: $_trackedSleepScore%', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── 4. NEED ADVICE -> AI ASSISTANT BANNER ──────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () => AIAssistantSheet.show(context),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141517),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.18),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Need advice?',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Chat with your Offline AI Coach',
                                  style: TextStyle(color: Color(0xFF8E9094), fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Ask AI',
                              style: TextStyle(color: Color(0xFF0D0E0F), fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── 5. RECOMMENDED WORKOUTS ────────────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recommended workouts',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        InkWell(
                          onTap: () => context.go('/explore'),
                          child: const Text('Explore', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildWorkoutCard(
                            context: context,
                            title: 'Hypertrophy Pull Complex',
                            level: 'Advanced',
                            time: '50 min',
                            category: 'Back & Biceps',
                            color: Colors.tealAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildWorkoutCard(
                            context: context,
                            title: 'Metabolic Power Conditioning',
                            level: 'Intermediate',
                            time: '35 min',
                            category: 'Full Body HIIT',
                            color: Colors.deepOrangeAccent,
                          ),
                          const SizedBox(width: 12),
                          _buildWorkoutCard(
                            context: context,
                            title: 'Posterior Chain Peaking',
                            level: 'Expert',
                            time: '60 min',
                            category: 'Deadlift & Glutes',
                            color: Colors.amberAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── 6. POPULAR PROGRAMS ────────────────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Popular programs',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        InkWell(
                          onTap: () => context.go('/explore'),
                          child: const Text('View all', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildProgramRow(
                      title: 'Kinetic Titan: 12-Week Pure Strength',
                      duration: '12 Weeks • 4 Days/Wk',
                      enrolled: '1,420 athletes',
                      rating: '4.9 ★',
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 10),
                    _buildProgramRow(
                      title: 'Hyper-Engine: Athletic Conditioning',
                      duration: '8 Weeks • 5 Days/Wk',
                      enrolled: '980 athletes',
                      rating: '4.8 ★',
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(height: 10),
                    _buildProgramRow(
                      title: 'Sculpt & Lean: Recomposition Protocol',
                      duration: '6 Weeks • 4 Days/Wk',
                      enrolled: '2,150 athletes',
                      rating: '4.9 ★',
                      color: Colors.pinkAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildWorkoutCard({
    required BuildContext context,
    required String title,
    required String level,
    required String time,
    required String category,
    required Color color,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF222F42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(level, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              Text(time, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          const Spacer(),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(category, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/workouts/active'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D283A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Start', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramRow({
    required String title,
    required String duration,
    required String enrolled,
    required String rating,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF202B3B)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.military_tech_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(duration, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(enrolled, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(rating, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
        ],
      ),
    );
  }
}
