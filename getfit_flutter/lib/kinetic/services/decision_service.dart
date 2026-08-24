import '../domain/models.dart';
import '../intelligence/decision_engine.dart';
import '../intelligence/feature_engine.dart';
import '../intelligence/feedback_loop.dart';
import '../persistence/kinetic_store.dart';

/// Application service orchestrating the core Kinetic Precision decision loop:
/// Observe -> Estimate State -> Evaluate Candidate Actions -> Recommend -> Explain -> Accept/Override -> Record Outcome
class DecisionService {
  final KineticStore store;

  DecisionService({KineticStore? store})
      : store = store ?? KineticStore.instance;

  /// Evaluates competing candidate actions, selects top recommendation, generates trace, and persists to local store
  RecommendationDecision evaluateRecommendation({
    required String userId,
    required LatentPhysiologicalState latentState,
    required PhysiologicalFeatures features,
    required UserGoal goal,
    required TrainingFocus focus,
    DateTime? deterministicTimestamp,
    Map<String, dynamic> constraints = const {},
  }) {
    return KineticDecisionEngine.makeDecision(
      userId: userId,
      latentState: latentState,
      features: features,
      goal: goal,
      focus: focus,
      deterministicTimestamp: deterministicTimestamp,
      constraints: constraints,
    );
  }

  /// Records user acceptance of the prescribed recommendation
  void acceptRecommendation(String recommendationId) {
    final now = DateTime.now();
    store.recordEvent(KineticEvent(
      id: 'evt_accept_${now.millisecondsSinceEpoch}',
      userId: store.getUser()?.id ?? 'u_default',
      eventType: KineticEventType.recommendationAccepted,
      timestamp: now,
      payload: {'recommendationId': recommendationId},
    ));
  }

  /// Records user override with rationale and non-coercive custom action
  void overrideRecommendation({
    required String recommendationId,
    required String overrideAction,
    required String overrideReason,
    String? notes,
  }) {
    final now = DateTime.now();
    final effectiveUserId = store.getUser()?.id ?? 'u_default';
    final override = UserOverride(
      id: 'ovr_${now.millisecondsSinceEpoch}',
      recommendationId: recommendationId,
      userId: effectiveUserId,
      recommendedAction: RecommendationAction.trainNormal,
      userAction: overrideAction,
      overrideReason: overrideReason,
      timestamp: now,
      outcome: notes != null ? {'notes': notes} : const {},
    );
    store.recordOverride(override);

    store.recordEvent(KineticEvent(
      id: 'evt_override_${now.millisecondsSinceEpoch}',
      userId: effectiveUserId,
      eventType: KineticEventType.recommendationOverridden,
      timestamp: now,
      payload: {
        'recommendationId': recommendationId,
        'overrideAction': overrideAction,
        'overrideReason': overrideReason,
        'notes': notes,
      },
    ));
  }

  /// Records real-world training/recovery outcome for closed-loop validation
  void recordOutcome({
    required String recommendationId,
    required String userId,
    required String performedAction,
    required double actualSessionRPE,
    required double actualVolumeLoadKg,
    required double nextDayRecoveryDelta,
    required String performanceCategory,
    DateTime? timestamp,
  }) {
    final effectiveTime = timestamp ?? DateTime.now();
    final outcome = RecommendationOutcome(
      recommendationId: recommendationId,
      userId: userId,
      performedAction: performedAction,
      actualSessionRPE: actualSessionRPE,
      actualVolumeLoadKg: actualVolumeLoadKg,
      nextDayRecoveryDelta: nextDayRecoveryDelta,
      performanceCategory: performanceCategory,
      timestamp: effectiveTime,
    );
    store.recordOutcome(outcome);
  }

  /// Retrieves full WHY explanation trace for a given recommendation ID
  RecommendationTrace? getRecommendationTrace(String recommendationId) {
    return store.getTrace(recommendationId);
  }
}
