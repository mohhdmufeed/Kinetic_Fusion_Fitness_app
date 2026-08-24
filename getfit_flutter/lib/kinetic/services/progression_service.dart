import '../domain/models.dart';
import '../intelligence/training_engine.dart';
import '../intelligence/progression_engine.dart';
import '../persistence/kinetic_store.dart';

/// Application Service orchestrating dynamic workout generation, in-workout autoregulation, and progressive overload
class ProgressionService {
  static const String version = 'progression_service_v1.0';

  final KineticStore store;

  ProgressionService({KineticStore? store})
      : store = store ?? KineticStore.instance;

  /// Generates a structured workout prescription scaled by user readiness and training focus
  WorkoutSession generateWorkout({
    required String userId,
    required UserGoal goal,
    required TrainingFocus focus,
    required LatentPhysiologicalState readinessState,
    List<String> availableEquipment = const ['barbell', 'dumbbell', 'cable', 'bodyweight'],
    String? sessionId,
    DateTime? sessionTimestamp,
  }) {
    return KineticTrainingEngine.generateWorkout(
      userId: userId,
      goal: goal,
      focus: focus,
      readinessState: readinessState,
      availableEquipment: availableEquipment,
      sessionId: sessionId,
      sessionTimestamp: sessionTimestamp,
    );
  }

  /// Autoregulates subsequent set prescriptions based on live feedback from the previous set
  AutoregulationAdjustment autoregulateNextSet({
    required ExercisePrescription prescription,
    required ExerciseSet previousSet,
    required int nextSetNumber,
  }) {
    return KineticTrainingEngine.autoregulateNextSet(
      prescription: prescription,
      previousSet: previousSet,
      nextSetNumber: nextSetNumber,
    );
  }

  /// Evaluates historical performance to generate progressive overload targets
  ProgressionRecommendation evaluateProgression({
    required Exercise exercise,
    required List<ExerciseSet> recentSets,
    required LatentPhysiologicalState recoveryState,
    int minRepTarget = 6,
    int maxRepTarget = 10,
    double targetRPE = 8.0,
  }) {
    return KineticProgressionEngine.evaluateProgression(
      exercise: exercise,
      recentSets: recentSets,
      recoveryState: recoveryState,
      minRepTarget: minRepTarget,
      maxRepTarget: maxRepTarget,
      targetRPE: targetRPE,
    );
  }

  /// Applies calculated progression targets to update future prescriptions in a planned workout session
  WorkoutSession applyProgressionToSession({
    required WorkoutSession session,
    required Map<String, ProgressionRecommendation> progressions,
  }) {
    final List<ExercisePrescription> updatedPrescriptions = [];

    for (final p in session.prescriptions) {
      final rec = progressions[p.exerciseId];
      if (rec != null) {
        updatedPrescriptions.add(
          ExercisePrescription(
            exerciseId: p.exerciseId,
            exerciseName: p.exerciseName,
            targetSets: rec.recommendedSets > 0 ? rec.recommendedSets : p.targetSets,
            targetReps: rec.recommendedReps > 0 ? rec.recommendedReps : p.targetReps,
            targetLoadKg: rec.recommendedLoadKg > 0 ? rec.recommendedLoadKg : p.targetLoadKg,
            targetRPE: rec.recommendedTargetRPE,
            restSeconds: p.restSeconds,
            tempo: p.tempo,
            priority: p.priority,
            reasonCode: 'progressive_overload_${rec.decision}',
          ),
        );
      } else {
        updatedPrescriptions.add(p);
      }
    }

    return WorkoutSession(
      id: session.id,
      userId: session.userId,
      startTime: session.startTime,
      endTime: session.endTime,
      goal: session.goal,
      focus: session.focus,
      prescriptions: updatedPrescriptions,
      completedSets: session.completedSets,
      status: session.status,
      averageRPE: session.averageRPE,
      trainingLoad: session.trainingLoad,
    );
  }
}
