import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/main_shell.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});
  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  List<Routine> _routines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ref.read(databaseProvider).getActiveRoutines();
    if (mounted) setState(() => _routines = r);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => context.go('/workouts/history'),
            tooltip: 'History',
          ),
        ],
      ),
      body: _routines.isEmpty
          ? EmptyState(
              icon: Icons.fitness_center_rounded,
              title: 'No routines yet',
              subtitle: 'Create a routine or log a quick exercise',
              action: ElevatedButton.icon(
                onPressed: () => context.go('/exercises'),
                icon: const Icon(Icons.search_rounded),
                label: const Text('Browse Exercises'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _routines.length,
              itemBuilder: (_, i) {
                final r = _routines[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accent]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center_rounded,
                          color: Colors.white),
                    ),
                    title: Text(r.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: r.description.isNotEmpty
                        ? Text(r.description)
                        : null,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.go('/exercises'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/exercises'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Exercise'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
