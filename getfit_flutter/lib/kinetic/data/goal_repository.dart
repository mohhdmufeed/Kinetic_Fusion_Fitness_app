import 'dart:convert';
import 'package:drift/drift.dart';
import '../domain/models.dart';

class GoalRepository {
  final QueryExecutor executor;

  GoalRepository(this.executor);

  /// Inserts a new user goal
  Future<void> createGoal(UserGoal goal) async {
    await executor.runCustom('''
      INSERT INTO kinetic_goals (
        id, user_id, type, priority, target_value, target_metric, deadline, constraints_json, is_active
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      goal.id,
      goal.userId,
      goal.type.name,
      goal.priority,
      goal.targetValue,
      goal.targetMetric,
      goal.deadline?.toIso8601String(),
      jsonEncode(goal.constraints),
      goal.isActive ? 1 : 0,
    ]);
  }

  /// Updates an existing goal
  Future<void> updateGoal(UserGoal goal) async {
    await executor.runCustom('''
      UPDATE kinetic_goals SET
        type = ?,
        priority = ?,
        target_value = ?,
        target_metric = ?,
        deadline = ?,
        constraints_json = ?,
        is_active = ?
      WHERE id = ?;
    ''', [
      goal.type.name,
      goal.priority,
      goal.targetValue,
      goal.targetMetric,
      goal.deadline?.toIso8601String(),
      jsonEncode(goal.constraints),
      goal.isActive ? 1 : 0,
      goal.id,
    ]);
  }

  /// Retrieves active goals for a user
  Future<List<UserGoal>> getActiveGoals(String userId) async {
    final rows = await executor.runSelect(
      'SELECT * FROM kinetic_goals WHERE user_id = ? AND is_active = 1 ORDER BY priority ASC;',
      [userId],
    );
    return rows.map((r) => _mapRow(r)).toList();
  }

  /// Retrieves all goals for a user
  Future<List<UserGoal>> getAllGoals(String userId) async {
    final rows = await executor.runSelect(
      'SELECT * FROM kinetic_goals WHERE user_id = ? ORDER BY is_active DESC, priority ASC;',
      [userId],
    );
    return rows.map((r) => _mapRow(r)).toList();
  }

  UserGoal _mapRow(Map<String, dynamic> row) {
    GoalType type = GoalType.custom;
    try {
      type = GoalType.values.byName(row['type'] as String);
    } catch (_) {}

    Map<String, dynamic> constraints = {};
    try {
      constraints = jsonDecode(row['constraints_json'] as String? ?? '{}') as Map<String, dynamic>;
    } catch (_) {}

    return UserGoal(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      type: type,
      priority: row['priority'] as int? ?? 1,
      targetValue: (row['target_value'] as num?)?.toDouble(),
      targetMetric: row['target_metric'] as String?,
      deadline: row['deadline'] != null ? DateTime.parse(row['deadline'] as String) : null,
      constraints: constraints,
      isActive: (row['is_active'] as int? ?? 1) == 1,
    );
  }
}
