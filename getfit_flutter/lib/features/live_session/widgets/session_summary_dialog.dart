import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../core/services/gps_run_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../runs/screens/run_tracker_screen.dart';

class SessionSummaryDialog extends ConsumerStatefulWidget {
  final String activityType;
  final DateTime startTime;
  final int activeDurationSeconds;
  final int pausedDurationSeconds;
  final double distanceMeters;
  final double caloriesBurned;
  final List<GpsPoint> routePoints;
  final String initialNotes;
  final int? linkedWishlistId;

  const SessionSummaryDialog({
    super.key,
    required this.activityType,
    required this.startTime,
    required this.activeDurationSeconds,
    required this.pausedDurationSeconds,
    required this.distanceMeters,
    required this.caloriesBurned,
    required this.routePoints,
    this.initialNotes = '',
    this.linkedWishlistId,
  });

  @override
  ConsumerState<SessionSummaryDialog> createState() => _SessionSummaryDialogState();
}

class _SessionSummaryDialogState extends ConsumerState<SessionSummaryDialog> {
  late TextEditingController _notesCtrl;
  bool _isFavorite = false;
  int? _selectedWishlistId;
  List<WishlistItem> _availableGoals = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl = TextEditingController(text: widget.initialNotes);
    _selectedWishlistId = widget.linkedWishlistId;
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    final db = ref.read(databaseProvider);
    final items = await db.getWishlistItems(activityType: widget.activityType);
    if (mounted) {
      setState(() {
        _availableGoals = items.where((i) => !i.isCompleted).toList();
      });
    }
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _saveSession() async {
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);

    final pointsJson = widget.routePoints.map((p) => p.toJson()).toList();

    final activityId = await db.insertActivityEntry(
      ActivityEntriesCompanion(
        activityType: drift.Value(widget.activityType.toLowerCase()),
        date: drift.Value(DateTime.now()),
        startTime: drift.Value(widget.startTime),
        durationSeconds: drift.Value(widget.activeDurationSeconds),
        pausedDurationSeconds: drift.Value(widget.pausedDurationSeconds),
        distanceMeters: drift.Value(widget.distanceMeters),
        routePointsJson: drift.Value(pointsJson.toString()),
        caloriesBurned: drift.Value(widget.caloriesBurned),
        moodNotes: drift.Value(_notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null),
        isFavorite: drift.Value(_isFavorite),
        pendingSync: const drift.Value(true),
      ),
    );

    // If linked to a wishlist goal, complete it
    if (_selectedWishlistId != null) {
      await db.completeWishlistItem(_selectedWishlistId!, completedActivityId: activityId);
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final distKm = widget.distanceMeters / 1000.0;
    final pace = distKm > 0 ? (widget.activeDurationSeconds / 60.0) / distKm : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.activityType.toUpperCase()} SUMMARY',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyColor),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: _isFavorite ? Colors.amber : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () => setState(() => _isFavorite = !_isFavorite),
                      tooltip: 'Mark as Favorite',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statTile('MOVING TIME', _formatDuration(widget.activeDurationSeconds)),
                          _statTile('DISTANCE', '${distKm.toStringAsFixed(2)} km'),
                          _statTile('CALORIES', '${widget.caloriesBurned.toInt()} kcal'),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statTile('AVG PACE', '${pace.toStringAsFixed(1)} min/km'),
                          _statTile('PAUSED TIME', _formatDuration(widget.pausedDurationSeconds)),
                          _statTile('TOTAL TIME', _formatDuration(widget.activeDurationSeconds + widget.pausedDurationSeconds)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comments / Notes Field
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Workout Notes & Comments',
                    hintText: 'How was the terrain, energy level, or weather?',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Wishlist Goal Linking
                if (_availableGoals.isNotEmpty) ...[
                  DropdownButtonFormField<int>(
                    value: _selectedWishlistId,
                    decoration: InputDecoration(
                      labelText: 'Complete a Wishlist Goal (Optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.flag_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('None / Regular workout'),
                      ),
                      ..._availableGoals.map((g) => DropdownMenuItem<int>(
                            value: g.id,
                            child: Text(g.title),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedWishlistId = val),
                  ),
                  const SizedBox(height: 20),
                ],

                // Route Map Preview Canvas
                if (widget.routePoints.isNotEmpty) ...[
                  const Text('Route Map', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: RoutePolylinePainter(
                          route: widget.routePoints,
                          isRunning: false,
                        ),
                        size: const Size(double.infinity, 160),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save to Activity History',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String val) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF26496C))),
      ],
    );
  }
}
