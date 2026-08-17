import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _navCard(
              context,
              icon: Icons.book_outlined,
              title: 'Food Diary',
              subtitle: 'Log what you eat today',
              color: AppColors.accent,
              onTap: () => context.go('/nutrition/diary'),
            ),
            const SizedBox(height: 16),
            _navCard(
              context,
              icon: Icons.search_rounded,
              title: 'Search Ingredients',
              subtitle: 'Browse the offline food database',
              color: AppColors.primary,
              onTap: () => context.go('/nutrition/search'),
            ),
            const SizedBox(height: 16),
            _navCard(
              context,
              icon: Icons.bar_chart_rounded,
              title: 'Calorie Charts',
              subtitle: 'View your intake over time',
              color: AppColors.warning,
              onTap: () => context.go('/charts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.55))),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
