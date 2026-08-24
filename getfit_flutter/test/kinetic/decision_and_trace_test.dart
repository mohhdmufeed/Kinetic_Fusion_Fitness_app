import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/intelligence/feature_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/decision_engine.dart';
import 'package:kinetic_precision/kinetic/persistence/kinetic_store.dart';

void main() {
  group('SPEC 18, 19, 22, 23: Recommendation & Decision Engine with WHY Traces', () {
    const userId = 'user_decision_test';
    const goal = UserGoal(id: 'g1', userId: userId, type: GoalType.hypertrophy);

    final primedState = LatentPhysiologicalState(
      recoveryScore: 88.0,
      fatigueScore: 18.0,
      readinessScore: 89.0,
      adaptationScore: 85.0,
      energyScore: 88.0,
      direction: TrendDirection.improving,
      contributingFactors: ['hrv_positive_deviation', 'sleep_restored'],
      dataQualityScore: 1.0,
      timestamp: DateTime.utc(2026, 8, 18, 8, 0),
      modelVersion: 'v1.0',
    );

    final primedFeatures = const PhysiologicalFeatures(
      hrvZScore: 1.25,
      rhrDeltaBpm: -1.0,
      sleepDebtHours: 0.0,
      sleepQualityScore: 92.0,
      acuteTrainingLoad: 350.0,
      chronicTrainingLoad: 320.0,
      acwr: 1.09,
      activityStepsDelta: 1500.0,
      dataCompleteness: 1.0,
      rawFeatureMap: {},
    );

    test('1. Unified Recommendation Object has exact specified schema and status', () {
      final decision = KineticDecisionEngine.makeDecision(
        userId: userId,
        latentState: primedState,
        features: primedFeatures,
        goal: goal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: DateTime.utc(2026, 8, 18, 8, 0),
      );

      final rec = decision.recommendation;

      // Verify all required fields from SPEC.md Section 18
      expect(rec.id.isNotEmpty, isTrue);
      expect(rec.type, equals('training'));
      expect(rec.action, equals('train_hard'));
      expect(rec.priority, equals(1));
      expect(rec.headline.isNotEmpty, isTrue);
      expect(rec.rationale.isNotEmpty, isTrue);
      expect(rec.evidence.isNotEmpty, isTrue);
      expect(rec.status, equals('pending'));
      expect(rec.modelVersion, equals('recommendation_policy_v1'));
      expect(rec.createdAt, equals(DateTime.utc(2026, 8, 18, 8, 0)));
      expect(rec.expiresAt, equals(DateTime.utc(2026, 8, 19, 8, 0)));
    });

    test('2. Candidate Actions Evaluation: evaluates all 6 candidates (train_hard, train_normal, train_light, active_recovery, walk, rest)', () {
      final candidates = DefaultUtilityScorer().evaluateCandidates(
        latentState: primedState,
        features: primedFeatures,
        goal: goal,
        focus: TrainingFocus.hypertrophy,
      );

      // Verify all 6 candidate actions are evaluated
      final actionNames = candidates.map((c) => c.action).toList();
      expect(actionNames, contains('train_hard'));
      expect(actionNames, contains('train_normal'));
      expect(actionNames, contains('train_light'));
      expect(actionNames, contains('active_recovery'));
      expect(actionNames, contains('walk'));
      expect(actionNames, contains('rest'));

      // Highest utility is train_hard when primed
      expect(candidates.first.action, equals('train_hard'));
      expect(candidates.first.utilityScore, greaterThan(70.0));
    });

    test('3. Recommendation Trace generates queryable WHY audit trail', () {
      final decision = KineticDecisionEngine.makeDecision(
        userId: userId,
        latentState: primedState,
        features: primedFeatures,
        goal: goal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: DateTime.utc(2026, 8, 18, 8, 0),
      );

      final trace = decision.trace;

      // Verify queryable trace matching Section 23
      expect(trace.recommendationId, equals(decision.recommendation.id));
      expect(trace.modelVersion, equals('recommendation_policy_v1'));
      expect(trace.selectedDecision, equals('train_hard'));
      expect(trace.rawInputs['goalType'], equals('hypertrophy'));
      expect(trace.derivedFeatures['acwr'], equals(1.09));
      expect(trace.estimatedLatentState['readinessScore'], equals(89.0));
      expect(trace.candidateEvaluations.length, greaterThanOrEqualTo(6));
      expect(trace.reasonCodes.isNotEmpty, isTrue);

      // Query from KineticStore
      final storedTrace = KineticStore.instance.getTrace(trace.recommendationId);
      expect(storedTrace != null, isTrue);
      expect(storedTrace?.selectedDecision, equals('train_hard'));
    });

    test('4. Determinism Test (SPEC Section 36): Identical inputs + model version always produce bit-for-bit identical recommendations and traces', () {
      final timestamp = DateTime.utc(2026, 8, 18, 9, 0, 0);

      // Run decision engine multiple times with identical inputs
      final run1 = KineticDecisionEngine.makeDecision(
        userId: userId,
        latentState: primedState,
        features: primedFeatures,
        goal: goal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: timestamp,
      );

      final run2 = KineticDecisionEngine.makeDecision(
        userId: userId,
        latentState: primedState,
        features: primedFeatures,
        goal: goal,
        focus: TrainingFocus.hypertrophy,
        deterministicTimestamp: timestamp,
      );

      // Verify bit-for-bit identical recommendations
      expect(run1.recommendation.id, equals(run2.recommendation.id));
      expect(run1.recommendation.action, equals(run2.recommendation.action));
      expect(run1.recommendation.headline, equals(run2.recommendation.headline));
      expect(run1.recommendation.rationale, equals(run2.recommendation.rationale));
      expect(run1.recommendation.evidence, equals(run2.recommendation.evidence));
      expect(run1.recommendation.modelVersion, equals(run2.recommendation.modelVersion));

      // Verify bit-for-bit identical trace JSON
      expect(run1.trace.toJson(), equals(run2.trace.toJson()));
    });
  });
}
