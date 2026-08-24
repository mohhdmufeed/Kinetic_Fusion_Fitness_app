import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class ScheduleSheet extends StatelessWidget {
  const ScheduleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ScheduleSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => now.add(Duration(days: i - 2)));

    final scheduleItems = [
      {
        'title': 'Upper Hypertrophy Overload',
        'time': '07:30 AM - 08:45 AM',
        'type': 'Workout Program',
        'trainer': 'Coach Marcus Vance',
        'status': 'Today - Up Next',
        'color': AppColors.primary,
        'icon': Icons.fitness_center_rounded,
      },
      {
        'title': 'High-Intensity Tactical Conditioning',
        'time': '05:00 PM - 05:45 PM',
        'type': 'Group Class',
        'trainer': 'Elena Rostova',
        'status': 'Seat Reserved #14',
        'color': Colors.orangeAccent,
        'icon': Icons.flash_on_rounded,
      },
      {
        'title': 'Mobility & Autonomic Recovery',
        'time': 'Tomorrow 08:00 AM',
        'type': 'Recovery Session',
        'trainer': 'Self-Guided Protocol',
        'status': 'Scheduled',
        'color': Colors.cyanAccent,
        'icon': Icons.self_improvement_rounded,
      },
      {
        'title': 'Nutrition Strategy Consultation',
        'time': 'Friday 02:00 PM',
        'type': 'Private Consultation',
        'trainer': 'Dr. Aris Thorne (RD)',
        'status': 'Confirmed Online Call',
        'color': Colors.purpleAccent,
        'icon': Icons.restaurant_rounded,
      },
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.80,
      decoration: const BoxDecoration(
        color: Color(0xFF0F141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF263345), width: 1.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Training Schedule', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    Text('Upcoming sessions, classes & appointments', style: TextStyle(color: Colors.white54, fontSize: 11)),
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
          // Day selector ribbon
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final d = days[idx];
                  final isToday = d.day == now.day && d.month == now.month;
                  return Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : const Color(0xFF161E2B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isToday ? AppColors.primary : const Color(0xFF243247)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d.weekday - 1],
                          style: TextStyle(
                            color: isToday ? Colors.black : Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            color: isToday ? Colors.black : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'PLANNED SESSIONS (${scheduleItems.length})',
              style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: scheduleItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final item = scheduleItems[idx];
                final color = item['color'] as Color;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141B26),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF222F42)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item['icon'] as IconData, color: color, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(item['type'] as String, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(item['status'] as String, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, color: Colors.white38, size: 13),
                                const SizedBox(width: 4),
                                Text(item['time'] as String, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                                const SizedBox(width: 10),
                                const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 13),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item['trainer'] as String,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ),
                              ],
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
