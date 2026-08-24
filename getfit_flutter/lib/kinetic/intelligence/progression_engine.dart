import 'dart:math';
import '../domain/models.dart';

/// Structured progressive overload recommendation retaining internal audit trails
class ProgressionRecommendation {
  /// Decision type: 'increase_load', 'increase_reps', 'maintain', 'reduce_load', 'reduce_volume', 'deload', 'recover'
  final String decision;

  /// Underlying recommendation action enum for domain consumers
  final RecommendationAction action;

  final double recommendedLoadKg;
  final int recommendedReps;
  final int recommendedSets;
  final double recommendedTargetRPE;

  /// Explicit rationale string
  final String reason;

  /// Key physiological and historical evidence
  final List<String> evidence;

  /// Audit trail of the raw inputs that produced this decision
  final Map<String, dynamic> inputs;

  final String modelVersion;

  const ProgressionRecommendation({
    required this.decision,
    required this.action,
    required this.recommendedLoadKg,
    required this.recommendedReps,
    required this.recommendedSets,
    this.recommendedTargetRPE = 8.0,
    required this.reason,
    required this.evidence,
    required this.inputs,
    required this.modelVersion,
  });

  String get primaryReasonCode => reason;

  Map<String, dynamic> toJson() => {
        'decision': decision,
        'action': action.name,
        'recommendedLoadKg': recommendedLoadKg,
        'recommendedReps': recommendedReps,
        'recommendedSets': recommendedSets,
        'recommendedTargetRPE': recommendedTargetRPE,
        'reason': reason,
        'evidence': evidence,
        'inputs': inputs,
        'modelVersion': modelVersion,
      };
}

/// Progressive Overload & Periodization Engine (SPEC.md Section 15)
class KineticProgressionEngine {
  static const String version = 'progression_model_v1.0';

  /// Evaluates historical performance and latent recovery to generate progressive overload targets
  static ProgressionRecommendation evaluateProgression({
    required Exercise exercise,
    required List<ExerciseSet> recentSets,
    required LatentPhysiologicalState recoveryState,
    int minRepTarget = 6,
    int maxRepTarget = 10,
    double targetRPE = 8.0,
  }) {
    final Map<String, dynamic> inputAudit = {
      'exerciseId': exercise.id,
      'exerciseName': exercise.name,
      'isCompound': exercise.isCompound,
      'minRepTarget': minRepTarget,
      'maxRepTarget': maxRepTarget,
      'targetRPE': targetRPE,
      'recoveryScore': recoveryState.recoveryScore,
      'fatigueScore': recoveryState.fatigueScore,
      'recentSetsCount': recentSets.length,
    };

    // 0. Base Initialization when no prior history is found
    if (recentSets.isEmpty) {
      return ProgressionRecommendation(
        decision: 'maintain',
        action: RecommendationAction.maintainLoad,
        recommendedLoadKg: 60.0,
        recommendedReps: (minRepTarget + maxRepTarget) ~/ 2,
        recommendedSets: 3,
        recommendedTargetRPE: targetRPE,
        reason: 'baseline_initialization',
        evidence: ['no_prior_history_found'],
        inputs: inputAudit,
        modelVersion: version,
      );
    }

    final lastLoad = recentSets.last.actualLoadKg;
    final avgRPE = recentSets.map((s) => s.actualRPE).reduce((a, b) => a + b) / recentSets.length;
    final avgReps = recentSets.map((s) => s.actualReps).reduce((a, b) => a + b) / recentSets.length;

    // 1. Recover / Full Rest Check (extreme systemic fatigue)
    if (recoveryState.recoveryScore < 30.0) {
      return ProgressionRecommendation(
        decision: 'recover',
        action: RecommendationAction.rest,
        recommendedLoadKg: 0.0,
        recommendedReps: 0,
        recommendedSets: 0,
        reason: 'systemic_depletion_full_recovery_prescribed',
        evidence: [
          'recovery_score_${recoveryState.recoveryScore}_lt_30',
          'fatigue_score_${recoveryState.fatigueScore}',
        ],
        inputs: inputAudit,
        modelVersion: version,
      );
    }

    // 2. Deload Check (accumulated fatigue or multi-session overreach)
    if (recoveryState.recoveryScore < 45.0 && recoveryState.fatigueScore > 70.0) {
      final deloadLoad = ((lastLoad * 0.80) / 2.5).round() * 2.5;
      return ProgressionRecommendation(
        decision: 'deload',
        action: RecommendationAction.deload,
        recommendedLoadKg: deloadLoad,
        recommendedReps: minRepTarget,
        recommendedSets: 2,
        recommendedTargetRPE: 6.5,
        reason: 'systemic_fatigue_deload_indicated',
        evidence: [
          'recovery_score_${recoveryState.recoveryScore}',
          'fatigue_score_${recoveryState.fatigueScore}',
        ],
        inputs: inputAudit,
        modelVersion: version,
      );
    }

    // 3. Reduce Load Check (acute performance degradation)
    if (avgRPE >= 9.5 || avgReps < minRepTarget) {
      final reducedLoad = ((lastLoad * 0.925) / 2.5).round() * 2.5;
      return ProgressionRecommendation(
        decision: 'reduce_load',
        action: RecommendationAction.reduceLoad,
        recommendedLoadKg: reducedLoad,
        recommendedReps: minRepTarget,
        recommendedSets: recentSets.length,
        recommendedTargetRPE: targetRPE,
        reason: 'rpe_overshoot_load_reduction',
        evidence: [
          'avg_rpe_${avgRPE.toStringAsFixed(1)}_exceeds_threshold',
          'avg_reps_${avgReps.toStringAsFixed(1)}_below_floor',
        ],
        inputs: inputAudit,
        modelVersion: version,
      );
    }

    // 4. Reduce Volume Check (excessive intra-session fatigue / volume accumulation)
    if (recentSets.length >= 4 && (avgRPE >= 8.5 || recentSets.last.actualRPE >= 9.5 || recoveryState.fatigueScore > 65.0)) {
      return ProgressionRecommendation(
        decision: 'reduce_volume',
        action: RecommendationAction.reduceVolume,
        recommendedLoadKg: lastLoad,
        recommendedReps: avgReps.round().clamp(minRepTarget, maxRepTarget),
        recommendedSets: max(2, recentSets.length - 1),
        recommendedTargetRPE: targetRPE,
        reason: 'intra_session_fatigue_volume_reduction',
        evidence: [
          'sets_count_${recentSets.length}',
          'fatigue_score_${recoveryState.fatigueScore}',
        ],
        inputs: inputAudit,
        modelVersion: version,
      );
    }

    // 4. Double Progression: Increase Load Check
    // If all completed sets hit the rep ceiling (maxRepTarget) with RPE in reserve (<= targetRPE + 0.5)
    final allTopRepsHit = recentSets.every((s) => s.actualReps >= maxRepTarget && s.actualRPE <= (targetRPE + 0.5));
    if (allTopRepsHit) {
      final increment = exercise.isCompound ? 2.5 : 1.25;
      final newLoad = lastLoad + increment;
      return ProgressionRecommendation(
        decision: 'increase_load',
        action: RecommendationAction.increaseLoad,
        recommendedLoadKg: newLoad,
        recommendedReps: minRepTarget, // Reset to rep floor with new heavier load
        recommendedSets: recentSets.length,
        recommendedTargetRPE: targetRPE,
        reason: 'double_progression_rep_ceiling_achieved',
        evidence: [
          'completed_reps_ge_$maxRepTarget',
          'rpe_reserve_validated',
          'recovery_favorable_${recoveryState.recoveryScore}',
        ],
        inputs: inputAudit,
        modelVersion: version,
      );
    }

    // 5. Increase Reps Check (working up the double-progression rep range)
    if (avgReps < maxRepTarget && avgRPE <= (targetRPE + 0.5)) {
      return ProgressionRecommendation(
        decision: 'increase_reps',
        action: RecommendationAction.increaseReps,
        recommendedLoadKg: lastLoad,
        recommendedReps: (avgReps + 1).round().clamp(minRepTarget, maxRepTarget),
        recommendedSets: recentSets.length,
        recommendedTargetRPE: targetRPE,
        reason: 'double_progression_working_up_rep_range',
        evidence: [
          'avg_reps_${avgReps.toStringAsFixed(1)}_lt_$maxRepTarget',
          'rpe_in_reserve_${avgRPE.toStringAsFixed(1)}',
        ],
        inputs: inputAudit,
        modelVersion: version,
      );
    }

    // 6. Maintain
    return ProgressionRecommendation(
      decision: 'maintain',
      action: RecommendationAction.maintainLoad,
      recommendedLoadKg: lastLoad,
      recommendedReps: avgReps.round().clamp(minRepTarget, maxRepTarget),
      recommendedSets: recentSets.length,
      recommendedTargetRPE: targetRPE,
      reason: 'consolidation_at_current_workload',
      evidence: ['performance_on_track'],
      inputs: inputAudit,
      modelVersion: version,
    );
  }
}
