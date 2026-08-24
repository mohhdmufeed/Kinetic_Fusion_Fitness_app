import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/intelligence/feature_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/decision_engine.dart';
import 'package:kinetic_precision/kinetic/services/decision_service.dart';
import 'package:kinetic_precision/kinetic/persistence/kinetic_store.dart';

void main() {
  group('Phase 8: Recommendation & Decision Engine Tests', () {
    const defaultGoal = UserGoal(id: 'g1', userId: 'u_dec_test', type: GoalType.hypertrophy);

    final fixedTime = DateTime(2026, 8, 18, 10, 0, 0);

    test('1. Competing Candidates Evaluation: Evaluates, scores, and ranks all candidate actions', () {
      final latentState = LatentPhysiologicalState(
        recoveryScore: 85.0,
        fatigueScore: 20.0,
        readinessScore: 88.0,
        adaptationScore: 80.0,
        energyScore: 85.0,
        direction: TrendDirection.improving,
        contributingFactors: ['sleep_restored'],
        dataQualityScore: 1.0,
        timestamp: fixedTime,
        modelVersion: 'v1',
      );

      final features = const PhysiologicalFeatures(
        hrvZScore: 1.2,
        rhrDeltaBpm: -1.0,
        sleepDebtHours: 0.0,
        sleepQualityScore: 90.0,
        acuteTrainingLoad: 350.0,
        chronicTrainingLoad: 330.0,
        acwr: 1.06,
        activityStepsDelta: 1000.0,
        dataCompleteness: 1.0,
        rawFeatureMap: {},
      );

      final scorer = DefaultUtilityScorer();
      final candidates = scorer.evaluateCandidates(
        latentState: latentState,
        features: features,
        goal: defaultGoal,
        focus: TrainingFocus.hypertrophy,
      );

      // Verify all candidate actions are evaluated
      final actionNames = candidates.map((c) => c.action).toList();
      expect(actionNames, contains('train_hard'));
      expect(actionNames, contains('train_normal'));
      expect(actionNames, contains('train_light'));
      expect(actionNames, contains('active_recovery'));
      expect(actionNames, contains('walk'));
      expect(actionNames, contains('rest'));
      expect(actionNames, contains('modify_workout'));
      expect(actionNames, contains('increase_load'));
      expect(actionNames, contains('maintain'));
      expect(actionNames, contains('reduce_load'));

      // Highest utility should be train_hard for primed athlete
      expect(candidates.first.action, equals('train_hard'));
      expect(candidates.first.utilityScore, greaterThan(70.0));
      expect(candidates.first.isEligible, isTrue);
    });

    test('2. Decision Selection: User A (High Recovery & Primed) selects train_hard', () {
      final decisionService = DecisionService();
      final latentState = LatentPhysiologicalState(
        recoveryScore: 92.0,
        fatigueScore: 12.0,
        readinessScore: 94.0,
        adaptationScore: 90.0,
        energyScore: 92.0,
        direction: TrendDirection.improving,
        contributingFactors: ['hrv_high', 'sleep_optimal'],
        dataQualityScore: 1.0,
        timestamp: fixedTime,
        modelVersion: 'v1',
      );

      final features = const PhysiologicalFeatures(
        hrvZScore: 1.6,
        rhrDeltaBpm: -3.0,
        sleepDebtHours: 0.0,
        sleepQualityScore: 95.0,
        acuteTrainingLoad: 320.0,
        chronicTrainingLoad: 310.0,
        acwr: 1.03,
        activityStepsDelta: 2000.0,
        dataCompleteness: 1.0,
        rawFeatureMap: {},
      );

      final decision = decisionService.evaluateRecommendation(
        userId: 'u_user_a',
        latentState: latentState,
        features: features,
        goal: defaultGoal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: fixedTime,
      );

      expect(decision.recommendation.action, equals('train_hard'));
      expect(decision.recommendation.headline, contains('Optimal Readiness'));
      expect(decision.recommendation.evidence.any((e) => e.contains('Readiness score')), isTrue);
      expect(decision.recommendation.status, equals('pending'));
    });

    test('3. Decision Selection: User B (Severe Fatigue & Workload Spike) selects rest', () {
      final decisionService = DecisionService();
      final exhaustedState = LatentPhysiologicalState(
        recoveryScore: 28.0,
        fatigueScore: 88.0,
        readinessScore: 25.0,
        adaptationScore: 35.0,
        energyScore: 25.0,
        direction: TrendDirection.declining,
        contributingFactors: ['sleep_debt_critical', 'hrv_suppressed'],
        dataQualityScore: 1.0,
        timestamp: fixedTime,
        modelVersion: 'v1',
      );

      final exhaustedFeatures = const PhysiologicalFeatures(
        hrvZScore: -2.1,
        rhrDeltaBpm: 10.0,
        sleepDebtHours: 5.0,
        sleepQualityScore: 30.0,
        acuteTrainingLoad: 650.0,
        chronicTrainingLoad: 350.0,
        acwr: 1.85, // Dangerous spike
        activityStepsDelta: -4000.0,
        dataCompleteness: 1.0,
        rawFeatureMap: {},
      );

      final decision = decisionService.evaluateRecommendation(
        userId: 'u_user_b',
        latentState: exhaustedState,
        features: exhaustedFeatures,
        goal: defaultGoal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: fixedTime,
      );

      expect(decision.recommendation.action, equals('rest'));
      expect(decision.recommendation.headline, contains('Rest'));
    });

    test('4. Recommendation Trace Auditability: Retains full inputs, state, candidate rankings, and reason codes', () {
      final decisionService = DecisionService();
      final latentState = LatentPhysiologicalState(
        recoveryScore: 75.0,
        fatigueScore: 30.0,
        readinessScore: 78.0,
        adaptationScore: 75.0,
        energyScore: 75.0,
        direction: TrendDirection.improving,
        contributingFactors: ['steady_adaptation'],
        dataQualityScore: 1.0,
        timestamp: fixedTime,
        modelVersion: 'v1',
      );

      final features = const PhysiologicalFeatures(
        hrvZScore: 0.0,
        rhrDeltaBpm: 0.0,
        sleepDebtHours: 0.5,
        sleepQualityScore: 80.0,
        acuteTrainingLoad: 300.0,
        chronicTrainingLoad: 300.0,
        acwr: 1.0,
        activityStepsDelta: 500.0,
        dataCompleteness: 0.90,
        rawFeatureMap: {},
      );

      final decision = decisionService.evaluateRecommendation(
        userId: 'u_trace_test',
        latentState: latentState,
        features: features,
        goal: defaultGoal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: fixedTime,
      );

      final trace = decision.trace;
      expect(trace.recommendationId, equals(decision.recommendation.id));
      expect(trace.rawInputs['userId'], equals('u_trace_test'));
      expect(trace.derivedFeatures['acwr'], equals(1.0));
      expect(trace.estimatedLatentState['readinessScore'], equals(78.0));
      expect(trace.candidateEvaluations.length, equals(10));
      expect(trace.selectedDecision, equals(decision.recommendation.action));
      expect(trace.reasonCodes.isNotEmpty, isTrue);

      // Verify queryability from store via DecisionService
      final retrievedTrace = decisionService.getRecommendationTrace(decision.recommendation.id);
      expect(retrievedTrace, isNotNull);
      expect(retrievedTrace!.recommendationId, equals(decision.recommendation.id));
    });

    test('5. Bit-for-Bit Determinism: Identical inputs produce bit-for-bit identical recommendations & traces', () {
      final latentState = LatentPhysiologicalState(
        recoveryScore: 80.0,
        fatigueScore: 25.0,
        readinessScore: 82.0,
        adaptationScore: 80.0,
        energyScore: 80.0,
        direction: TrendDirection.improving,
        contributingFactors: ['favorable_recovery'],
        dataQualityScore: 1.0,
        timestamp: fixedTime,
        modelVersion: 'v1',
      );

      final features = const PhysiologicalFeatures(
        hrvZScore: 0.5,
        rhrDeltaBpm: 0.0,
        sleepDebtHours: 0.0,
        sleepQualityScore: 85.0,
        acuteTrainingLoad: 310.0,
        chronicTrainingLoad: 300.0,
        acwr: 1.03,
        activityStepsDelta: 1000.0,
        dataCompleteness: 0.95,
        rawFeatureMap: {},
      );

      final run1 = KineticDecisionEngine.makeDecision(
        userId: 'u_det_test',
        latentState: latentState,
        features: features,
        goal: defaultGoal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: fixedTime,
      );

      final run2 = KineticDecisionEngine.makeDecision(
        userId: 'u_det_test',
        latentState: latentState,
        features: features,
        goal: defaultGoal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: fixedTime,
      );

      expect(run1.recommendation.id, equals(run2.recommendation.id));
      expect(run1.recommendation.action, equals(run2.recommendation.action));
      expect(run1.recommendation.rationale, equals(run2.recommendation.rationale));
      expect(run1.trace.candidateEvaluations.length, equals(run2.trace.candidateEvaluations.length));
    });

    test('6. Complete Intelligence Loop: Observe -> Estimate -> Decide -> Accept -> Override -> Record Outcome', () {
      final decisionService = DecisionService();
      final store = KineticStore.instance;

      final latentState = LatentPhysiologicalState(
        recoveryScore: 70.0,
        fatigueScore: 35.0,
        readinessScore: 72.0,
        adaptationScore: 70.0,
        energyScore: 70.0,
        direction: TrendDirection.stable,
        contributingFactors: ['moderate_readiness'],
        dataQualityScore: 1.0,
        timestamp: fixedTime,
        modelVersion: 'v1',
      );

      final features = const PhysiologicalFeatures(
        hrvZScore: 0.0,
        rhrDeltaBpm: 0.0,
        sleepDebtHours: 1.0,
        sleepQualityScore: 75.0,
        acuteTrainingLoad: 320.0,
        chronicTrainingLoad: 320.0,
        acwr: 1.0,
        activityStepsDelta: 0.0,
        dataCompleteness: 0.90,
        rawFeatureMap: {},
      );

      // 1. Evaluate Recommendation
      final decision = decisionService.evaluateRecommendation(
        userId: 'u_loop_test',
        latentState: latentState,
        features: features,
        goal: defaultGoal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: fixedTime,
      );
      final recId = decision.recommendation.id;

      // 2. Accept Recommendation
      decisionService.acceptRecommendation(recId);
      final acceptEvents = store.getEvents(eventType: KineticEventType.recommendationAccepted);
      expect(acceptEvents.any((e) => e.payload['recommendationId'] == recId), isTrue);

      // 3. User Override (e.g. user felt extra energetic and decided to train harder)
      decisionService.overrideRecommendation(
        recommendationId: recId,
        overrideAction: 'train_hard',
        overrideReason: 'felt_well_rested_post_caffeine',
        notes: 'Felt strong after warm-up',
      );
      final overrideEvents = store.getEvents(eventType: KineticEventType.recommendationOverridden);
      expect(overrideEvents.any((e) => e.payload['overrideAction'] == 'train_hard'), isTrue);

      // 4. Record Real-World Outcome
      decisionService.recordOutcome(
        recommendationId: recId,
        userId: 'u_loop_test',
        performedAction: 'train_hard',
        actualSessionRPE: 8.5,
        actualVolumeLoadKg: 14000,
        nextDayRecoveryDelta: 2.0,
        performanceCategory: 'matched',
        timestamp: fixedTime.add(const Duration(hours: 3)),
      );

      expect(decisionService.getRecommendationTrace(recId), isNotNull);
    });
  });
}
