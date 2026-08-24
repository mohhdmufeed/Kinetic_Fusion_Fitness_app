import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/auth/auth_service.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class AchievementModel {
  final String code;
  final String title;
  final String description;
  final String ruleType;
  final int threshold;
  final String iconUrl;
  final DateTime? unlockedAt;

  AchievementModel({
    required this.code,
    required this.title,
    required this.description,
    required this.ruleType,
    required this.threshold,
    required this.iconUrl,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory AchievementModel.fromUnlocked(Map<String, dynamic> j) {
    final ach = j['achievement'] as Map<String, dynamic>? ?? {};
    return AchievementModel(
      code: ach['code'] as String? ?? '',
      title: ach['title'] as String? ?? '',
      description: ach['description'] as String? ?? '',
      ruleType: ach['rule_type'] as String? ?? '',
      threshold: ach['threshold'] as int? ?? 1,
      iconUrl: ach['icon_url'] as String? ?? '',
      unlockedAt: DateTime.tryParse(j['unlocked_at'] as String? ?? ''),
    );
  }

  factory AchievementModel.fromCatalogue(Map<String, dynamic> j) =>
      AchievementModel(
        code: j['code'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        ruleType: j['rule_type'] as String? ?? '',
        threshold: j['threshold'] as int? ?? 1,
        iconUrl: j['icon_url'] as String? ?? '',
      );
}

// ─── Providers ──────────────────────────────────────────────────────────────

final achievementsProvider =
    FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final auth = ref.watch(authServiceProvider);
  try {
    final resp = await auth.dioClient.get('/achievements/');
    return (resp.data as List? ?? [])
        .map((j) => AchievementModel.fromUnlocked(j as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

final catalogueProvider =
    FutureProvider.autoDispose<List<AchievementModel>>((ref) async {
  final auth = ref.watch(authServiceProvider);
  try {
    final resp = await auth.dioClient.get('/achievements/catalogue/');
    return (resp.data as List? ?? [])
        .map((j) => AchievementModel.fromCatalogue(j as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Screen ─────────────────────────────────────────────────────────────────

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(achievementsProvider);
    final catalogue = ref.watch(catalogueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      unlocked.maybeWhen(
                        data: (list) => Text(
                          '${list.length} unlocked',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.emoji_events_rounded,
                      color: Color(0xFFFFD700), size: 32),
                ],
              ),
            ),
            Expanded(
              child: catalogue.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (e, _) => const Center(
                    child: Text('Could not load achievements',
                        style: TextStyle(color: Colors.white54))),
                data: (all) {
                  final unlockedCodes = unlocked.valueOrNull
                          ?.map((a) => a.code)
                          .toSet() ??
                      {};
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: all.length,
                    itemBuilder: (context, idx) {
                      final ach = all[idx];
                      final isUnlocked = unlockedCodes.contains(ach.code);
                      return _AchievementCard(
                          achievement: ach, isUnlocked: isUnlocked);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementModel achievement;
  final bool isUnlocked;

  const _AchievementCard(
      {required this.achievement, required this.isUnlocked});

  static const Map<String, IconData> _ruleIcons = {
    'workout_count': Icons.fitness_center_rounded,
    'streak_days': Icons.local_fire_department_rounded,
    'benchmark_hit': Icons.trending_up_rounded,
    'class_attended': Icons.groups_rounded,
    'nutrition_streak': Icons.restaurant_rounded,
    'body_goal': Icons.monitor_weight_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final icon =
        _ruleIcons[achievement.ruleType] ?? Icons.emoji_events_rounded;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isUnlocked
            ? const Color(0xFF131A26)
            : const Color(0xFF0D1118),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primary.withValues(alpha: 0.5)
              : const Color(0xFF1C2535),
          width: isUnlocked ? 1.5 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isUnlocked ? AppColors.primary : Colors.white12,
                  width: 2,
                ),
              ),
              child: Icon(
                isUnlocked ? icon : Icons.lock_outline_rounded,
                color: isUnlocked ? AppColors.primary : Colors.white24,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isUnlocked ? Colors.white54 : Colors.white24,
                fontSize: 10,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isUnlocked) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'UNLOCKED',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
