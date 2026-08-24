import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/services/gps_run_service.dart';
import 'run_tracker_screen.dart';

class RunHistoryScreen extends ConsumerStatefulWidget {
  const RunHistoryScreen({super.key});

  @override
  ConsumerState<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends ConsumerState<RunHistoryScreen> {
  List<RunSession> _runs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    final runs = await ref.read(databaseProvider).getRunSessions();
    if (mounted) {
      setState(() {
        _runs = runs;
        _loading = false;
      });
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final h = (seconds ~/ 3600);
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  String _formatPace(double paceMinPerKm) {
    if (paceMinPerKm <= 0 || paceMinPerKm.isInfinite || paceMinPerKm > 30) {
      return '--:--';
    }
    final mins = paceMinPerKm.toInt();
    final secs = ((paceMinPerKm - mins) * 60).toInt().toString().padLeft(2, '0');
    return '$mins\'$secs"';
  }

  void _showRunDetails(RunSession run) {
    List<GpsPoint> points = [];
    try {
      final decoded = jsonDecode(run.routePointsJson) as List<dynamic>;
      points = decoded.map((p) => GpsPoint.fromJson(p as Map<String, dynamic>)).toList();
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d, y • h:mm a').format(run.startTime),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        points.isNotEmpty ? 'Route Replay' : 'Cardio Session Summary',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            // Map / Telemetry Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF101c2b),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: points.isNotEmpty
                      ? CustomPaint(
                          size: Size.infinite,
                          painter: RoutePolylinePainter(
                            route: points,
                            isRunning: false,
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.directions_run_rounded, size: 48, color: Color(0xFF859463)),
                              SizedBox(height: 12),
                              Text(
                                'Cardio Session Recorded',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Telemetry saved to local SQLite store',
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            // Stats Grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCol('DISTANCE', '${(run.distanceMeters / 1000).toStringAsFixed(2)} km'),
                  _statCol('TIME', _formatDuration(run.durationSeconds)),
                  _statCol('PACE', '${_formatPace(run.avgPaceMinPerKm)} /km'),
                  _statCol('CALORIES', '${run.caloriesBurned.toInt()} kcal'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF26496C)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session History'),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _runs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_run_rounded, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No runs recorded yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start your first run to track duration, distance & pace',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/run-tracker'),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: const Text('Start Run', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: navyColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _runs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final run = _runs[idx];
                    final dateStr = DateFormat('MMM d, y • h:mm a').format(run.startTime);

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: InkWell(
                        onTap: () => _showRunDetails(run),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: navyColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.directions_run_rounded,
                                          color: navyColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        dateStr,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _metricItem(
                                    label: 'Distance',
                                    val: '${(run.distanceMeters / 1000).toStringAsFixed(2)} km',
                                  ),
                                  _metricItem(
                                    label: 'Duration',
                                    val: _formatDuration(run.durationSeconds),
                                  ),
                                  _metricItem(
                                    label: 'Pace',
                                    val: '${_formatPace(run.avgPaceMinPerKm)}/km',
                                  ),
                                  _metricItem(
                                    label: 'Burn',
                                    val: '${run.caloriesBurned.toInt()} kcal',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/run-tracker'),
        backgroundColor: navyColor,
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text('Start Run', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _metricItem({required String label, required String val}) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
