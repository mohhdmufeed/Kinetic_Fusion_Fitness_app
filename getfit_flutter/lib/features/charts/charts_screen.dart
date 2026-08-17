import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});
  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<WeightEntry> _weights = [];
  List<WorkoutLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final w = await db.getWeightEntries(limit: 30);
    final l = await db.getWorkoutLogs(
        from: DateTime.now().subtract(const Duration(days: 30)));
    if (mounted) setState(() { _weights = w; _logs = l; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Charts'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Body Weight'),
            Tab(text: 'Workouts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _weightChart(),
          _workoutChart(),
        ],
      ),
    );
  }

  Widget _weightChart() {
    if (_weights.length < 2) {
      return const Center(
        child: Text('Log at least 2 weight entries to see a chart',
            style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
      );
    }
    final sorted = [..._weights]..sort((a, b) => a.date.compareTo(b.date));
    final spots = sorted.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();
    final minY =
        sorted.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 1;
    final maxY =
        sorted.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last ${sorted.length} entries',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white10,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}kg',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: (sorted.length / 5).ceilToDouble(),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= sorted.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          DateFormat('d/M').format(sorted[i].date),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _workoutChart() {
    if (_logs.isEmpty) {
      return const Center(
        child: Text('Log some workouts to see volume charts',
            style: TextStyle(color: Colors.grey)),
      );
    }
    // Group by day
    final byDay = <String, int>{};
    for (final log in _logs) {
      final key = DateFormat('MM/dd').format(log.date);
      byDay[key] = (byDay[key] ?? 0) + log.reps;
    }
    final entries = byDay.entries.toList();
    final bars = entries.asMap().entries
        .map((e) => BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  color: AppColors.accent,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6)),
                ),
              ],
            ))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Reps Per Day (last 30 days)',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white10, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(entries[i].key,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.grey));
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: bars,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
