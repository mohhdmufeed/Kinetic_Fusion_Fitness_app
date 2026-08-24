import '../domain/models.dart';

class AutoregulationAdjustment {
  final double adjustedLoadKg;
  final int adjustedReps;
  final double adjustedTargetRPE;
  final String reasonCode;

  const AutoregulationAdjustment({
    required this.adjustedLoadKg,
    required this.adjustedReps,
    required this.adjustedTargetRPE,
    required this.reasonCode,
  });
}

/// Training Engine (training_model_v1)
class KineticTrainingEngine {
  static const String version = 'training_model_v1.0';

  /// Generates a dynamic workout prescription based on goal, focus, equipment, and readiness state.
  /// [sessionId] and [sessionTimestamp] must be supplied by callers that need
  /// reproducible output (e.g. tests, simulations). They default to wall-clock
  /// values only at the outermost service boundary.
  static WorkoutSession generateWorkout({
    required String userId,
    required UserGoal goal,
    required TrainingFocus focus,
    required LatentPhysiologicalState readinessState,
    List<String> availableEquipment = const ['barbell', 'dumbbell', 'cable', 'bodyweight'],
    String? sessionId,
    DateTime? sessionTimestamp,
  }) {
    final effectiveId = sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    final effectiveStart = sessionTimestamp ?? DateTime.now();
    final List<ExercisePrescription> prescriptions = [];

    // Scale intensity and volume by physiological readiness
    final double readinessFactor = (readinessState.readinessScore / 100.0).clamp(0.6, 1.15);
    final isDeloadOrFatigued = readinessState.readinessScore < 50.0;

    int defaultSets = isDeloadOrFatigued ? 2 : (focus == TrainingFocus.hypertrophy ? 4 : 3);
    double targetRPE = isDeloadOrFatigued ? 6.5 : (focus == TrainingFocus.strength ? 8.5 : 8.0);

    // Build targeted prescriptions
    if (focus == TrainingFocus.hypertrophy || goal.type == GoalType.hypertrophy) {
      prescriptions.addAll([
        ExercisePrescription(
          exerciseId: 'ex_barbell_bench_press',
          exerciseName: 'Barbell Bench Press',
          targetSets: defaultSets,
          targetReps: (8 * readinessFactor).round().clamp(6, 12),
          targetLoadKg: 80.0,
          targetRPE: targetRPE,
          restSeconds: 120,
          tempo: '3-1-1-0',
          priority: 1,
          reasonCode: 'primary_horizontal_push_compound',
        ),
        ExercisePrescription(
          exerciseId: 'ex_barbell_row',
          exerciseName: 'Barbell Pendlay Row',
          targetSets: defaultSets,
          targetReps: (10 * readinessFactor).round().clamp(8, 12),
          targetLoadKg: 70.0,
          targetRPE: targetRPE,
          restSeconds: 90,
          tempo: '2-0-1-0',
          priority: 2,
          reasonCode: 'primary_horizontal_pull_antagonist',
        ),
        const ExercisePrescription(
          exerciseId: 'ex_dumbbell_lateral_raise',
          exerciseName: 'DB Lateral Raise',
          targetSets: 3,
          targetReps: 15,
          targetLoadKg: 12.0,
          targetRPE: 8.5,
          restSeconds: 60,
          tempo: '2-0-1-1',
          priority: 3,
          reasonCode: 'shoulder_hypertrophy_isolation',
        ),
      ]);
    } else if (focus == TrainingFocus.strength || goal.type == GoalType.strength) {
      prescriptions.addAll([
        ExercisePrescription(
          exerciseId: 'ex_barbell_back_squat',
          exerciseName: 'Barbell Back Squat',
          targetSets: isDeloadOrFatigued ? 3 : 5,
          targetReps: (5 * readinessFactor).round().clamp(3, 5),
          targetLoadKg: 120.0,
          targetRPE: targetRPE,
          restSeconds: 180,
          tempo: '3-1-1-0',
          priority: 1,
          reasonCode: 'neural_strength_squat_pattern',
        ),
        ExercisePrescription(
          exerciseId: 'ex_overhead_press',
          exerciseName: 'Standing Overhead Press',
          targetSets: isDeloadOrFatigued ? 2 : 4,
          targetReps: 5,
          targetLoadKg: 55.0,
          targetRPE: targetRPE,
          restSeconds: 150,
          tempo: '2-1-1-0',
          priority: 2,
          reasonCode: 'vertical_push_strength',
        ),
      ]);
    } else {
      // Active recovery / General Fitness
      prescriptions.add(
        const ExercisePrescription(
          exerciseId: 'ex_goblet_squat_mobility',
          exerciseName: 'Goblet Squat & Mobility Flow',
          targetSets: 3,
          targetReps: 12,
          targetLoadKg: 16.0,
          targetRPE: 6.0,
          restSeconds: 60,
          tempo: '3-2-2-0',
          priority: 1,
          reasonCode: 'active_recovery_tissue_perfusion',
        ),
      );
    }

    return WorkoutSession(
      id: effectiveId,
      userId: userId,
      startTime: effectiveStart,
      goal: goal.type,
      focus: focus,
      prescriptions: prescriptions,
      completedSets: const [],
      status: 'planned',
    );
  }

  /// Autoregulation: Computes dynamic set-by-set load/rep adjustments based on real-time feedback
  /// Example: If prescribed 80kg x 8 @ RPE 8, but user logs 80kg x 6 @ RPE 9.5 (overshoot),
  /// the engine calculates appropriate load reduction for subsequent sets.
  static AutoregulationAdjustment autoregulateNextSet({
    required ExercisePrescription prescription,
    required ExerciseSet previousSet,
    required int nextSetNumber,
  }) {
    final rpeDelta = previousSet.actualRPE - prescription.targetRPE;
    final repsDelta = previousSet.actualReps - prescription.targetReps;

    double newLoad = previousSet.actualLoadKg;
    int newReps = prescription.targetReps;
    double newRPE = prescription.targetRPE;
    String reason = 'on_target_preservation';

    if (rpeDelta >= 1.5 || repsDelta <= -2) {
      // Significant Overshoot / Fatigue spike -> Reduce load by 5-7.5%
      newLoad = (previousSet.actualLoadKg * 0.935);
      // Round to nearest 2.5kg plate increment
      newLoad = (newLoad / 2.5).round() * 2.5;
      newRPE = 8.0;
      reason = 'rpe_overshoot_fatigue_mitigation';
    } else if (rpeDelta <= -1.5 && repsDelta >= 0) {
      // Undershoot / Higher neural capacity -> Increase load by 2.5-5%
      newLoad = previousSet.actualLoadKg + 2.5;
      reason = 'performance_above_expected_load_ramp';
    }

    return AutoregulationAdjustment(
      adjustedLoadKg: newLoad,
      adjustedReps: newReps,
      adjustedTargetRPE: newRPE,
      reasonCode: reason,
    );
  }
}
