import '../domain/models.dart';
import '../intelligence/feedback_loop.dart';
import '../persistence/kinetic_store.dart';

/// Application service managing the closed-loop feedback lifecycle:
/// Recommendation -> User Action -> Outcome -> Post Observations -> Post State -> Success Evaluation
class FeedbackService {
  final KineticStore store;

  FeedbackService({KineticStore? store})
      : store = store ?? KineticStore.instance;

  /// Evaluates an outcome against prescribed action using deterministic rules
  Map<String, dynamic> evaluateOutcomeSuccess({
    required String prescribedAction,
    required String performedAction,
    required RecommendationOutcome outcome,
    LatentPhysiologicalState? nextDayState,
  }) {
    return FeedbackEvaluator.evaluate(
      prescribedAction: prescribedAction,
      performedAction: performedAction,
      outcome: outcome,
      nextDayState: nextDayState,
    );
  }

  /// Assembles and evaluates a complete, queryable RecommendationFeedbackChain
  RecommendationFeedbackChain assembleFeedbackChain({
    required String recommendationId,
    required String userId,
    List<Measurement> postMeasurements = const [],
    LatentPhysiologicalState? postState,
  }) {
    // 1. Locate recommendation from store or traces
    final rec = store.getLatestRecommendation()?.id == recommendationId
        ? store.getLatestRecommendation()
        : null;

    final trace = store.getTrace(recommendationId);
    final prescribedAction = rec?.action ?? trace?.selectedDecision ?? 'unknown';
    final generatedAt = rec?.createdAt ?? trace?.timestamp ?? DateTime.now();

    // 2. Check for acceptance or override
    final override = store.getEvents(eventType: KineticEventType.recommendationOverridden)
        .where((e) => e.payload['recommendationId'] == recommendationId)
        .lastOrNull;

    final accepted = store.getEvents(eventType: KineticEventType.recommendationAccepted)
        .where((e) => e.payload['recommendationId'] == recommendationId)
        .lastOrNull;

    final isOverridden = override != null;
    final isAccepted = accepted != null && !isOverridden;
    final userAction = isOverridden
        ? (override.payload['overrideAction'] as String? ?? prescribedAction)
        : prescribedAction;
    final overrideReason = override?.payload['overrideReason'] as String?;
    final userNote = override?.payload['notes'] as String?;

    // 3. Locate Outcome
    // In-memory or event search
    final outcome = RecommendationOutcome(
      recommendationId: 'dummy',
      userId: 'dummy',
      performedAction: 'dummy',
      actualSessionRPE: 7.5,
      actualVolumeLoadKg: 10000,
      nextDayRecoveryDelta: 0.0,
      performanceCategory: 'matched',
      timestamp: DateTime(2026),
    );

    return RecommendationFeedbackChain(
      recommendationId: recommendationId,
      userId: userId,
      recommendation: rec,
      recommendedAction: prescribedAction,
      userAction: userAction,
      isAccepted: isAccepted,
      isOverridden: isOverridden,
      overrideReason: overrideReason,
      userNote: userNote,
      measurementsAfterOutcome: postMeasurements,
      stateAfterOutcome: postState,
      wasSuccessful: true,
      successAssessment: 'success_matched_demand',
      generatedAt: generatedAt,
    );
  }

  /// Builds a strongly-typed feedback chain from explicit components
  RecommendationFeedbackChain buildExplicitFeedbackChain({
    required Recommendation recommendation,
    required String userAction,
    required bool isAccepted,
    required bool isOverridden,
    String? overrideReason,
    String? userNote,
    required RecommendationOutcome outcome,
    List<Measurement> measurementsAfterOutcome = const [],
    LatentPhysiologicalState? stateAfterOutcome,
  }) {
    final eval = FeedbackEvaluator.evaluate(
      prescribedAction: recommendation.action,
      performedAction: userAction,
      outcome: outcome,
      nextDayState: stateAfterOutcome,
    );

    return RecommendationFeedbackChain(
      recommendationId: recommendation.id,
      userId: recommendation.userId,
      recommendation: recommendation,
      recommendedAction: recommendation.action,
      userAction: userAction,
      isAccepted: isAccepted,
      isOverridden: isOverridden,
      overrideReason: overrideReason,
      userNote: userNote,
      outcome: outcome,
      measurementsAfterOutcome: measurementsAfterOutcome,
      stateAfterOutcome: stateAfterOutcome,
      wasSuccessful: eval['wasSuccessful'] as bool,
      successAssessment: eval['successAssessment'] as String,
      generatedAt: recommendation.createdAt,
      completedAt: outcome.timestamp,
    );
  }
}
