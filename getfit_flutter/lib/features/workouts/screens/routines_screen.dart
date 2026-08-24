import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/motion_widgets.dart';
import '../../../kinetic/domain/models.dart' as kinetic;
import '../../../kinetic/persistence/kinetic_store.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});
  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  List<Exercise> _exercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final db = ref.read(databaseProvider);
    final exList = await db.getAllExercises();
    if (mounted) {
      setState(() {
        _exercises = exList;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _displayExercises {
    if (_exercises.isEmpty) {
      return const [
        {'id': 1, 'name': 'Barbell Bench Press', 'sets': '4×8', 'category': 'Chest'},
        {'id': 2, 'name': 'Incline DB Press', 'sets': '3×10', 'category': 'Chest'},
        {'id': 3, 'name': 'Romanian Deadlift', 'sets': '3×8', 'category': 'Back'},
        {'id': 4, 'name': 'Face Pull', 'sets': '3×15', 'category': 'Shoulders'},
      ];
    }
    return _exercises.take(4).map((e) {
      return {
        'id': e.id,
        'name': e.name,
        'sets': '4×8',
        'category': e.category,
      };
    }).toList();
  }

  void _startWorkout() {
    context.push('/live-session/strength');
  }

  void _skipWorkout() {
    final store = KineticStore.instance;
    final now = DateTime.now();
    store.recordEvent(kinetic.KineticEvent(
      id: 'event_${now.millisecondsSinceEpoch}',
      userId: 'default_user',
      eventType: 'workout_skipped',
      timestamp: now,
      payload: {'reason': 'user_deload_request'},
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deload / Active Recovery day logged into Kinetic Engine.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _displayExercises;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle tag with entrance animation
              FadeSlideTransition(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRAIN',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upper-body\nstrength',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${list.length} exercises • 42 min',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Exercises List Card
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222836)),
                  ),
                  child: Column(
                    children: List.generate(list.length, (index) {
                      final ex = list[index];
                      final isLast = index == list.length - 1;
                      return InkWell(
                        onTap: () => context.push('/workouts/log/${ex['id']}'),
                        borderRadius: BorderRadius.vertical(
                          top: index == 0 ? const Radius.circular(16) : Radius.zero,
                          bottom: isLast ? const Radius.circular(16) : Radius.zero,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ex['name'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ex['sets'] as String,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              const Divider(color: Color(0xFF222836), height: 1),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Training history link
              FadeSlideTransition(
                delay: const Duration(milliseconds: 150),
                child: InkWell(
                  onTap: () => context.push('/workouts/history'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Training history ',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Start Workout Button -> Launches full live session with timer & music
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: BouncingTap(
                  onTap: _startWorkout,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Start workout ',
                          style: TextStyle(
                            color: Color(0xFF121810),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded, color: Color(0xFF121810), size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Skip today's workout link
              FadeSlideTransition(
                delay: const Duration(milliseconds: 250),
                child: Center(
                  child: GestureDetector(
                    onTap: _skipWorkout,
                    child: const Text(
                      "Skip today's workout",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(color: Color(0xFF1E2634), height: 1),
              const SizedBox(height: 24),

              // Training Utilities Hub
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRAINING TOOLS & DATABASE',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTrainToolCard(
                            context,
                            icon: Icons.menu_book_rounded,
                            title: 'Exercise Library',
                            subtitle: 'Browse 300+ exercises',
                            color: AppColors.primary,
                            onTap: () => context.push('/exercises'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTrainToolCard(
                            context,
                            icon: Icons.timer_outlined,
                            title: 'Live Session',
                            subtitle: 'Timer & Rest Tracker',
                            color: const Color(0xFF38BDF8),
                            onTap: () => context.push('/live-session/strength'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTrainToolCard(
                            context,
                            icon: Icons.history_rounded,
                            title: 'Past Logs',
                            subtitle: 'Session records',
                            color: const Color(0xFFFB923C),
                            onTap: () => context.push('/workouts/history'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTrainToolCard(
                            context,
                            icon: Icons.add_circle_outline_rounded,
                            title: 'Custom Exercise',
                            subtitle: 'Create movement',
                            color: const Color(0xFFA855F7),
                            onTap: () => context.push('/exercises'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncingTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF222836)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
