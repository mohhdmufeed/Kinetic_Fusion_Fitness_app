import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/motion_widgets.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  int _steps = 8420;
  final int _stepGoal = 10000;
  double _sleepHours = 7.63; // 7h 38m
  int _recoveryScore = 91;
  double _weight = 78.4;
  final double _weightGoal = 76.0;
  int _workoutsCompleted = 4;
  final int _workoutsGoal = 5;
  int _energyBurned = 2640;

  // Configurable widgets state for "Add widget" branch
  final Map<String, bool> _activeWidgets = {
    'Steps': true,
    'Workouts': true,
    'Sleep': true,
    'Weight': true,
    'Kcal burned': true,
  };

  void _showAddWidgetSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
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
                Row(
                  children: [
                    const Icon(Icons.widgets_rounded, color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    const Text('Customize Activity Dashboard', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white60)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Toggle the metric widgets visible on your daily activity telemetry.', style: TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
                const SizedBox(height: 16),
                ..._activeWidgets.keys.map((key) {
                  final isEnabled = _activeWidgets[key] ?? true;
                  return SwitchListTile(
                    title: Text(key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text('Show $key widget card on Activity telemetry', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                    value: isEnabled,
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setModalState(() => _activeWidgets[key] = val);
                      setState(() => _activeWidgets[key] = val);
                    },
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Layout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showStepsDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final progress = (_steps / _stepGoal).clamp(0.0, 1.0);
          final km = (_steps * 0.00078).toStringAsFixed(1);
          final kcal = (_steps * 0.045).round();

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
                          const Text('Steps Telemetry & ML Model', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('7-Day EWMA: 9,120 steps/day (+8% baseline)', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
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
                      Text(NumberFormat('#,###').format(_steps), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                      Text('${(progress * 100).round()}% of daily $_stepGoal step goal', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 13)),
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
                      _sheetStat('Active Time', '${(_steps / 115).round()} min'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Quick Add Steps', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _stepBtn('+500', 500, setSheetState),
                    const SizedBox(width: 8),
                    _stepBtn('+1,000', 1000, setSheetState),
                    const SizedBox(width: 8),
                    _stepBtn('+2,500', 2500, setSheetState),
                    const SizedBox(width: 8),
                    _stepBtn('+5,000', 5000, setSheetState),
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

  void _showWorkoutsDetailSheet(BuildContext context) {
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
                          const Text('Workouts & ACWR Workload', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('ML Model ACWR: 1.05 (Safe Overload Sweet Spot)', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
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
                      _sheetStat('Tonnage (Wk)', '28,450 kg'),
                      _sheetStat('Sets Logged', '48 sets'),
                      _sheetStat('Active Time', '3h 45m'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Muscle Volume Allocation', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _volumeBar('Chest & Triceps', 0.32, '32% (15 sets)'),
                _volumeBar('Legs & Calves', 0.28, '28% (13 sets)'),
                _volumeBar('Back & Biceps', 0.24, '24% (12 sets)'),
                _volumeBar('Shoulders & Core', 0.16, '16% (8 sets)'),
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
                    child: const Text('View All Routine Plans', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSleepDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final hours = _sleepHours.floor();
          final mins = ((_sleepHours - hours) * 60).round();

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
                          const Text('Sleep & Autonomic Recovery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('ML Recovery Score: $_recoveryScore% • Autonomic Primed', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
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
                      _sheetStat('Deep Sleep', '1h 45m'),
                      _sheetStat('REM Sleep', '2h 10m'),
                      _sheetStat('Light Sleep', '3h 43m'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Log / Adjust Sleep Duration', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Slider(
                  value: _sleepHours,
                  min: 4.0,
                  max: 12.0,
                  divisions: 32,
                  activeColor: Colors.purpleAccent,
                  inactiveColor: const Color(0xFF222326),
                  label: '${hours}h ${mins}m',
                  onChanged: (val) {
                    final newScore = (80 + (val - 6.0) * 5).clamp(60, 99).round();
                    setSheetState(() {
                      _sleepHours = val;
                      _recoveryScore = newScore;
                    });
                    setState(() {
                      _sleepHours = val;
                      _recoveryScore = newScore;
                    });
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
                          content: Text('Sleep logged: ${hours}h ${mins}m (Recovery Score: $_recoveryScore%)', style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Sleep Telemetry', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showWeightDetailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final diff = (_weight - _weightGoal).abs().toStringAsFixed(1);

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
                        color: Colors.tealAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.monitor_weight_rounded, color: Colors.tealAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Body Weight & ML Forecast', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('OLS Regression: -0.35 kg/wk • ETA: 4.5 weeks', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
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
                      Text('${_weight.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                      Text('$diff kg to goal (${_weightGoal.toStringAsFixed(1)} kg)', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 13)),
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
                      _sheetStat('30-Day Delta', '-1.4 kg'),
                      _sheetStat('Weekly Rate', '-0.35 kg'),
                      _sheetStat('Body Fat Est.', '14.2%'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Log New Weight (kg)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                Slider(
                  value: _weight,
                  min: 60.0,
                  max: 110.0,
                  divisions: 500,
                  activeColor: Colors.tealAccent,
                  inactiveColor: const Color(0xFF222326),
                  label: '${_weight.toStringAsFixed(1)} kg',
                  onChanged: (val) {
                    setSheetState(() => _weight = val);
                    setState(() => _weight = val);
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
                          content: Text('Weight logged: ${_weight.toStringAsFixed(1)} kg', style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Weigh-In', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEnergyDetailSheet(BuildContext context) {
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
                        color: Colors.amberAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Energy & Caloric Expenditure', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          Text('Deficit: -270 kcal/day (Optimal Fat Loss)', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12)),
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
                      Text(NumberFormat('#,###').format(_energyBurned), style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
                      const Text('Total Kcal Expended Today', style: TextStyle(color: Color(0xFF8E9094), fontSize: 13)),
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
                      _sheetStat('Basal (BMR)', '1,680 kcal'),
                      _sheetStat('Active Burn', '790 kcal'),
                      _sheetStat('TEF (Food)', '170 kcal'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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

  Widget _volumeBar(String label, double ratio, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(count, style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFF1E2024),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(String label, int amount, StateSetter setSheetState) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setSheetState(() => _steps += amount);
          setState(() => _steps += amount);
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
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Profile icon & Add Widget Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Activity',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showAddWidgetSheet,
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
                        tooltip: 'Add widget',
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => context.go('/profile'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 1.5),
                          ),
                          child: const CircleAvatar(
                            radius: 17,
                            backgroundColor: Color(0xFF1E293B),
                            child: Icon(Icons.person_rounded, color: AppColors.primary, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Comprehensive 24/7 movement, training & biological metrics',
                style: TextStyle(color: Color(0xFF8E9094), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // ─── 1. STEPS WIDGET ────────────────────────────────────────────────
              if (_activeWidgets['Steps'] ?? true) ...[
                FadeSlideTransition(
                  child: SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => _showStepsDetailSheet(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141517),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF222326)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.directions_walk_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('Steps Telemetry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                const Spacer(),
                                Text(
                                  '${((_steps / _stepGoal) * 100).round()}% of Goal',
                                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(NumberFormat('#,###').format(_steps), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 8),
                                Text('/ ${NumberFormat('#,###').format(_stepGoal)} steps', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 14)),
                                const Spacer(),
                                Text(
                                  '${(_steps * 0.00078).toStringAsFixed(1)} km • ${(_steps * 0.045).round()} kcal',
                                  style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (_steps / _stepGoal).clamp(0.0, 1.0),
                                backgroundColor: const Color(0xFF1E2024),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ─── 2. WORKOUTS WIDGET ──────────────────────────────────────────────
              if (_activeWidgets['Workouts'] ?? true) ...[
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 50),
                  child: SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => _showWorkoutsDetailSheet(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141517),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF222326)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrangeAccent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.fitness_center_rounded, color: Colors.deepOrangeAccent, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('Workouts Volume', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => context.push('/workouts'),
                                  child: const Text('Logs', style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _MetricColumn(title: 'Tonnage (Wk)', value: '28,450 kg'),
                                _MetricColumn(title: 'Sets Logged', value: '48 sets'),
                                _MetricColumn(title: 'Active Time', value: '3h 45m'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ─── 3. SLEEP WIDGET ────────────────────────────────────────────────
              if (_activeWidgets['Sleep'] ?? true) ...[
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 100),
                  child: SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => _showSleepDetailSheet(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141517),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF222326)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purpleAccent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.bedtime_rounded, color: Colors.purpleAccent, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('Sleep & Autonomic Recovery', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${_sleepHours.floor()}h ${((_sleepHours - _sleepHours.floor()) * 60).round()}m',
                                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 8),
                                const Text('Sleep duration', style: TextStyle(color: Color(0xFF8E9094), fontSize: 13)),
                                const Spacer(),
                                Text('Recovery: $_recoveryScore%', style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Deep: 1h 45m', style: TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                                Text('REM: 2h 10m', style: TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                                Text('Light: 3h 43m', style: TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ─── 4. WEIGHT WIDGET ────────────────────────────────────────────────
              if (_activeWidgets['Weight'] ?? true) ...[
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 150),
                  child: SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => _showWeightDetailSheet(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141517),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF222326)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.tealAccent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.monitor_weight_rounded, color: Colors.tealAccent, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('Weight Trend (kg)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                                const Spacer(),
                                const Text('-1.4 kg (30d)', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(_weight.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 4),
                                const Text('kg', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                const SizedBox(width: 12),
                                Text('Goal: ${_weightGoal.toStringAsFixed(1)} kg', style: const TextStyle(color: Color(0xFF8E9094), fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ─── 5. KCAL BURNED WIDGET ──────────────────────────────────────────
              if (_activeWidgets['Kcal burned'] ?? true) ...[
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => _showEnergyDetailSheet(context),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141517),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF222326)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Text('Energy Burned (Kcal)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(NumberFormat('#,###').format(_energyBurned), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                                const SizedBox(width: 4),
                                const Text('kcal total', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                const Spacer(),
                                const Text('Active: 790 kcal', style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Add Widget Button Card
              InkWell(
                onTap: _showAddWidgetSheet,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141517),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF222326)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Add / Rearrange Widgets', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String title;
  final String value;
  const _MetricColumn({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
