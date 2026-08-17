import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/gps_run_service.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class RunTrackerScreen extends ConsumerStatefulWidget {
  const RunTrackerScreen({super.key});

  @override
  ConsumerState<RunTrackerScreen> createState() => _RunTrackerScreenState();
}

class _RunTrackerScreenState extends ConsumerState<RunTrackerScreen> {
  double _userWeightKg = 70.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(databaseProvider).getUserProfile();
    if (mounted) {
      setState(() {
        _userWeightKg = profile?.weightKg ?? 70.0;
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

  Future<void> _finishRun(ActiveRunSession session) async {
    final service = ref.read(gpsRunServiceProvider);
    await service.stopAndSaveRun(notes: 'Completed GPS Run');

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Text('🎉 Run Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${(session.distanceMeters / 1000).toStringAsFixed(2)} km'),
            const SizedBox(height: 4),
            Text('Duration: ${_formatDuration(session.durationSeconds)}'),
            const SizedBox(height: 4),
            Text('Avg Pace: ${_formatPace(session.avgPaceMinPerKm)} /km'),
            const SizedBox(height: 4),
            Text('Calories: ${session.caloriesBurned.toInt()} kcal'),
            const SizedBox(height: 12),
            const Text(
              'Your route and stats have been saved offline to your run history.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/runs');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26496C),
            ),
            child: const Text('View All Runs', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final gpsService = ref.watch(gpsRunServiceProvider);

    return StreamBuilder<ActiveRunSession>(
      stream: gpsService.sessionStream,
      initialData: gpsService.currentSession,
      builder: (context, snapshot) {
        final session = snapshot.data ?? const ActiveRunSession();
        final isRunning = session.state == RunState.running;
        final isPaused = session.state == RunState.paused;
        final isIdle = session.state == RunState.idle;

        return Scaffold(
          backgroundColor: const Color(0xFF1b2e44),
          appBar: AppBar(
            title: const Text('GPS Run Tracker'),
            backgroundColor: navyColor,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded),
                onPressed: () => context.push('/runs'),
                tooltip: 'Run History',
              ),
            ],
          ),
          body: Column(
            children: [
              // Top Map Route Canvas
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFF101c2b),
                  child: Stack(
                    children: [
                      // Polyline Map Route Painter
                      CustomPaint(
                        size: Size.infinite,
                        painter: RoutePolylinePainter(
                          route: session.route,
                          isRunning: isRunning,
                        ),
                      ),

                      // GPS Status Badge
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isRunning ? Colors.greenAccent : Colors.amberAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isRunning
                                    ? 'GPS Tracking Active'
                                    : (isPaused ? 'GPS Paused' : 'Ready to Start'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Live Distance Overlay Badge
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _liveOverlayMetric(
                                label: 'TIME',
                                value: _formatDuration(session.durationSeconds),
                              ),
                              _liveOverlayMetric(
                                label: 'DISTANCE',
                                value: '${(session.distanceMeters / 1000).toStringAsFixed(2)} km',
                              ),
                              _liveOverlayMetric(
                                label: 'PACE',
                                value: _formatPace(session.avgPaceMinPerKm),
                              ),
                              _liveOverlayMetric(
                                label: 'CALORIES',
                                value: '${session.caloriesBurned.toInt()} kcal',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Controls Section
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Large Timer Display
                      Column(
                        children: [
                          Text(
                            _formatDuration(session.durationSeconds),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF26496C),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Text(
                            'TOTAL DURATION',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      // Controls
                      if (isIdle) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              gpsService.startRun(userWeightKg: _userWeightKg);
                            },
                            icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                            label: const Text(
                              'START RUN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            // Pause / Resume Button
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (isRunning) {
                                      gpsService.pauseRun();
                                    } else {
                                      gpsService.resumeRun();
                                    }
                                  },
                                  icon: Icon(
                                    isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    isRunning ? 'PAUSE' : 'RESUME',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isRunning ? AppColors.warning : AppColors.success,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Stop & Finish Button
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: () => _finishRun(session),
                                  icon: const Icon(Icons.stop_rounded, color: Colors.white),
                                  label: const Text(
                                    'FINISH RUN',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent.shade700,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _liveOverlayMetric({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Custom Painter that renders GPS coordinates as an interactive polyline route map
class RoutePolylinePainter extends CustomPainter {
  final List<GpsPoint> route;
  final bool isRunning;

  RoutePolylinePainter({required this.route, required this.isRunning});

  @override
  void paint(Canvas canvas, Size size) {
    // Grid lines for map aesthetic
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    if (route.isEmpty) {
      // Draw idle center pin
      final center = Offset(size.width / 2, size.height / 2);
      final pinPaint = Paint()..color = const Color(0xFF26496C);
      canvas.drawCircle(center, 12, pinPaint);
      canvas.drawCircle(center, 6, Paint()..color = Colors.white);
      return;
    }

    // Determine coordinate bounding box
    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (final p in route) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    // Add padding to bounds
    final latSpan = (maxLat - minLat).abs().clamp(0.0005, 10.0);
    final lngSpan = (maxLng - minLng).abs().clamp(0.0005, 10.0);

    const padding = 50.0;
    final drawWidth = size.width - (padding * 2);
    final drawHeight = size.height - (padding * 2);

    Offset toOffset(GpsPoint p) {
      final normX = (p.longitude - minLng) / lngSpan;
      final normY = 1.0 - ((p.latitude - minLat) / latSpan);
      return Offset(padding + (normX * drawWidth), padding + (normY * drawHeight));
    }

    // Draw route path line
    final pathPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final firstPoint = toOffset(route.first);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < route.length; i++) {
      final pt = toOffset(route[i]);
      path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path, pathPaint);

    // Draw start point marker (Green)
    final startPaint = Paint()..color = Colors.greenAccent;
    canvas.drawCircle(firstPoint, 7, startPaint);
    canvas.drawCircle(firstPoint, 3, Paint()..color = Colors.white);

    // Draw current runner marker (Blue pulsing circle)
    final lastPoint = toOffset(route.last);
    final runnerPaint = Paint()..color = const Color(0xFF0284C7);
    canvas.drawCircle(lastPoint, 9, runnerPaint);
    canvas.drawCircle(lastPoint, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant RoutePolylinePainter oldDelegate) => true;
}
