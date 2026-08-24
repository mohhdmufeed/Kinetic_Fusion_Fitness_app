import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/models.dart';

class ExerciseRepository {
  final QueryExecutor executor;

  ExerciseRepository(this.executor);

  /// Inserts a new exercise into the database
  Future<void> createExercise(Exercise exercise) async {
    await executor.runCustom('''
      INSERT INTO kinetic_exercises (
        id, name, movement_pattern, primary_muscles_json, secondary_muscles_json, equipment_json, default_rest_seconds, is_compound, difficulty
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      exercise.id,
      exercise.name,
      exercise.movementPattern.name,
      jsonEncode(exercise.primaryMuscles.map((m) => m.name).toList()),
      jsonEncode(exercise.secondaryMuscles.map((m) => m.name).toList()),
      jsonEncode(exercise.equipment),
      exercise.defaultRestSeconds,
      exercise.isCompound ? 1 : 0,
      'medium', // Default difficulty
    ]);
  }

  /// Retrieves an exercise by ID
  Future<Exercise?> getExercise(String id) async {
    final rows = await executor.runSelect(
      'SELECT * FROM kinetic_exercises WHERE id = ?;',
      [id],
    );
    if (rows.isEmpty) return null;
    return _mapRow(rows.first);
  }

  /// Queries all exercises, optionally filtered by movement pattern
  Future<List<Exercise>> queryExercises({MovementPattern? movementPattern}) async {
    final List<String> whereClauses = [];
    final List<dynamic> args = [];

    if (movementPattern != null) {
      whereClauses.add('movement_pattern = ?');
      args.add(movementPattern.name);
    }

    final sql = 'SELECT * FROM kinetic_exercises' +
        (whereClauses.isNotEmpty ? ' WHERE ${whereClauses.join(" AND ")}' : '') +
        ' ORDER BY name ASC;';

    final rows = await executor.runSelect(sql, args);
    return rows.map((r) => _mapRow(r)).toList();
  }

  Exercise _mapRow(Map<String, dynamic> row) {
    MovementPattern pattern = MovementPattern.isolation;
    try {
      pattern = MovementPattern.values.byName(row['movement_pattern'] as String);
    } catch (_) {}

    List<MuscleGroup> primaryMuscles = [];
    try {
      final list = jsonDecode(row['primary_muscles_json'] as String? ?? '[]') as List;
      primaryMuscles = list.map((m) => MuscleGroup.values.byName(m as String)).toList();
    } catch (_) {}

    List<MuscleGroup> secondaryMuscles = [];
    try {
      final list = jsonDecode(row['secondary_muscles_json'] as String? ?? '[]') as List;
      secondaryMuscles = list.map((m) => MuscleGroup.values.byName(m as String)).toList();
    } catch (_) {}

    List<String> equipment = [];
    try {
      equipment = List<String>.from(jsonDecode(row['equipment_json'] as String? ?? '[]'));
    } catch (_) {}

    return Exercise(
      id: row['id'] as String,
      name: row['name'] as String,
      movementPattern: pattern,
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      equipment: equipment,
      defaultRestSeconds: (row['default_rest_seconds'] as num? ?? 90.0).toDouble(),
      isCompound: (row['is_compound'] as int? ?? 1) == 1,
    );
  }
}
