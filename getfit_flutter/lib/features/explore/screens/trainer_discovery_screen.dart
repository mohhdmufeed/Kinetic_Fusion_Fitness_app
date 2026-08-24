import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/auth/auth_service.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class TrainerModel {
  final int id;
  final String username;
  final String displayName;
  final String bio;
  final List<String> specialties;
  final List<String> certifications;
  final bool isAcceptingBookings;

  TrainerModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.specialties,
    required this.certifications,
    required this.isAcceptingBookings,
  });

  factory TrainerModel.fromJson(Map<String, dynamic> j) => TrainerModel(
        id: j['id'] as int? ?? 0,
        username: j['username'] as String? ?? '',
        displayName: j['display_name'] as String? ?? j['username'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        specialties: List<String>.from(j['specialties'] as List? ?? []),
        certifications: List<String>.from(j['certifications'] as List? ?? []),
        isAcceptingBookings: j['is_accepting_bookings'] as bool? ?? false,
      );
}

class GroupClassModel {
  final int id;
  final String trainerName;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int capacity;
  final int seatsAvailable;
  final bool isOnline;
  final String venueName;
  final double? distanceKm;

  GroupClassModel({
    required this.id,
    required this.trainerName,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.seatsAvailable,
    required this.isOnline,
    required this.venueName,
    this.distanceKm,
  });

  factory GroupClassModel.fromJson(Map<String, dynamic> j) => GroupClassModel(
        id: j['id'] as int? ?? 0,
        trainerName: j['trainer_name'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        startTime: DateTime.tryParse(j['start_time'] as String? ?? '') ?? DateTime.now(),
        endTime: DateTime.tryParse(j['end_time'] as String? ?? '') ?? DateTime.now(),
        capacity: j['capacity'] as int? ?? 0,
        seatsAvailable: j['seats_available'] as int? ?? 0,
        isOnline: j['is_online'] as bool? ?? false,
        venueName: j['venue_name'] as String? ?? '',
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
      );
}

// ─── Providers ──────────────────────────────────────────────────────────────

final trainersProvider =
    FutureProvider.autoDispose<List<TrainerModel>>((ref) async {
  final auth = ref.watch(authServiceProvider);
  try {
    final resp = await auth.dioClient.get('/trainers/');
    return (resp.data as List? ?? [])
        .map((j) => TrainerModel.fromJson(j as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

final classesProvider =
    FutureProvider.autoDispose<List<GroupClassModel>>((ref) async {
  final auth = ref.watch(authServiceProvider);
  try {
    final resp = await auth.dioClient.get('/classes/');
    return (resp.data as List? ?? [])
        .map((j) => GroupClassModel.fromJson(j as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

// ─── Screen ─────────────────────────────────────────────────────────────────

class TrainerDiscoveryScreen extends ConsumerStatefulWidget {
  const TrainerDiscoveryScreen({super.key});

  @override
  ConsumerState<TrainerDiscoveryScreen> createState() =>
      _TrainerDiscoveryScreenState();
}

class _TrainerDiscoveryScreenState
    extends ConsumerState<TrainerDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explore',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Trainers & Classes',
                        style: TextStyle(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.search_rounded,
                      color: Colors.white60, size: 26),
                ],
              ),
            ),
            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [Tab(text: 'Trainers'), Tab(text: 'Classes')],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TrainersList(),
                  _ClassesList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Trainers List ───────────────────────────────────────────────────────────

class _TrainersList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainers = ref.watch(trainersProvider);
    return trainers.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(
          child: Text('Could not load trainers',
              style: TextStyle(color: Colors.white54))),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
              child: Text('No trainers yet',
                  style: TextStyle(color: Colors.white38)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _TrainerCard(trainer: list[idx]),
        );
      },
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final TrainerModel trainer;
  const _TrainerCard({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF202C3E)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              trainer.displayName.isNotEmpty
                  ? trainer.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trainer.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                if (trainer.specialties.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trainer.specialties.take(3).join(' · '),
                    style: const TextStyle(color: AppColors.primary, fontSize: 11),
                  ),
                ],
                if (trainer.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    trainer.bio,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (trainer.isAcceptingBookings)
            ElevatedButton(
              onPressed: () => _showBookSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(60, 32),
              ),
              child: const Text('Book',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            )
          else
            const Text('Unavailable',
                style: TextStyle(color: Colors.white30, fontSize: 10)),
        ],
      ),
    );
  }

  void _showBookSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F141C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book with ${trainer.displayName}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const _BookOptionTile(
                icon: Icons.videocam_rounded,
                label: 'Online Workout Session',
                value: 'online_workout'),
            const SizedBox(height: 8),
            const _BookOptionTile(
                icon: Icons.restaurant_menu_rounded,
                label: 'Nutrition Consultation',
                value: 'nutrition_consultation'),
          ],
        ),
      ),
    );
  }
}

class _BookOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BookOptionTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Booking requested: $label'),
          backgroundColor: AppColors.primary,
        ));
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF202C3E)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

// ─── Classes List ─────────────────────────────────────────────────────────────

class _ClassesList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classes = ref.watch(classesProvider);
    return classes.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (_, __) => const Center(
          child: Text('Could not load classes',
              style: TextStyle(color: Colors.white54))),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
              child: Text('No upcoming classes',
                  style: TextStyle(color: Colors.white38)));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) => _ClassCard(cls: list[idx]),
        );
      },
    );
  }
}

class _ClassCard extends StatelessWidget {
  final GroupClassModel cls;
  const _ClassCard({required this.cls});

  @override
  Widget build(BuildContext context) {
    final isFull = cls.seatsAvailable == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isFull
                ? Colors.white12
                : AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(cls.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFull
                      ? Colors.white.withValues(alpha: 0.05)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFull ? 'FULL' : '${cls.seatsAvailable} SEATS',
                  style: TextStyle(
                      color: isFull ? Colors.white38 : AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(
                _formatTime(cls.startTime),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (cls.distanceKm != null) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on_outlined,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${cls.distanceKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
              const SizedBox(width: 12),
              const Icon(Icons.person_outline_rounded,
                  color: Colors.white38, size: 14),
              const SizedBox(width: 4),
              Text(cls.trainerName,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
          if (cls.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(cls.description,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isFull
                  ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Added to waitlist'),
                        backgroundColor: Color(0xFF1E293B),
                      ))
                  : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Booking ${cls.title}...'),
                        backgroundColor: AppColors.primary,
                      )),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull
                    ? const Color(0xFF1C2535)
                    : AppColors.primary,
                foregroundColor: isFull ? Colors.white60 : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isFull ? 'Join Waitlist' : 'Book Class',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.inDays == 0) return 'Today ${_hm(dt)}';
    if (diff.inDays == 1) return 'Tomorrow ${_hm(dt)}';
    return '${dt.month}/${dt.day} ${_hm(dt)}';
  }

  String _hm(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
