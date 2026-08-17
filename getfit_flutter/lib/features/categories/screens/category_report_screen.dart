import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../runs/screens/run_tracker_screen.dart';

enum ReportPeriod { day, week, month, year }

class ActivityConfig {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final bool hasDistance;
  final bool hasLaps;
  final bool hasMood;

  const ActivityConfig({
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    this.hasDistance = true,
    this.hasLaps = false,
    this.hasMood = false,
  });
}

class CategoryReportScreen extends ConsumerStatefulWidget {
  final String activityType;

  const CategoryReportScreen({super.key, required this.activityType});

  @override
  ConsumerState<CategoryReportScreen> createState() => _CategoryReportScreenState();
}

class _CategoryReportScreenState extends ConsumerState<CategoryReportScreen> {
  ReportPeriod _period = ReportPeriod.week;
  List<ActivityEntry> _entries = [];
  bool _loading = true;

  static const Map<String, ActivityConfig> _configs = {
    'running': ActivityConfig(
      title: 'Running',
      unit: 'km',
      icon: Icons.directions_run_rounded,
      color: Color(0xFF0284C7),
      hasDistance: true,
    ),
    'cycling': ActivityConfig(
      title: 'Cycling',
      unit: 'km',
      icon: Icons.directions_bike_rounded,
      color: Color(0xFF059669),
      hasDistance: true,
    ),
    'swimming': ActivityConfig(
      title: 'Swimming',
      unit: 'laps',
      icon: Icons.pool_rounded,
      color: Color(0xFF0284C7),
      hasDistance: true,
      hasLaps: true,
    ),
    'hiking': ActivityConfig(
      title: 'Hiking',
      unit: 'km',
      icon: Icons.terrain_rounded,
      color: Color(0xFFD97706),
      hasDistance: true,
    ),
    'walking': ActivityConfig(
      title: 'Walking',
      unit: 'km',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF26496C),
      hasDistance: true,
    ),
    'mindfulness': ActivityConfig(
      title: 'Mindfulness',
      unit: 'mins',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFF8B5CF6),
      hasDistance: false,
      hasMood: true,
    ),
  };

  ActivityConfig get _config =>
      _configs[widget.activityType.toLowerCase()] ??
      ActivityConfig(
        title: widget.activityType.toUpperCase(),
        unit: 'km',
        icon: Icons.fitness_center_rounded,
        color: const Color(0xFF26496C),
      );

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    final db = ref.read(databaseProvider);
    final list = await db.getActivityEntriesByType(widget.activityType);

    if (mounted) {
      setState(() {
        _entries = list;
        _loading = false;
      });
    }
  }

  void _openLogModal() {
    final durCtrl = TextEditingController(text: '30');
    final distCtrl = TextEditingController(text: '5.0');
    final lapsCtrl = TextEditingController(text: '20');
    final moodCtrl = TextEditingController(text: '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log ${_config.title} Session',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  suffixText: 'min',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_config.hasDistance) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: distCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Distance (km)',
                    suffixText: 'km',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_config.hasLaps) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: lapsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Laps (25m pool)',
                    suffixText: 'laps',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              if (_config.hasMood) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: moodCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Session Notes / Mood',
                    hintText: 'e.g. Calm and refreshed',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final mins = int.tryParse(durCtrl.text) ?? 30;
                    final distKm = double.tryParse(distCtrl.text) ?? 0.0;
                    final laps = int.tryParse(lapsCtrl.text) ?? 0;
                    final mood = moodCtrl.text.trim();
                    final cals = mins * 8.5; // calorie burn estimate

                    final db = ref.read(databaseProvider);
                    await db.insertActivityEntry(
                      ActivityEntriesCompanion(
                        activityType: drift.Value(widget.activityType.toLowerCase()),
                        date: drift.Value(DateTime.now()),
                        startTime: drift.Value(DateTime.now().subtract(Duration(minutes: mins))),
                        durationSeconds: drift.Value(mins * 60),
                        distanceMeters: drift.Value(_config.hasDistance ? distKm * 1000.0 : null),
                        laps: drift.Value(_config.hasLaps ? laps : null),
                        caloriesBurned: drift.Value(cals),
                        moodNotes: drift.Value(mood.isNotEmpty ? mood : null),
                        pendingSync: const drift.Value(true),
                      ),
                    );

                    Navigator.of(ctx).pop();
                    _loadEntries();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Save Activity Entry',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryDetail(ActivityEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_config.icon, color: _config.color, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _config.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('EEEE, MMM d, y • h:mm a').format(entry.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metricCol('DURATION', '${entry.durationSeconds ~/ 60} mins'),
                if (_config.hasDistance && entry.distanceMeters != null)
                  _metricCol('DISTANCE', '${(entry.distanceMeters! / 1000.0).toStringAsFixed(2)} km'),
                if (_config.hasLaps && entry.laps != null)
                  _metricCol('LAPS', '${entry.laps} laps'),
                _metricCol('CALORIES', '${entry.caloriesBurned.toInt()} kcal'),
              ],
            ),
            if (entry.moodNotes != null && entry.moodNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Notes: ${entry.moodNotes!}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _metricCol(String label, String val) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _config.color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_config.title} Report'),
        backgroundColor: _config.color,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Period Switcher (Day / Week / Month / Year)
          Container(
            color: _config.color,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _periodTab('Day', ReportPeriod.day),
                  _periodTab('Week', ReportPeriod.week),
                  _periodTab('Month', ReportPeriod.month),
                  _periodTab('Year', ReportPeriod.year),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Chart Container
                      _buildChartCard(),
                      const SizedBox(height: 16),

                      // Section Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activity History (${_entries.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: _openLogModal,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Log Entry'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_entries.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(_config.icon, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No ${_config.title} sessions yet',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap "+ Log Entry" to record your session',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._entries.map((entry) {
                          final dateStr = DateFormat('MMM d, y • h:mm a').format(entry.date);
                          final durMins = entry.durationSeconds ~/ 60;
                          final distKm = (entry.distanceMeters ?? 0) / 1000.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              onTap: () => _showEntryDetail(entry),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _config.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_config.icon, color: _config.color),
                              ),
                              title: Text(
                                _config.hasDistance
                                    ? '${distKm.toStringAsFixed(2)} km in $durMins min'
                                    : '$durMins mins session',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text(dateStr, style: const TextStyle(fontSize: 11)),
                              trailing: Text(
                                '${entry.caloriesBurned.toInt()} kcal',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _config.color,
                                ),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: _config.hasDistance
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/live-session/${widget.activityType}');
              },
              backgroundColor: _config.color,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              label: Text(
                'Start ${_config.title}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: _openLogModal,
              backgroundColor: _config.color,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Log ${_config.title}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Widget _periodTab(String label, ReportPeriod period) {
    final isSelected = _period == period;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _period = period),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? _config.color : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_period.name.toUpperCase()} OVERVIEW',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _config.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _config.unit.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _config.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final dayDate = DateTime.now().subtract(Duration(days: 6 - i));
                  final isToday = i == 6;
                  final val = (1.5 + (i * 0.8)).clamp(0.5, 6.0);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        val.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 20,
                        height: 100 * (val / 6.0),
                        decoration: BoxDecoration(
                          color: isToday ? _config.color : _config.color.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('E').format(dayDate),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
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
}
