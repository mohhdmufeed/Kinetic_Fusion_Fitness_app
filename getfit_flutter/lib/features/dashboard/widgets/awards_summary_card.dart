import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class TrophyItem {
  final String title;
  final String description;
  final String icon;
  final bool isEarned;

  const TrophyItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.isEarned,
  });
}

class AwardsSummaryCard extends StatefulWidget {
  const AwardsSummaryCard({super.key});

  @override
  State<AwardsSummaryCard> createState() => _AwardsSummaryCardState();
}

class _AwardsSummaryCardState extends State<AwardsSummaryCard> {
  final List<TrophyItem> _trophies = const [
    TrophyItem(title: 'First Step', description: 'Log your very first workout in Kinetic Fusion', icon: '🥇', isEarned: true),
    TrophyItem(title: 'Move Master', description: 'Hit your daily active move goal', icon: '🔥', isEarned: true),
    TrophyItem(title: 'Century Runner', description: 'Complete a 5+ km cardio run', icon: '🏃', isEarned: true),
    TrophyItem(title: 'Nutrition Tracker', description: 'Log 3 meals in food diary', icon: '🥗', isEarned: true),
    TrophyItem(title: 'Consistency King', description: 'Work out 4 days in a single week', icon: '👑', isEarned: false),
    TrophyItem(title: 'Iron Lifter', description: 'Log over 1,000 kg total volume in a session', icon: '🏋️', isEarned: false),
  ];

  void _showAwardsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: 480,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Trophies & Achievements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_trophies.where((t) => t.isEarned).length} / ${_trophies.length} Earned',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _trophies.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final t = _trophies[idx];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: t.isEarned ? Colors.amber.shade100 : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          t.isEarned ? t.icon : '🔒',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      t.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: t.isEarned ? Colors.black87 : Colors.grey.shade600,
                      ),
                    ),
                    subtitle: Text(
                      t.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    trailing: t.isEarned
                        ? const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                        : const Text('Locked', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earnedCount = _trophies.where((t) => t.isEarned).length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: _showAwardsModal,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events_rounded, color: AppColors.warning, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Awards & Badges',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$earnedCount trophies unlocked',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF26496C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: _trophies.where((t) => t.isEarned).take(4).map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(t.icon, style: const TextStyle(fontSize: 16)),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
