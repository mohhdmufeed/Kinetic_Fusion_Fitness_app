import '../domain/models.dart';
import '../data/event_repository.dart';

/// Complete causal feedback chain representing:
/// Recommendation -> User Action -> Outcome -> Post-Outcome Observations -> Post-Outcome State -> Success Assessment
class RecommendationFeedbackChain {
  final String recommendationId;
  final String userId;
  final Recommendation? recommendation;
  final String recommendedAction;
  final String userAction;
  final bool isAccepted;
  final bool isOverridden;
  final String? overrideReason;
  final String? userNote;
  final RecommendationOutcome? outcome;
  final List<Measurement> measurementsAfterOutcome;
  final LatentPhysiologicalState? stateAfterOutcome;
  final bool wasSuccessful;
  final String successAssessment;
  final DateTime generatedAt;
  final DateTime? completedAt;

  const RecommendationFeedbackChain({
    required this.recommendationId,
    required this.userId,
    this.recommendation,
    required this.recommendedAction,
    required this.userAction,
    required this.isAccepted,
    required this.isOverridden,
    this.overrideReason,
    this.userNote,
    this.outcome,
    this.measurementsAfterOutcome = const [],
    this.stateAfterOutcome,
    required this.wasSuccessful,
    required this.successAssessment,
    required this.generatedAt,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'recommendationId': recommendationId,
        'userId': userId,
        'recommendation': recommendation?.toJson(),
        'recommendedAction': recommendedAction,
        'userAction': userAction,
        'isAccepted': isAccepted,
        'isOverridden': isOverridden,
        'overrideReason': overrideReason,
        'userNote': userNote,
        'outcome': outcome?.toJson(),
        'measurementsAfterOutcomeCount': measurementsAfterOutcome.length,
        'stateAfterOutcome': stateAfterOutcome != null
            ? {
                'recoveryScore': stateAfterOutcome!.recoveryScore,
                'readinessScore': stateAfterOutcome!.readinessScore,
                'fatigueScore': stateAfterOutcome!.fatigueScore,
                'direction': stateAfterOutcome!.direction.name,
              }
            : null,
        'wasSuccessful': wasSuccessful,
        'successAssessment': successAssessment,
        'generatedAt': generatedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };
}

/// Consolidated record of a recommendation's full lifecycle reconstructed from the immutable event log
class RecommendationLifecycleRecord {
  final String recommendationId;
  final String userId;
  final String prescribedAction;
  final DateTime generatedAt;
  final String status; // 'generated', 'accepted', 'overridden', 'dismissed'
  final String? overrideAction;
  final String? overrideReason;
  final String? userNote;
  final DateTime? overrideTimestamp;
  final Map<String, dynamic>? outcome;

  const RecommendationLifecycleRecord({
    required this.recommendationId,
    required this.userId,
    required this.prescribedAction,
    required this.generatedAt,
    required this.status,
    this.overrideAction,
    this.overrideReason,
    this.userNote,
    this.overrideTimestamp,
    this.outcome,
  });

  bool get wasOverridden => status == 'overridden';
  bool get wasAccepted => status == 'accepted';

  Map<String, dynamic> toJson() => {
        'recommendationId': recommendationId,
        'userId': userId,
        'prescribedAction': prescribedAction,
        'generatedAt': generatedAt.toIso8601String(),
        'status': status,
        'overrideAction': overrideAction,
        'overrideReason': overrideReason,
        'userNote': userNote,
        'overrideTimestamp': overrideTimestamp?.toIso8601String(),
        'outcome': outcome,
      };
}

/// Structured outcome payload after a recommendation or override has been performed
class RecommendationOutcome {
  final String recommendationId;
  final String userId;
  final String performedAction;
  final double actualSessionRPE;
  final double actualVolumeLoadKg;
  final double nextDayRecoveryDelta; // Delta in recovery/readiness score (+/-)
  final String performanceCategory; // 'exceeded', 'matched', 'underperformed', 'fatigue_spike'
  final DateTime timestamp;

  const RecommendationOutcome({
    required this.recommendationId,
    required this.userId,
    required this.performedAction,
    required this.actualSessionRPE,
    required this.actualVolumeLoadKg,
    required this.nextDayRecoveryDelta,
    required this.performanceCategory,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'recommendationId': recommendationId,
        'userId': userId,
        'performedAction': performedAction,
        'actualSessionRPE': actualSessionRPE,
        'actualVolumeLoadKg': actualVolumeLoadKg,
        'nextDayRecoveryDelta': nextDayRecoveryDelta,
        'performanceCategory': performanceCategory,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Evaluator assessing whether an action or override resulted in a successful physiological outcome
class FeedbackEvaluator {
  static const String version = 'feedback_evaluator_v1.0';

  static Map<String, dynamic> evaluate({
    required String prescribedAction,
    required String performedAction,
    required RecommendationOutcome outcome,
    LatentPhysiologicalState? nextDayState,
  }) {
    final isOverride = prescribedAction != performedAction;
    final isFatigueSpike = outcome.performanceCategory == 'fatigue_spike' || outcome.nextDayRecoveryDelta <= -15.0;
    final isMatchedOrExceeded = outcome.performanceCategory == 'matched' || outcome.performanceCategory == 'exceeded';
    final recoveryPreserved = outcome.nextDayRecoveryDelta >= -5.0;

    bool wasSuccessful;
    String assessment;

    if (!isOverride) {
      // Accepted Recommendation evaluation
      if (isFatigueSpike) {
        wasSuccessful = false;
        assessment = 'fatigue_spike_detected';
      } else if (isMatchedOrExceeded && recoveryPreserved) {
        wasSuccessful = true;
        assessment = 'success_matched_demand';
      } else if (outcome.performanceCategory == 'underperformed') {
        wasSuccessful = false;
        assessment = 'underperformance';
      } else {
        wasSuccessful = recoveryPreserved;
        assessment = recoveryPreserved ? 'recovery_preserved' : 'mild_fatigue_accumulation';
      }
    } else {
      // User Override evaluation
      if (isFatigueSpike) {
        wasSuccessful = false;
        assessment = 'override_caused_fatigue_spike';
      } else if (isMatchedOrExceeded && recoveryPreserved) {
        wasSuccessful = true;
        assessment = 'override_beneficial';
      } else {
        wasSuccessful = recoveryPreserved;
        assessment = recoveryPreserved ? 'override_tolerated' : 'override_overreach';
      }
    }

    return {
      'wasSuccessful': wasSuccessful,
      'successAssessment': assessment,
    };
  }
}

/// Feedback Loop & Override Intelligence Service reading directly from the immutable Event Ledger
/// (SPEC.md Sections 24 & 25)
class FeedbackEventService {
  final EventRepository eventRepo;

  FeedbackEventService(this.eventRepo);

  /// 1. Records initial recommendation generation event
  Future<void> recordRecommendationGenerated({
    required Recommendation recommendation,
  }) async {
    await eventRepo.appendEvent(KineticEvent(
      id: 'evt_gen_${recommendation.id}',
      userId: recommendation.userId,
      eventType: 'RecommendationGenerated',
      timestamp: recommendation.createdAt,
      payload: {
        'recommendationId': recommendation.id,
        'type': recommendation.type,
        'action': recommendation.action,
        'priority': recommendation.priority,
        'headline': recommendation.headline,
        'modelVersion': recommendation.modelVersion,
      },
    ));
  }

  /// 2. Records user acceptance event
  Future<void> recordRecommendationAccepted({
    required String recommendationId,
    required String userId,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    await eventRepo.appendEvent(KineticEvent(
      id: 'evt_acc_${recommendationId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      eventType: 'RecommendationAccepted',
      timestamp: now,
      payload: {
        'recommendationId': recommendationId,
      },
    ));
  }

  /// 3. Records user override event (prescribed vs chosen action + reason)
  Future<void> recordRecommendationOverridden({
    required String recommendationId,
    required String userId,
    required String prescribedAction,
    required String overrideAction,
    required String reason,
    String? userNote,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    await eventRepo.appendEvent(KineticEvent(
      id: 'evt_ovr_${recommendationId}_${now.millisecondsSinceEpoch}',
      userId: userId,
      eventType: 'RecommendationOverridden',
      timestamp: now,
      payload: {
        'recommendationId': recommendationId,
        'prescribedAction': prescribedAction,
        'overrideAction': overrideAction,
        'reason': reason,
        'userNote': userNote,
      },
    ));
  }

  /// 4. Records post-session physiological & performance outcome
  Future<void> recordOutcome(RecommendationOutcome outcome) async {
    await eventRepo.appendEvent(KineticEvent(
      id: 'evt_out_${outcome.recommendationId}_${outcome.timestamp.millisecondsSinceEpoch}',
      userId: outcome.userId,
      eventType: 'RecommendationOutcomeRecorded',
      timestamp: outcome.timestamp,
      payload: outcome.toJson(),
    ));
  }

  /// 5. Reconstructs a complete lifecycle history for a recommendation from the event log
  Future<RecommendationLifecycleRecord?> getRecommendationLifecycle(
    String recommendationId, {
    required String userId,
  }) async {
    final events = await eventRepo.getEvents(userId: userId);
    final recEvents = events
        .where((e) => e.payload['recommendationId'] == recommendationId)
        .toList();

    if (recEvents.isEmpty) return null;

    final genEvent = recEvents.firstWhere(
      (e) => e.eventType == 'RecommendationGenerated',
      orElse: () => recEvents.first,
    );

    final prescribedAction = (genEvent.payload['action'] as String?) ?? 'unknown';
    final generatedAt = genEvent.timestamp;

    final overrideEvent = recEvents.where((e) => e.eventType == 'RecommendationOverridden').lastOrNull;
    final acceptedEvent = recEvents.where((e) => e.eventType == 'RecommendationAccepted').lastOrNull;
    final outcomeEvent = recEvents.where((e) => e.eventType == 'RecommendationOutcomeRecorded').lastOrNull;

    String status = 'generated';
    if (overrideEvent != null) {
      status = 'overridden';
    } else if (acceptedEvent != null) {
      status = 'accepted';
    }

    return RecommendationLifecycleRecord(
      recommendationId: recommendationId,
      userId: userId,
      prescribedAction: prescribedAction,
      generatedAt: generatedAt,
      status: status,
      overrideAction: overrideEvent?.payload['overrideAction'] as String?,
      overrideReason: overrideEvent?.payload['reason'] as String?,
      userNote: overrideEvent?.payload['userNote'] as String?,
      overrideTimestamp: overrideEvent?.timestamp,
      outcome: outcomeEvent?.payload,
    );
  }

  /// 6. Queries all overridden recommendations with their subsequent outcomes for model tuning
  Future<List<RecommendationLifecycleRecord>> getAllOverrideOutcomes(String userId) async {
    final events = await eventRepo.getEvents(userId: userId);
    final overrideEvents = events.where((e) => e.eventType == 'RecommendationOverridden').toList();

    final List<RecommendationLifecycleRecord> records = [];
    for (final ovr in overrideEvents) {
      final recId = ovr.payload['recommendationId'] as String?;
      if (recId != null) {
        final record = await getRecommendationLifecycle(recId, userId: userId);
        if (record != null) {
          records.add(record);
        }
      }
    }

    return records;
  }
}
