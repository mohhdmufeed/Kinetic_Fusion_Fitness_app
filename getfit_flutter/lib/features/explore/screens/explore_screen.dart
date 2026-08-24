import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/motion_widgets.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showBookingSheet(BuildContext context, {required String type}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PrivateSessionBookingSheet(sessionType: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Profile icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.go('/profile'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary, width: 1.5),
                            ),
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFF1E293B),
                              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── BOOK A PRIVATE SESSION (Online Workout / Nutrition) ────────
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A2636), Color(0xFF101722)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF283A52)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Book a private session',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '1-on-1 virtual training and expert clinical nutrition consultation with elite coaches.',
                            style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showBookingSheet(context, type: 'Online Workout'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.primary),
                                    foregroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.videocam_rounded, size: 16),
                                  label: const Text('Online workout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showBookingSheet(context, type: 'Nutrition consultation'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.restaurant_rounded, size: 16),
                                  label: const Text('Nutrition consult', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Navigation Tabs
                    TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Workouts'),
                        Tab(text: 'Group classes'),
                        Tab(text: 'Meet our trainers'),
                        Tab(text: 'Saved & Achievements'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              // ─── 1. WORKOUTS SUB-VIEW ──────────────────────────────────────────
              _buildWorkoutsTab(context),

              // ─── 2. GROUP CLASSES SUB-VIEW ─────────────────────────────────────
              _buildGroupClassesTab(context),

              // ─── 3. MEET OUR TRAINERS SUB-VIEW ─────────────────────────────────
              _buildTrainersTab(context),

              // ─── 4. SAVED WORKOUTS & ACHIEVEMENTS SUB-VIEW ─────────────────────
              _buildSavedAndAchievementsTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutsTab(BuildContext context) {
    final workoutCategories = [
      {'title': 'Strength & Hypertrophy', 'count': '24 routines', 'icon': Icons.fitness_center_rounded, 'color': AppColors.primary},
      {'title': 'HIIT & Conditioning', 'count': '18 workouts', 'icon': Icons.flash_on_rounded, 'color': Colors.deepOrangeAccent},
      {'title': 'Mobility & Recovery', 'count': '12 protocols', 'icon': Icons.self_improvement_rounded, 'color': Colors.cyanAccent},
      {'title': 'Athletic Speed & Power', 'count': '15 routines', 'icon': Icons.speed_rounded, 'color': Colors.amberAccent},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Workout Library', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: () => context.push('/workouts'),
              child: const Text('All Routines', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...workoutCategories.map((cat) {
          final color = cat['color'] as Color;
          return SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () => context.push('/workouts'),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141517),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF222326)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Icon(cat['icon'] as IconData, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat['title'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            cat['count'] as String,
                            style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222326),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Browse', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGroupClassesTab(BuildContext context) {
    final classes = [
      {'name': 'HIIT Sprint & Core Fusion', 'instructor': 'Coach Elena', 'time': 'Today 05:30 PM', 'seats': '18 / 20 Reserved', 'color': Colors.deepOrangeAccent},
      {'name': 'Olympic Lifting Masterclass', 'instructor': 'Marcus Vance', 'time': 'Tomorrow 07:00 AM', 'seats': '8 / 10 Reserved', 'color': AppColors.primary},
      {'name': 'Mobility Flow & Breathwork', 'instructor': 'Sarah Jenkins', 'time': 'Tomorrow 06:00 PM', 'seats': '12 / 25 Reserved', 'color': Colors.cyanAccent},
      {'name': 'High-Volume Hypertrophy Camp', 'instructor': 'Darius Kane', 'time': 'Friday 08:00 AM', 'seats': '14 / 15 Reserved', 'color': Colors.purpleAccent},
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: classes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final c = classes[idx];
        final color = c['color'] as Color;
        return SizedBox(
          width: double.infinity,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141517),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF222326)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: color.withOpacity(0.18), borderRadius: BorderRadius.circular(8)),
                      child: Text(c['time'] as String, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Text(c['seats'] as String, style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  c['name'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Instructor: ${c['instructor']}',
                  style: const TextStyle(color: Color(0xFF8E9094), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Seat reserved for ${c['name']}!'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: const Color(0xFF0D0E0F),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reserve Seat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrainersTab(BuildContext context) {
    final trainers = [
      {'name': 'Marcus Vance', 'role': 'Head Strength & Conditioning', 'experience': '12 yrs exp • CSCS', 'rating': '4.9 ★ (340 sessions)', 'color': AppColors.primary},
      {'name': 'Dr. Aris Thorne', 'role': 'Performance Clinical Nutritionist', 'experience': 'PhD, Registered Dietitian', 'rating': '5.0 ★ (210 consults)', 'color': Colors.cyanAccent},
      {'name': 'Elena Rostova', 'role': 'HIIT & Mobility Specialist', 'experience': 'Former Track Athlete • CPT', 'rating': '4.9 ★ (490 sessions)', 'color': Colors.deepOrangeAccent},
    ];

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: trainers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final t = trainers[idx];
        final color = t['color'] as Color;
        return SizedBox(
          width: double.infinity,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141517),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF222326)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: color.withOpacity(0.18),
                  child: Text(
                    (t['name'] as String).substring(0, 1),
                    style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t['name'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t['role'] as String,
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t['experience'] as String,
                        style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t['rating'] as String,
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showBookingSheet(context, type: 'Private Session with ${t['name']}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF222326),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedAndAchievementsTab(BuildContext context) {
    final savedWorkouts = [
      'Heavy 5x5 Barbell Protocol',
      'Incline Dumbbell & Triceps Blast',
      'HIIT 20-Min Tabata Burner',
    ];

    final achievements = [
      {'title': 'Century Club', 'desc': 'Logged 100 workouts', 'icon': Icons.military_tech_rounded, 'color': Colors.amberAccent},
      {'title': 'Iron Consistency', 'desc': '30-day streak achieved', 'icon': Icons.whatshot_rounded, 'color': Colors.deepOrangeAccent},
      {'title': 'Macro Precision', 'desc': 'Hit exact protein target 7 days in a row', 'icon': Icons.check_circle_rounded, 'color': AppColors.primary},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        const Text('Saved workouts', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...savedWorkouts.map((w) => SizedBox(
              width: double.infinity,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141517),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF222326)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Icon(Icons.bookmark_added_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 20),
        const Text('Achievements', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...achievements.map((a) {
          final color = a['color'] as Color;
          return SizedBox(
            width: double.infinity,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF141517),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF222326)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
                    child: Icon(a['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          a['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a['desc'] as String,
                          style: const TextStyle(color: Color(0xFF8E9094), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PrivateSessionBookingSheet extends StatefulWidget {
  final String sessionType;
  const _PrivateSessionBookingSheet({required this.sessionType});

  @override
  State<_PrivateSessionBookingSheet> createState() => _PrivateSessionBookingSheetState();
}

class _PrivateSessionBookingSheetState extends State<_PrivateSessionBookingSheet> {
  int _selectedDay = 0;
  int _selectedSlot = 1;

  final days = ['Today', 'Tomorrow', 'Friday', 'Saturday'];
  final slots = ['08:00 AM', '10:30 AM', '02:00 PM', '04:30 PM', '06:00 PM'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F141C),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF263345), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Book ${widget.sessionType}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white60)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Select Date', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(days.length, (i) {
              final isSel = i == _selectedDay;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedDay = i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : const Color(0xFF161E2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSel ? AppColors.primary : const Color(0xFF243346)),
                    ),
                    child: Center(
                      child: Text(
                        days[i],
                        style: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          const Text('Select Time Slot', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(slots.length, (i) {
              final isSel = i == _selectedSlot;
              return ChoiceChip(
                label: Text(slots[i]),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFF161E2A),
                labelStyle: TextStyle(color: isSel ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                onSelected: (val) => setState(() => _selectedSlot = i),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Confirmed: ${widget.sessionType} on ${days[_selectedDay]} at ${slots[_selectedSlot]}'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Confirm & Add to Schedule', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
