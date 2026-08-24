import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/gps_run_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../runs/screens/run_tracker_screen.dart';
import '../widgets/mini_music_player.dart';
import '../widgets/session_summary_dialog.dart';

class LiveWorkoutScreen extends ConsumerStatefulWidget {
  final String activityType;
  final int? wishlistId;

  const LiveWorkoutScreen({
    super.key,
    required this.activityType,
    this.wishlistId,
  });

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen> {
  bool _isStarted = false;
  bool _isPaused = false;
  int _activeSeconds = 0;
  int _pausedSeconds = 0;
  Timer? _timer;
  DateTime? _startTime;

  double _distanceMeters = 0.0;
  double _caloriesBurned = 0.0;
  double _currentPace = 0.0;
  final List<GpsPoint> _routePoints = [];
  String _inSessionNotes = '';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startSession() {
    setState(() {
      _isStarted = true;
      _isPaused = false;
      _startTime = DateTime.now();
      _activeSeconds = 0;
      _pausedSeconds = 0;
      _routePoints.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) {
        setState(() {
          _activeSeconds++;
          _distanceMeters = _activeSeconds * 2.8; // ~10 km/h estimated pacing
          _caloriesBurned = _activeSeconds * 0.18; // ~11 kcal/min
          final distKm = _distanceMeters / 1000.0;
          _currentPace = distKm > 0 ? (_activeSeconds / 60.0) / distKm : 0.0;
        });
      } else {
        setState(() {
          _pausedSeconds++;
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _openQuickNote() {
    final ctrl = TextEditingController(text: _inSessionNotes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('In-Session Note'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'e.g. Heart rate feeling great, pacing smoothly',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _inSessionNotes = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishSession() async {
    _timer?.cancel();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SessionSummaryDialog(
        activityType: widget.activityType,
        startTime: _startTime ?? DateTime.now(),
        activeDurationSeconds: _activeSeconds,
        pausedDurationSeconds: _pausedSeconds,
        distanceMeters: _distanceMeters,
        caloriesBurned: _caloriesBurned,
        routePoints: _routePoints,
        initialNotes: _inSessionNotes,
        linkedWishlistId: widget.wishlistId,
      ),
    );

    if (saved == true && mounted) {
      context.pop();
    }
  }

  String _formatTimer(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final distKm = _distanceMeters / 1000.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Text(
          'Live ${widget.activityType.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isStarted)
            IconButton(
              icon: const Icon(Icons.note_alt_outlined, color: Colors.white),
              onPressed: _openQuickNote,
              tooltip: 'Quick Note',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Live Map Canvas
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      if (_routePoints.isNotEmpty)
                        CustomPaint(
                          painter: RoutePolylinePainter(
                            route: _routePoints,
                            isRunning: !_isPaused,
                          ),
                          size: Size.infinite,
                        )
                      else
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_run_rounded, size: 48, color: Color(0xFF38BDF8)),
                              SizedBox(height: 12),
                              Text(
                                'Cardio Session Telemetry',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 6),
                              Text(
                                '🛰️ Live GPS Map — Hardware integration coming soon',
                                style: TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                            ],
                          ),
                        ),

                      // Status Pill
                      if (_isStarted)
                        Positioned(
                          top: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isPaused ? Colors.amber.shade700 : AppColors.success,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(_isPaused ? Icons.pause : Icons.play_arrow, size: 14, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  _isPaused ? 'PAUSED (${_formatTimer(_pausedSeconds)})' : 'RECORDING',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Mini Music Player
            const MiniMusicPlayer(),

            // Stats Heads-Up Display
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Main Stopwatch Timer
                  Text(
                    _formatTimer(_activeSeconds),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _liveMetric('DISTANCE', '${distKm.toStringAsFixed(2)} km'),
                      _liveMetric('PACE', '${_currentPace.toStringAsFixed(1)} min/km'),
                      _liveMetric('CALORIES', '${_caloriesBurned.toInt()} kcal'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons (Start / Pause / Finish)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: !_isStarted
                  ? SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                        label: Text(
                          'START ${widget.activityType.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _togglePause,
                              icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: Colors.white),
                              label: Text(_isPaused ? 'Resume' : 'Pause', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isPaused ? AppColors.success : Colors.amber.shade700,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _finishSession,
                              icon: const Icon(Icons.stop_rounded, color: Colors.white),
                              label: const Text('Finish', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _liveMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
