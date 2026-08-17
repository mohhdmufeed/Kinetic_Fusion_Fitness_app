import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class DailyChallengeCard extends ConsumerStatefulWidget {
  const DailyChallengeCard({super.key});

  @override
  ConsumerState<DailyChallengeCard> createState() => _DailyChallengeCardState();
}

class _DailyChallengeCardState extends ConsumerState<DailyChallengeCard> {
  DailyChallenge? _currentChallenge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenge();
  }

  Future<void> _loadChallenge() async {
    final db = ref.read(databaseProvider);
    await db.initDefaultChallengesIfEmpty();
    final list = await db.getDailyChallenges();
    if (mounted) {
      setState(() {
        if (list.isNotEmpty) {
          // Select today's rotating challenge
          final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
          _currentChallenge = list[dayOfYear % list.length];
        }
        _loading = false;
      });
    }
  }

  Future<void> _toggleComplete() async {
    if (_currentChallenge == null) return;
    final db = ref.read(databaseProvider);
    final newStatus = !_currentChallenge!.isCompleted;
    await db.completeDailyChallenge(_currentChallenge!.id, newStatus);
    await _loadChallenge();

    if (newStatus && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Challenge Completed! Keep up the momentum!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    if (_loading || _currentChallenge == null) {
      return const SizedBox.shrink();
    }

    final isDone = _currentChallenge!.isCompleted;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDone
                ? [
                    AppColors.success.withValues(alpha: 0.12),
                    Colors.white,
                  ]
                : [
                    const Color(0xFFE11D48).withValues(alpha: 0.08),
                    Colors.white,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isDone ? AppColors.success.withValues(alpha: 0.3) : const Color(0xFFE11D48).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success : const Color(0xFFE11D48),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(isDone ? Icons.check_circle_rounded : Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            isDone ? 'COMPLETED' : "TODAY'S CHALLENGE",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _currentChallenge!.activityType.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: _toggleComplete,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.success.withValues(alpha: 0.15) : navyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 16,
                          color: isDone ? AppColors.success : navyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDone ? 'Done' : 'Mark Done',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDone ? AppColors.success : navyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _currentChallenge!.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                decoration: isDone ? TextDecoration.lineThrough : null,
                color: isDone ? Colors.grey.shade700 : navyColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _currentChallenge!.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
