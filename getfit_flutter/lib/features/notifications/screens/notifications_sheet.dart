import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'New PR Recorded! 🏆',
        'desc': 'You achieved a new estimated 1RM of 132.5kg on Barbell Bench Press.',
        'time': '20m ago',
        'type': 'achievement',
        'icon': Icons.emoji_events_rounded,
        'color': Colors.amberAccent,
        'isNew': true,
      },
      {
        'title': 'Class Reminder: HIIT Sprint',
        'desc': 'Your reserved class starts in 45 minutes at Studio A. Don\'t forget your water bottle!',
        'time': '45m ago',
        'type': 'class',
        'icon': Icons.schedule_rounded,
        'color': AppColors.primary,
        'isNew': true,
      },
      {
        'title': 'Coach Marcus Vance commented',
        'desc': '"Great bar path on your last set of Romanian deadlifts. Keep the hips hinged."',
        'time': '2h ago',
        'type': 'social',
        'icon': Icons.chat_bubble_rounded,
        'color': Colors.lightBlueAccent,
        'isNew': false,
      },
      {
        'title': 'Weekly Recovery Report Ready',
        'desc': 'Average HRV is up 12% with optimal ACWR (1.08). View your full biometric digest.',
        'time': '1d ago',
        'type': 'biometrics',
        'icon': Icons.insights_rounded,
        'color': Colors.purpleAccent,
        'isNew': false,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF263345), width: 1.5)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Updates, social interactions & reminders', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E2838), height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = notifications[idx];
                final isNew = item['isNew'] as bool;
                final color = item['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isNew ? const Color(0xFF182230) : const Color(0xFF131922),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isNew ? color.withOpacity(0.3) : const Color(0xFF202A38)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title'] as String,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                if (isNew)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['time'] as String,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
