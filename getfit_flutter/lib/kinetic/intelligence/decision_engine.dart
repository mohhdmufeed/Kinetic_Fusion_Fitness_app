import '../domain/models.dart';
import '../persistence/kinetic_store.dart';
import 'feature_engine.dart';

/// Evaluated candidate action with utility score and rationale
class CandidateActionEvaluation {
  final String action; // 'train_hard', 'train_normal', 'train_light', 'active_recovery', 'walk', 'rest', 'modify_workout', 'increase_load', 'maintain', 'reduce_load'
  final double utilityScore;
  final bool isEligible;
  final String rationale;

  const CandidateActionEvaluation({
    required this.action,
    required this.utilityScore,
    required this.isEligible,
    required this.rationale,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'utilityScore': utilityScore,
        'isEligible': isEligible,
        'rationale': rationale,
      };
}

/// Pluggable utility scoring interface for candidate actions
abstract class DecisionUtilityScorer {
  List<CandidateActionEvaluation> evaluateCandidates({
    required LatentPhysiologicalState latentState,
    required PhysiologicalFeatures features,
    required UserGoal goal,
    required TrainingFocus focus,
    Map<String, dynamic> constraints = const {},
  });
}

/// Default deterministic utility scoring function evaluating competing candidate actions
class DefaultUtilityScorer implements DecisionUtilityScorer {
  @override
  List<CandidateActionEvaluation> evaluateCandidates({
    required LatentPhysiologicalState latentState,
    required PhysiologicalFeatures features,
    required UserGoal goal,
    required TrainingFocus focus,
    Map<String, dynamic> constraints = const {},
  }) {
    final List<CandidateActionEvaluation> candidates = [];
    final readiness = latentState.readinessScore;
    final recovery = latentState.recoveryScore;
    final fatigue = latentState.fatigueScore;
    final acwr = features.acwr;

    // 1. Train Hard
    bool canTrainHard = readiness >= 80.0 && acwr <= 1.35 && fatigue < 35.0;
    double utilityHard = canTrainHard
        ? (readiness * 0.85 + (goal.type == GoalType.hypertrophy || goal.type == GoalType.strength ? 20.0 : 10.0))
        : -50.0;
    candidates.add(CandidateActionEvaluation(
      action: 'train_hard',
      utilityScore: utilityHard,
      isEligible: canTrainHard,
      rationale: canTrainHard
          ? 'Readiness primed and acute:chronic load ratio in optimal sweet spot.'
          : 'Elevated fatigue or workload spike prohibits max intensity overload.',
    ));

    // 2. Train Normal
    bool canTrainNormal = readiness >= 60.0 && acwr <= 1.50;
    double utilityNormal = canTrainNormal ? (readiness * 0.75 + 10.0) : -20.0;
    candidates.add(CandidateActionEvaluation(
      action: 'train_normal',
      utilityScore: utilityNormal,
      isEligible: canTrainNormal,
      rationale: canTrainNormal
          ? 'Systemic recovery adequate to support prescribed progressive training volume.'
          : 'Suppressed HRV or accumulated fatigue advises lighter stimulus.',
    ));

    // 3. Train Light
    bool canTrainLight = readiness >= 45.0 && fatigue < 70.0;
    double utilityLight = canTrainLight ? (65.0 - (readiness - 50.0).abs() * 0.5) : -10.0;
    candidates.add(CandidateActionEvaluation(
      action: 'train_light',
      utilityScore: utilityLight,
      isEligible: canTrainLight,
      rationale: 'Sub-maximal loads promote blood flow without adding central nervous fatigue.',
    ));

    // 4. Active Recovery / Recover
    bool canActiveRecover = recovery < 60.0 || fatigue > 50.0;
    double utilityActiveRec = canActiveRecover ? (85.0 - (recovery - 45.0).abs()) : 35.0;
    candidates.add(CandidateActionEvaluation(
      action: 'active_recovery',
      utilityScore: utilityActiveRec,
      isEligible: true,
      rationale: 'Active recovery accelerates metabolic byproduct clearance and tissue repair.',
    ));

    // 5. Walk (Low intensity steady locomotion)
    double utilityWalk = (recovery < 65.0 && fatigue > 40.0) ? 75.0 : 40.0;
    candidates.add(CandidateActionEvaluation(
      action: 'walk',
      utilityScore: utilityWalk,
      isEligible: true,
      rationale: 'Low-stress parasympathetic walking supports recovery and daily energy balance.',
    ));

    // 6. Rest (Complete passive rest)
    bool requiresRest = recovery < 35.0 || fatigue > 80.0 || acwr > 1.65;
    double utilityRest = requiresRest ? (95.0 + (fatigue - 80.0) * 0.5) : 10.0;
    candidates.add(CandidateActionEvaluation(
      action: 'rest',
      utilityScore: utilityRest,
      isEligible: true,
      rationale: 'Autonomic nervous system depletion or dangerous workload spike requires complete cessation.',
    ));

    // 7. Modify Workout
    bool timeConstrained = constraints['timeMinutes'] != null && (constraints['timeMinutes'] as num) < 45;
    bool equipmentLimited = constraints['limitedEquipment'] == true;
    double utilityModify = (timeConstrained || equipmentLimited) ? 88.0 : (readiness < 55.0 ? 55.0 : 20.0);
    candidates.add(CandidateActionEvaluation(
      action: 'modify_workout',
      utilityScore: utilityModify,
      isEligible: true,
      rationale: (timeConstrained || equipmentLimited)
          ? 'Session constraints require volume or equipment adaptation.'
          : 'Prescription modifications dynamically adjusted for readiness.',
    ));

    // 8. Increase Load (Progressive Overload)
    bool canIncreaseLoad = readiness >= 75.0 && fatigue < 40.0;
    double utilityIncreaseLoad = canIncreaseLoad ? (readiness * 0.70 + 15.0) : -30.0;
    candidates.add(CandidateActionEvaluation(
      action: 'increase_load',
      utilityScore: utilityIncreaseLoad,
      isEligible: canIncreaseLoad,
      rationale: 'High neuromuscular reserve supports upward load progression.',
    ));

    // 9. Maintain (Consolidation)
    double utilityMaintain = (readiness >= 55.0 && readiness < 75.0) ? 65.0 : 30.0;
    candidates.add(CandidateActionEvaluation(
      action: 'maintain',
      utilityScore: utilityMaintain,
      isEligible: true,
      rationale: 'Consolidates current adaptation level without forcing overreach.',
    ));

    // 10. Reduce Load (Fatigue Management)
    bool needsReduceLoad = fatigue > 65.0 || acwr > 1.45;
    double utilityReduceLoad = needsReduceLoad ? (75.0 + (fatigue - 65.0) * 0.5) : -20.0;
    candidates.add(CandidateActionEvaluation(
      action: 'reduce_load',
      utilityScore: utilityReduceLoad,
      isEligible: true,
      rationale: 'Workload reduction mitigates overtraining and injury risk.',
    ));

    // Sort deterministically by utility score descending, with deterministic tie-breaking by action name
    candidates.sort((a, b) {
      final scoreCompare = b.utilityScore.compareTo(a.utilityScore);
      if (scoreCompare != 0) return scoreCompare;
      return a.action.compareTo(b.action);
    });

    return candidates;
  }
}

/// Decision Result Bundle
class RecommendationDecision {
  final Recommendation recommendation;
  final RecommendationTrace trace;

  const RecommendationDecision({
    required this.recommendation,
    required this.trace,
  });
}

/// Decision Engine & Recommendation Policy (SPEC.md Sections 18, 19, 22, 23)
class KineticDecisionEngine {
  /// Policy Semantic Version as required by SPEC
  static const String version = 'recommendation_policy_v1';

  /// Active pluggable utility scorer
  static DecisionUtilityScorer utilityScorer = DefaultUtilityScorer();

  /// Sets a custom utility scorer (e.g. multi-attribute Bayesian / RL policy)
  static void setScorer(DecisionUtilityScorer scorer) {
    utilityScorer = scorer;
  }

  /// Resets to default deterministic utility scorer
  static void resetScorer() {
    utilityScorer = DefaultUtilityScorer();
  }

  /// Evaluates competing candidate actions, scores utilities deterministically,
  /// selects the top recommendation, and generates a queryable RecommendationTrace.
  static RecommendationDecision makeDecision({
    required String userId,
    required LatentPhysiologicalState latentState,
    required PhysiologicalFeatures features,
    required UserGoal goal,
    required TrainingFocus focus,
    DateTime? deterministicTimestamp,
    Map<String, dynamic> constraints = const {},
  }) {
    final now = deterministicTimestamp ?? DateTime.now();

    // 1. Evaluate all candidate action utilities via pluggable scoring function
    final candidates = utilityScorer.evaluateCandidates(
      latentState: latentState,
      features: features,
      goal: goal,
      focus: focus,
      constraints: constraints,
    );

    final winningCandidate = candidates.first;
    final recommendationId = 'rec_${now.millisecondsSinceEpoch}_${winningCandidate.action}';

    // 2. Formulate headline and evidence based on chosen action
    String headline;
    final List<String> evidence = [];

    switch (winningCandidate.action) {
      case 'train_hard':
        headline = 'Optimal Readiness: Push for Overload';
        evidence.add('Readiness score at ${latentState.readinessScore.round()}/100 (Primed)');
        evidence.add('Acute:Chronic Workload Ratio in sweet spot (${features.acwr.toStringAsFixed(2)})');
        if (features.hrvZScore > 0) {
          evidence.add('HRV is +${features.hrvZScore.toStringAsFixed(1)}σ above baseline');
        }
        break;
      case 'train_normal':
        headline = 'Good Recovery: Progressive Training';
        evidence.add('Readiness score at ${latentState.readinessScore.round()}/100');
        evidence.add('Workload balanced at ACWR ${features.acwr.toStringAsFixed(2)}');
        break;
      case 'train_light':
        headline = 'Moderate Readiness: Light Technical Work';
        evidence.add('Readiness is ${latentState.readinessScore.round()}/100');
        evidence.add('Mild fatigue accumulation detected');
        break;
      case 'active_recovery':
        headline = 'Active Recovery Indicated';
        evidence.add('Recovery score at ${latentState.recoveryScore.round()}/100');
        evidence.add('Light locomotion or mobility advised');
        break;
      case 'walk':
        headline = 'Low-Intensity Parasympathetic Walk';
        evidence.add('Promotes recovery without central fatigue');
        break;
      case 'modify_workout':
        headline = 'Adapted Workout Recommended';
        evidence.add('Session constraints or readiness dictate modified volume/time');
        break;
      case 'increase_load':
        headline = 'Progressive Overload: Increase Load';
        evidence.add('High neuromuscular reserve detected');
        break;
      case 'maintain':
        headline = 'Consolidate Current Load';
        evidence.add('Steady adaptation without overreaching');
        break;
      case 'reduce_load':
        headline = 'Deload / Reduce Load Prescribed';
        evidence.add('Fatigue mitigation to prevent overtraining');
        break;
      default:
        headline = 'Full Rest & Restoration Recommended';
        evidence.add('Autonomic nervous system strain or high fatigue (${latentState.fatigueScore.round()}/100)');
        break;
    }

    // 3. Build unified Recommendation object
    final recommendation = Recommendation(
      id: recommendationId,
      userId: userId,
      type: 'training',
      action: winningCandidate.action,
      priority: 1,
      headline: headline,
      rationale: winningCandidate.rationale,
      evidence: evidence,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      status: 'pending',
      modelVersion: version,
      payload: {
        'chosenUtilityScore': winningCandidate.utilityScore,
        'goalType': goal.type.name,
      },
    );

    // 4. Build complete, queryable RecommendationTrace matching Section 23
    final trace = RecommendationTrace(
      recommendationId: recommendationId,
      userId: userId,
      modelVersion: version,
      timestamp: now,
      rawInputs: {
        'userId': userId,
        'goalType': goal.type.name,
        'trainingFocus': focus.name,
        'constraints': constraints,
      },
      derivedFeatures: {
        'acwr': features.acwr,
        'hrvZScore': features.hrvZScore,
        'rhrDelta': features.rhrDeltaBpm,
        'sleepDebt': features.sleepDebtHours,
      },
      estimatedLatentState: {
        'recoveryScore': latentState.recoveryScore,
        'readinessScore': latentState.readinessScore,
        'fatigueScore': latentState.fatigueScore,
        'direction': latentState.direction.name,
        'contributingFactors': latentState.contributingFactors,
      },
      candidateEvaluations: candidates.map((c) => c.toJson()).toList(),
      selectedDecision: winningCandidate.action,
      reasonCodes: [winningCandidate.rationale, ...latentState.contributingFactors],
    );

    // 5. Persist to KineticStore for queryability by the WHY screen
    KineticStore.instance.recordRecommendation(recommendation);
    KineticStore.instance.recordTrace(trace);

    return RecommendationDecision(
      recommendation: recommendation,
      trace: trace,
    );
  }
}
