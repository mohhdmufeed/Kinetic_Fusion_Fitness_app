import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});
  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  Exercise? _exercise;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    final ex = await (db.select(db.exercises)
          ..where((t) => t.id.equals(widget.exerciseId)))
        .getSingleOrNull();
    if (mounted) setState(() => _exercise = ex);
  }

  @override
  Widget build(BuildContext context) {
    if (_exercise == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ex = _exercise!;
    final muscles = ex.muscles
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final equipment = ex.equipment
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.fitness_center_rounded,
                      size: 80, color: Colors.white30),
                ),
              ),
              title: Text(ex.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ex.category.isNotEmpty)
                    Chip(
                      label: Text(ex.category),
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      labelStyle: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 20),
                  if (muscles.isNotEmpty) ...[
                    _sectionTitle('Primary Muscles'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: muscles
                          .map((m) => _muscleChip(m))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (equipment.isNotEmpty) ...[
                    _sectionTitle('Equipment'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: equipment
                          .map((e) => Chip(
                                label: Text(e),
                                avatar: const Icon(Icons.build_outlined,
                                    size: 14),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (ex.description.isNotEmpty) ...[
                    _sectionTitle('Description'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ex.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.go('/workouts/log/${ex.id}'),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log This Exercise'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));

  Widget _muscleChip(String muscle) {
    const colors = {
      'chest': AppColors.chest,
      'back': AppColors.back,
      'leg': AppColors.legs,
      'shoulder': AppColors.shoulders,
      'arm': AppColors.arms,
      'bicep': AppColors.arms,
      'tricep': AppColors.arms,
      'core': AppColors.core,
      'abs': AppColors.core,
    };
    Color color = AppColors.primary;
    for (final entry in colors.entries) {
      if (muscle.toLowerCase().contains(entry.key)) {
        color = entry.value;
        break;
      }
    }
    return Chip(
      label: Text(muscle),
      backgroundColor: color.withOpacity(0.15),
      labelStyle:
          TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    );
  }
}
