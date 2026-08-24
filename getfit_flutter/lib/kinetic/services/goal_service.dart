import '../domain/models.dart';
import '../persistence/kinetic_store.dart';

/// Application Service for Goals & Progression Targets (SPEC.md Section 3)
class GoalService {
  final KineticStore store;

  GoalService({KineticStore? store}) : store = store ?? KineticStore.instance;

  /// 1. getGoals(): Retrieves all configured goals for the user
  Future<List<UserGoal>> getGoals() async {
    return store.getGoals();
  }

  /// 2. setPrimaryGoal(): Sets or updates the primary active user goal
  Future<void> setPrimaryGoal(UserGoal goal) async {
    store.addGoal(goal);
    store.recordEvent(KineticEvent(
      id: 'evt_goal_${DateTime.now().millisecondsSinceEpoch}',
      userId: goal.userId,
      eventType: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {
        'goalId': goal.id,
        'type': goal.type.name,
        'targetValue': goal.targetValue,
      },
    ));
  }

  /// 3. updateGoalProgress(): Computes progress toward the target metric
  Future<Map<String, dynamic>> updateGoalProgress(String goalId) async {
    final goals = store.getGoals();
    final goal = goals.firstWhere((g) => g.id == goalId);

    double progressPercent = 0.0;
    if (goal.targetMetric == 'weight_kg' && goal.targetValue != null) {
      final weights = store.getMeasurements(metric: 'weight_kg');
      if (weights.isNotEmpty) {
        final current = weights.last.value;
        final start = weights.first.value;
        final totalDelta = (goal.targetValue! - start).abs();
        final currentDelta = (current - start).abs();
        progressPercent = totalDelta > 0 ? (currentDelta / totalDelta).clamp(0.0, 1.0) : 1.0;
      }
    } else {
      progressPercent = 0.5; // Ongoing lifestyle / hypertrophy target
    }

    return {
      'goalId': goalId,
      'type': goal.type.name,
      'progressPercent': progressPercent,
    };
  }
}
