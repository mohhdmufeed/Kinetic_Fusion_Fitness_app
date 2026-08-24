import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/data/database_manager.dart';
import 'package:kinetic_precision/kinetic/data/migration.dart';
import 'package:kinetic_precision/kinetic/data/migrations/migration_v1_measurements_events.dart';
import 'package:kinetic_precision/kinetic/data/event_repository.dart';
import 'package:kinetic_precision/kinetic/intelligence/feedback_loop.dart';
import 'package:kinetic_precision/kinetic/intelligence/contracts.dart';
import 'package:kinetic_precision/kinetic/services/feedback_service.dart';
import 'package:kinetic_precision/kinetic/kinetic_core.dart';

void main() {
  group('Phase 9: Feedback Loop, Overrides & Closed-Loop Learning Tests', () {
    late KineticDatabaseManager dbManager;
    late EventRepository eventRepo;
    late FeedbackEventService feedbackEventService;
    final feedbackService = FeedbackService();

    setUp(() async {
      final registry = MigrationRegistry();
      registry.register(MigrationV1MeasurementsEvents());
      registry.register(MigrationV2DomainModels());
      dbManager = KineticDatabaseManager.inMemory(registry: registry);
      await dbManager.migrateToLatest();

      eventRepo = EventRepository(dbManager.executor);
      feedbackEventService = FeedbackEventService(eventRepo);
    });

    tearDown(() async {
      await dbManager.close();
    });

    test('1. Full Lifecycle Reconstructed from Event Log: Gen -> Override -> Outcome', () async {
      const userId = 'user_feedback_test_1';
      final now = DateTime.utc(2026, 8, 18, 10, 0, 0);

      final rec = Recommendation(
        id: 'rec_20260818_1000',
        userId: userId,
        type: 'training',
        action: 'train_light',
        priority: 1,
        headline: 'Moderate Readiness: Light Technical Session',
        rationale: 'Suppressed HRV recommends avoiding heavy neurological load.',
        evidence: ['HRV is -1.1σ below baseline', 'Fatigue score 62/100'],
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        status: 'pending',
        modelVersion: 'recommendation_policy_v1',
      );

      await feedbackEventService.recordRecommendationGenerated(recommendation: rec);

      var lifecycle = await feedbackEventService.getRecommendationLifecycle(rec.id, userId: userId);
      expect(lifecycle != null, isTrue);
      expect(lifecycle?.status, equals('generated'));
      expect(lifecycle?.prescribedAction, equals('train_light'));

      // User overrides recommendation
      await feedbackEventService.recordRecommendationOverridden(
        recommendationId: rec.id,
        userId: userId,
        prescribedAction: 'train_light',
        overrideAction: 'train_hard',
        reason: 'felt_energetic_subjectively',
        userNote: 'Had extra espresso and trained heavy squats anyway',
        timestamp: now.add(const Duration(minutes: 15)),
      );

      lifecycle = await feedbackEventService.getRecommendationLifecycle(rec.id, userId: userId);
      expect(lifecycle?.status, equals('overridden'));
      expect(lifecycle?.wasOverridden, isTrue);
      expect(lifecycle?.overrideAction, equals('train_hard'));

      // Record resulting outcome
      final outcome = RecommendationOutcome(
        recommendationId: rec.id,
        userId: userId,
        performedAction: 'train_hard',
        actualSessionRPE: 9.5,
        actualVolumeLoadKg: 5200.0,
        nextDayRecoveryDelta: -18.5,
        performanceCategory: 'fatigue_spike',
        timestamp: now.add(const Duration(hours: 2)),
      );
      await feedbackEventService.recordOutcome(outcome);

      final fullLifecycle = await feedbackEventService.getRecommendationLifecycle(rec.id, userId: userId);
      expect(fullLifecycle?.outcome?['actualSessionRPE'], equals(9.5));
      expect(fullLifecycle?.outcome?['performanceCategory'], equals('fatigue_spike'));

      final allOverrides = await feedbackEventService.getAllOverrideOutcomes(userId);
      expect(allOverrides.length, equals(1));
    });

    test('2. Complete Feedback Chain & Success Evaluator: Accepted + Matched + Recovery Preserved', () {
      final now = DateTime.utc(2026, 8, 18, 10, 0, 0);
      final rec = Recommendation(
        id: 'rec_acc_01',
        userId: 'u_eval_1',
        type: 'training',
        action: 'train_normal',
        priority: 1,
        headline: 'Good Recovery: Progressive Hypertrophy',
        rationale: 'Balanced recovery supports planned training volume.',
        evidence: ['HRV normal', 'Sleep 8.2h'],
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        status: 'pending',
        modelVersion: 'recommendation_policy_v1',
      );

      final outcome = RecommendationOutcome(
        recommendationId: rec.id,
        userId: 'u_eval_1',
        performedAction: 'train_normal',
        actualSessionRPE: 8.0,
        actualVolumeLoadKg: 4500.0,
        nextDayRecoveryDelta: 3.0, // Recovery increased or stable
        performanceCategory: 'matched',
        timestamp: now.add(const Duration(hours: 3)),
      );

      final chain = feedbackService.buildExplicitFeedbackChain(
        recommendation: rec,
        userAction: 'train_normal',
        isAccepted: true,
        isOverridden: false,
        outcome: outcome,
      );

      expect(chain.wasSuccessful, isTrue);
      expect(chain.successAssessment, equals('success_matched_demand'));
      expect(chain.recommendedAction, equals('train_normal'));
      expect(chain.userAction, equals('train_normal'));
    });

    test('3. Success Evaluator: Accepted + Fatigue Spike -> wasSuccessful = false', () {
      final now = DateTime.utc(2026, 8, 18, 10, 0, 0);
      final rec = Recommendation(
        id: 'rec_spike_01',
        userId: 'u_eval_2',
        type: 'training',
        action: 'train_hard',
        priority: 1,
        headline: 'Push Load',
        rationale: 'High readiness',
        evidence: ['HRV high'],
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        status: 'pending',
        modelVersion: 'recommendation_policy_v1',
      );

      final outcome = RecommendationOutcome(
        recommendationId: rec.id,
        userId: 'u_eval_2',
        performedAction: 'train_hard',
        actualSessionRPE: 9.8,
        actualVolumeLoadKg: 8000.0,
        nextDayRecoveryDelta: -20.0, // Severe recovery drop
        performanceCategory: 'fatigue_spike',
        timestamp: now.add(const Duration(hours: 3)),
      );

      final chain = feedbackService.buildExplicitFeedbackChain(
        recommendation: rec,
        userAction: 'train_hard',
        isAccepted: true,
        isOverridden: false,
        outcome: outcome,
      );

      expect(chain.wasSuccessful, isFalse);
      expect(chain.successAssessment, equals('fatigue_spike_detected'));
    });

    test('4. Success Evaluator: User Override with Positive Adaptation -> override_beneficial', () {
      final now = DateTime.utc(2026, 8, 18, 10, 0, 0);
      final rec = Recommendation(
        id: 'rec_ovr_pos',
        userId: 'u_eval_3',
        type: 'training',
        action: 'train_light', // Engine suggested light
        priority: 1,
        headline: 'Moderate',
        rationale: 'Caution advised',
        evidence: [],
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        status: 'pending',
        modelVersion: 'recommendation_policy_v1',
      );

      final outcome = RecommendationOutcome(
        recommendationId: rec.id,
        userId: 'u_eval_3',
        performedAction: 'train_normal', // User chose normal and handled it well
        actualSessionRPE: 7.5,
        actualVolumeLoadKg: 5000.0,
        nextDayRecoveryDelta: 2.0,
        performanceCategory: 'exceeded',
        timestamp: now.add(const Duration(hours: 3)),
      );

      final chain = feedbackService.buildExplicitFeedbackChain(
        recommendation: rec,
        userAction: 'train_normal',
        isAccepted: false,
        isOverridden: true,
        overrideReason: 'felt_strong_after_caffeine',
        outcome: outcome,
      );

      expect(chain.wasSuccessful, isTrue);
      expect(chain.successAssessment, equals('override_beneficial'));
    });

    test('5. Future ML Preparation Contracts: Predictor, Policy, Scorer, and Optimizer interfaces', () {
      // 1. Mock Scorer
      final scorer = _MockScorer();
      expect(scorer.version, equals('mock_scorer_v1'));
      expect(scorer.score('train_hard', {'readiness': 90.0}), equals(95.0));

      // 2. Mock Predictor
      final predictor = _MockPredictor();
      expect(predictor.version, equals('mock_predictor_v1'));
      expect(predictor.predict({'sleep': 8.0}), equals(85.0));

      // 3. Mock Policy
      final policy = _MockPolicy();
      expect(policy.version, equals('mock_policy_v1'));

      // 4. Mock Optimizer
      final optimizer = _MockOptimizer();
      expect(optimizer.version, equals('mock_optimizer_v1'));
      expect(optimizer.optimize([1.0, 2.0, 3.0]), equals(3.0));
    });
  });
}

class _MockScorer implements Scorer<String, Map<String, dynamic>, double> {
  @override
  String get version => 'mock_scorer_v1';

  @override
  double score(String candidate, Map<String, dynamic> context) {
    final readiness = (context['readiness'] as num?)?.toDouble() ?? 50.0;
    return candidate == 'train_hard' ? readiness + 5.0 : 50.0;
  }
}

class _MockPredictor implements Predictor<Map<String, dynamic>, double> {
  @override
  String get version => 'mock_predictor_v1';

  @override
  double predict(Map<String, dynamic> features) {
    return 85.0;
  }
}

class _MockPolicy implements Policy<LatentPhysiologicalState, UserGoal, String> {
  @override
  String get version => 'mock_policy_v1';

  @override
  Recommendation selectAction(LatentPhysiologicalState state, UserGoal goal, List<String> candidateActions) {
    return Recommendation(
      id: 'rec_mock',
      userId: goal.userId,
      type: 'training',
      action: candidateActions.first,
      headline: 'Mock Policy Action',
      rationale: 'Mock policy evaluation',
      evidence: const [],
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      modelVersion: version,
    );
  }
}

class _MockOptimizer implements Optimizer<List<double>, double> {
  @override
  String get version => 'mock_optimizer_v1';

  @override
  double optimize(List<double> problem) {
    return problem.reduce((a, b) => a > b ? a : b);
  }
}
