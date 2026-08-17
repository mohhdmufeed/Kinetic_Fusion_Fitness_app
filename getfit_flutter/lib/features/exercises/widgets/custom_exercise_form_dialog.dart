import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class CustomExerciseFormDialog extends ConsumerStatefulWidget {
  final VoidCallback onSaved;

  const CustomExerciseFormDialog({super.key, required this.onSaved});

  @override
  ConsumerState<CustomExerciseFormDialog> createState() =>
      _CustomExerciseFormDialogState();
}

class _CustomExerciseFormDialogState
    extends ConsumerState<CustomExerciseFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'Chest';
  final List<String> _selectedMuscles = [];
  final List<String> _selectedEquipment = [];

  final List<String> _categories = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Abs / Core',
    'Cardio & Mobility',
  ];

  final List<String> _muscles = [
    'Pectorals',
    'Lats',
    'Rhomboids',
    'Trapezius',
    'Biceps',
    'Triceps',
    'Forearms',
    'Quads',
    'Hamstrings',
    'Glutes',
    'Calves',
    'Abdominals',
    'Obliques',
  ];

  final List<String> _equipment = [
    'Barbell',
    'Dumbbell',
    'Kettlebell',
    'Cable',
    'Machine',
    'Bodyweight',
    'Resistance Band',
    'Pull-up Bar',
  ];

  Future<void> _saveCustomExercise() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final customId = 900000 + Random().nextInt(99999);

    await db.insertCustomExercise(
      ExercisesCompanion(
        id: drift.Value(customId),
        uuid: drift.Value('custom_$customId'),
        name: drift.Value(name),
        description: drift.Value(_descCtrl.text.trim()),
        category: drift.Value(_selectedCategory),
        muscles: drift.Value(jsonEncode(_selectedMuscles)),
        equipment: drift.Value(jsonEncode(_selectedEquipment)),
        imageUrl: const drift.Value(''),
        isCustom: const drift.Value(true),
      ),
    );

    widget.onSaved();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Added custom exercise "$name" to your library!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
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
                'Create Custom Exercise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name *',
                    hintText: 'e.g. Incline Cable Flyes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Primary Muscle Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text('Target Muscles (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _muscles.map((m) {
                    final isSel = _selectedMuscles.contains(m);
                    return FilterChip(
                      label: Text(m, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: navyColor,
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _selectedMuscles.add(m);
                          } else {
                            _selectedMuscles.remove(m);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Required Equipment (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _equipment.map((e) {
                    final isSel = _selectedEquipment.contains(e);
                    return FilterChip(
                      label: Text(e, style: TextStyle(fontSize: 11, color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: const Color(0xFF0284C7),
                      onSelected: (sel) {
                        setState(() {
                          if (sel) {
                            _selectedEquipment.add(e);
                          } else {
                            _selectedEquipment.remove(e);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Execution Instructions / Notes',
                    hintText: 'e.g. Set bench to 30 degrees, squeeze at peak contraction.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveCustomExercise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Save to Exercise Library',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
