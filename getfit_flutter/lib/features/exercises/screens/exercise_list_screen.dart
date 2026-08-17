import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/main_shell.dart';

import '../widgets/custom_exercise_form_dialog.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});
  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  List<Exercise> _exercises = [];
  List<Exercise> _filtered = [];
  bool _loading = true;
  String _query = '';
  String? _selectedCategory;
  final _searchCtrl = TextEditingController();

  static const _categoryColors = {
    'Chest': AppColors.chest,
    'Back': AppColors.back,
    'Legs': AppColors.legs,
    'Shoulders': AppColors.shoulders,
    'Arms': AppColors.arms,
    'Core': AppColors.core,
    'Cardio': AppColors.cardio,
  };

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    final db = ref.read(databaseProvider);
    final all = await db.getAllExercises();
    if (mounted) {
      setState(() {
        _exercises = all;
        _filtered = all;
        _loading = false;
      });
    }
  }

  void _openCustomExerciseDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomExerciseFormDialog(
        onSaved: () {
          _loadExercises();
        },
      ),
    );
  }

  void _filter() {
    setState(() {
      _filtered = _exercises.where((e) {
        final matchQ =
            _query.isEmpty || e.name.toLowerCase().contains(_query.toLowerCase());
        final matchCat = _selectedCategory == null ||
            e.category.toLowerCase() ==
                _selectedCategory!.toLowerCase();
        return matchQ && matchCat;
      }).toList();
    });
  }

  List<String> get _categories {
    final cats = _exercises.map((e) => e.category).where((c) => c.isNotEmpty).toSet().toList();
    cats.sort();
    return cats;
  }

  Color _categoryColor(String cat) =>
      _categoryColors.entries
          .firstWhere(
            (e) => cat.toLowerCase().contains(e.key.toLowerCase()),
            orElse: () => MapEntry('', AppColors.primary),
          )
          .value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Custom Exercise',
            onPressed: _openCustomExerciseDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                hintText: 'Search exercises...',
              ),
              onChanged: (v) {
                _query = v;
                _filter();
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? EmptyState(
                  icon: Icons.sports_gymnastics_rounded,
                  title: 'No exercises yet',
                  subtitle: 'Connect to internet to sync the exercise database',
                  action: null,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final ex = _filtered[i];
                    final catColor = _categoryColor(ex.category);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: catColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.fitness_center_rounded,
                              color: catColor, size: 20),
                        ),
                        title: Text(ex.name,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: ex.category.isNotEmpty
                            ? Text(ex.category,
                                style: TextStyle(
                                    color: catColor, fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/exercises/${ex.id}'),
                      ),
                    );
                  },
                ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter by Category',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                      _filter();
                      Navigator.pop(context);
                    },
                  ),
                  ..._categories.map((cat) => FilterChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        selectedColor:
                            _categoryColor(cat).withOpacity(0.2),
                        onSelected: (_) {
                          setState(() => _selectedCategory = cat);
                          _filter();
                          Navigator.pop(context);
                        },
                      )),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
