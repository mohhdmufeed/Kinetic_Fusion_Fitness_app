import 'package:drift/drift.dart';
import '../domain/models.dart';

class SessionRepository {
  final QueryExecutor executor;

  SessionRepository(this.executor);

  /// Inserts a new workout session along with its prescriptions atomically
  Future<void> createSession(WorkoutSession session) async {
    // We use custom transactional inserts or raw statements
    await executor.runCustom('''
      INSERT INTO kinetic_sessions (
        id, user_id, start_time, end_time, goal, focus, average_rpe, training_load, status
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      session.id,
      session.userId,
      session.startTime.toIso8601String(),
      session.endTime?.toIso8601String(),
      session.goal.name,
      session.focus.name,
      session.averageRPE,
      session.trainingLoad,
      session.status,
    ]);

    for (final rx in session.prescriptions) {
      final rxId = '${session.id}_${rx.exerciseId}';
      await executor.runCustom('''
        INSERT INTO kinetic_prescriptions (
          id, session_id, exercise_id, exercise_name, target_sets, target_reps, target_load_kg, target_rpe, rest_seconds, tempo, priority, reason_code
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''', [
        rxId,
        session.id,
        rx.exerciseId,
        rx.exerciseName,
        rx.targetSets,
        rx.targetReps,
        rx.targetLoadKg,
        rx.targetRPE,
        rx.restSeconds,
        rx.tempo,
        rx.priority,
        rx.reasonCode,
      ]);
    }
  }

  /// Inserts/records a completed set under a session
  Future<void> recordSet(String sessionId, ExerciseSet set) async {
    final setId = '${sessionId}_${set.exerciseId}_${set.setNumber}';
    await executor.runCustom('''
      INSERT OR REPLACE INTO kinetic_sets (
        id, session_id, exercise_id, set_number, prescribed_load_kg, actual_load_kg, prescribed_reps, actual_reps, target_rpe, actual_rpe, rest_seconds, timestamp, is_completed
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''', [
      setId,
      sessionId,
      set.exerciseId,
      set.setNumber,
      set.prescribedLoadKg,
      set.actualLoadKg,
      set.prescribedReps,
      set.actualReps,
      set.targetRPE,
      set.actualRPE,
      set.restSeconds,
      set.timestamp.toIso8601String(),
      set.isCompleted ? 1 : 0,
    ]);
  }

  /// Completes a session by updating its status, end time, average RPE, and training load
  Future<void> completeSession({
    required String sessionId,
    required DateTime endTime,
    required double averageRPE,
    required double trainingLoad,
  }) async {
    await executor.runCustom('''
      UPDATE kinetic_sessions SET
        end_time = ?,
        average_rpe = ?,
        training_load = ?,
        status = ?
      WHERE id = ?;
    ''', [
      endTime.toIso8601String(),
      averageRPE,
      trainingLoad,
      'completed',
      sessionId,
    ]);
  }

  /// Retrieves a complete session by its unique ID
  Future<WorkoutSession?> getSession(String id) async {
    final sessionRows = await executor.runSelect(
      'SELECT * FROM kinetic_sessions WHERE id = ?;',
      [id],
    );
    if (sessionRows.isEmpty) return null;

    final sessionRow = sessionRows.first;

    final rxRows = await executor.runSelect(
      'SELECT * FROM kinetic_prescriptions WHERE session_id = ? ORDER BY priority ASC;',
      [id],
    );

    final setRows = await executor.runSelect(
      'SELECT * FROM kinetic_sets WHERE session_id = ? ORDER BY exercise_id, set_number ASC;',
      [id],
    );

    final prescriptions = rxRows.map((rx) {
      return ExercisePrescription(
        exerciseId: rx['exercise_id'] as String,
        exerciseName: rx['exercise_name'] as String,
        targetSets: rx['target_sets'] as int,
        targetReps: rx['target_reps'] as int,
        targetLoadKg: (rx['target_load_kg'] as num).toDouble(),
        targetRPE: (rx['target_rpe'] as num).toDouble(),
        restSeconds: rx['rest_seconds'] as int,
        tempo: rx['tempo'] as String? ?? '2-0-1-0',
        priority: rx['priority'] as int? ?? 1,
        reasonCode: rx['reason_code'] as String,
      );
    }).toList();

    final completedSets = setRows.map((s) {
      return ExerciseSet(
        setNumber: s['set_number'] as int,
        exerciseId: s['exercise_id'] as String,
        prescribedLoadKg: (s['prescribed_load_kg'] as num).toDouble(),
        actualLoadKg: (s['actual_load_kg'] as num).toDouble(),
        prescribedReps: s['prescribed_reps'] as int,
        actualReps: s['actual_reps'] as int,
        targetRPE: (s['target_rpe'] as num).toDouble(),
        actualRPE: (s['actual_rpe'] as num).toDouble(),
        restSeconds: s['rest_seconds'] as int? ?? 90,
        timestamp: DateTime.parse(s['timestamp'] as String),
        isCompleted: (s['is_completed'] as int? ?? 1) == 1,
      );
    }).toList();

    GoalType goal = GoalType.hypertrophy;
    try {
      goal = GoalType.values.byName(sessionRow['goal'] as String);
    } catch (_) {}

    TrainingFocus focus = TrainingFocus.hypertrophy;
    try {
      focus = TrainingFocus.values.byName(sessionRow['focus'] as String);
    } catch (_) {}

    return WorkoutSession(
      id: sessionRow['id'] as String,
      userId: sessionRow['user_id'] as String,
      startTime: DateTime.parse(sessionRow['start_time'] as String),
      endTime: sessionRow['end_time'] != null ? DateTime.parse(sessionRow['end_time'] as String) : null,
      goal: goal,
      focus: focus,
      prescriptions: prescriptions,
      completedSets: completedSets,
      averageRPE: (sessionRow['average_rpe'] as num?)?.toDouble(),
      trainingLoad: (sessionRow['training_load'] as num? ?? 0.0).toDouble(),
      status: sessionRow['status'] as String? ?? 'planned',
    );
  }

  /// Retrieves complete session history for a user
  Future<List<WorkoutSession>> getSessions(String userId) async {
    final sessionRows = await executor.runSelect(
      'SELECT id FROM kinetic_sessions WHERE user_id = ? ORDER BY start_time DESC;',
      [userId],
    );

    final List<WorkoutSession> sessions = [];
    for (final row in sessionRows) {
      final session = await getSession(row['id'] as String);
      if (session != null) {
        sessions.add(session);
      }
    }
    return sessions;
  }
}
