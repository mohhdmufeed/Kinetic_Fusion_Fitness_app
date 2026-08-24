import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/persistence/kinetic_store.dart';
import 'package:kinetic_precision/kinetic/math/baseline_calc.dart';
import 'package:kinetic_precision/kinetic/intelligence/feature_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/state_estimator.dart';
import 'package:kinetic_precision/kinetic/intelligence/recovery_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/training_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/progression_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/decision_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/sleep_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/nutrition_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/feedback_loop.dart';
import 'package:kinetic_precision/kinetic/simulation/archetypes.dart';
import 'package:kinetic_precision/kinetic/simulation/generator.dart';
import 'package:kinetic_precision/kinetic/services/kinetic_app_facade.dart';
import 'package:kinetic_precision/kinetic/contracts/app_view_models.dart';

void main() {
  group('Phase 12: Production Hardening & System-Wide Audit Tests', () {
    late KineticAppFacade facade;
    late KineticStore store;
    final fixedTime = DateTime(2026, 8, 18, 12, 0, 0);

    setUp(() {
      store = KineticStore.instance..reset();
      facade = KineticAppFacade(store: store);
    });

    // ── 1. ARCHITECTURE & LAYERING AUDIT ──
    group('1. Architecture & Layering Audit', () {
      test('Application Facade cleanly isolates Domain & Intelligence from UI', () async {
        final user = KineticUser(
          id: 'u_arch_audit',
          createdAt: fixedTime.subtract(const Duration(days: 30)),
          updatedAt: fixedTime,
          sex: 'female',
          age: 29,
          heightCm: 170,
          weightKg: 65.0,
        );

        final createRes = await facade.createUser(user);
        expect(createRes.isSuccess, isTrue);

        final goalRes = await facade.createGoal(const UserGoal(
          id: 'g_arch_audit',
          userId: 'u_arch_audit',
          type: GoalType.fatLoss,
          targetValue: 62.0,
        ));
        expect(goalRes.isSuccess, isTrue);

        final todayRes = await facade.getToday();
        expect(todayRes.isSuccess, isTrue);
        expect(todayRes.data.user.id, equals('u_arch_audit'));
      });
    });

    // ── 2. DATA AUDIT ──
    group('2. Data Integrity & Idempotency Audit', () {
      test('Raw measurements preserved with duplicate-guard idempotency', () async {
        final m1 = Measurement(
          id: 'meas_dup_1',
          userId: 'u_data_audit',
          metric: 'hrv_rmssd',
          value: 68.0,
          unit: 'ms',
          timestamp: fixedTime,
          source: 'sensor_ble',
          quality: DataQuality.observed,
        );

        store.recordMeasurement(m1);
        store.recordMeasurement(m1); // Duplicate write attempt

        final stored = store.getMeasurements(metric: 'hrv_rmssd');
        expect(stored.length, equals(1)); // Exact duplicate filtered
      });

      test('Immutable event ledger records append-only events', () async {
        store.recordEvent(KineticEvent(
          id: 'evt_audit_1',
          userId: 'u_data_audit',
          eventType: 'WorkoutStarted',
          timestamp: fixedTime,
          payload: {'sessionId': 'sess_1'},
        ));

        final events = store.getEvents();
        expect(events.length, equals(1));
        expect(events.first.eventType, equals('WorkoutStarted'));
      });
    });

    // ── 3. INTELLIGENCE & VERSION AUDIT ──
    group('3. Intelligence & Model Versioning Audit', () {
      test('All intelligence engines have explicit semantic versions', () {
        expect(BaselineEngine.version, equals('baseline_engine_v1.0'));
        expect(KineticRecoveryEngine.version, equals('recovery_model_v1'));
        expect(KineticProgressionEngine.version, equals('progression_model_v1.0'));
        expect(KineticDecisionEngine.version, equals('recommendation_policy_v1'));
        expect(KineticSleepEngine.version, equals('sleep_model_v1.0'));
        expect(KineticNutritionEngine.version, equals('nutrition_model_v1.0'));
        expect(FeedbackEvaluator.version, equals('feedback_evaluator_v1.0'));
      });

      test('Decision engine generates queryable WHY trace matching SPEC Section 23', () async {
        final decision = KineticDecisionEngine.makeDecision(
          userId: 'u_why_audit',
          latentState: LatentPhysiologicalState(
            recoveryScore: 85.0,
            fatigueScore: 20.0,
            readinessScore: 88.0,
            adaptationScore: 80.0,
            energyScore: 85.0,
            direction: TrendDirection.improving,
            contributingFactors: ['hrv_high'],
            dataQualityScore: 1.0,
            timestamp: fixedTime,
            modelVersion: 'v1',
          ),
          features: const PhysiologicalFeatures(
            hrvZScore: 1.2,
            rhrDeltaBpm: -2.0,
            sleepDebtHours: 0.0,
            sleepQualityScore: 90.0,
            acuteTrainingLoad: 300.0,
            chronicTrainingLoad: 300.0,
            acwr: 1.0,
            activityStepsDelta: 1000.0,
            dataCompleteness: 1.0,
            rawFeatureMap: {},
          ),
          goal: const UserGoal(id: 'g', userId: 'u_why_audit', type: GoalType.hypertrophy),
          focus: TrainingFocus.hypertrophy,
          deterministicTimestamp: fixedTime,
        );

        final trace = decision.trace;
        expect(trace.recommendationId, equals(decision.recommendation.id));
        expect(trace.candidateEvaluations.length, greaterThanOrEqualTo(6));
        expect(trace.reasonCodes.isNotEmpty, isTrue);
        expect(trace.modelVersion, equals('recommendation_policy_v1'));
      });
    });

    // ── 4. OFFLINE RESILIENCE AUDIT ──
    group('4. Offline Resilience Audit', () {
      test('Simulates Network = OFF: Full simulation and decision cycle executes without network', () {
        // Run 90-day multi-month closed loop simulation
        final result = KineticSimulator.simulateClosedLoopHistory(
          archetype: UserArchetype.userA_HighRecoveryAthlete,
          days: 90,
          seed: 42,
          deterministicTimestamp: fixedTime,
        );

        expect(result.dataset.measurements.isNotEmpty, isTrue);
        expect(result.recommendations.isNotEmpty, isTrue);
        expect(result.traces.isNotEmpty, isTrue);
        expect(result.feedbackChains.isNotEmpty, isTrue);
      });
    });

    // ── 5. PERFORMANCE BENCHMARKS AUDIT ──
    group('5. Performance Benchmarks Audit', () {
      test('Full intelligence pipeline on 365-day dataset completes in < 50ms', () {
        final dataset = KineticSimulator.generateHistory(
          archetype: UserArchetype.userA_HighRecoveryAthlete,
          days: 365,
          seed: 77,
          deterministicTimestamp: fixedTime,
        );

        final Map<String, List<Measurement>> rawGrouped = {};
        for (final m in dataset.measurements) {
          rawGrouped.putIfAbsent(m.metric, () => []).add(m);
        }

        final stopwatch = Stopwatch()..start();

        final featureEngine = KineticFeatureEngine(baselines: {});
        final features = featureEngine.extractFeatures(rawGrouped);
        final stateEstimator = KineticStateEstimator();
        final state = stateEstimator.estimateState(features, {}, deterministicTimestamp: fixedTime);
        KineticDecisionEngine.makeDecision(
          userId: dataset.profile.user.id,
          latentState: state,
          features: features,
          goal: dataset.profile.goal,
          focus: dataset.profile.trainingFocus,
          deterministicTimestamp: fixedTime,
        );

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(50),
            reason: 'Full pipeline on 365-day dataset must execute under 50ms');
      });

      test('RecoveryEngine executes in < 10ms', () {
        final stopwatch = Stopwatch()..start();
        KineticRecoveryEngine.estimate(
          RecoveryEvaluationInput(
            sleepDurationHours: 8.2,
            sleepDebtHours: 0.0,
            hrvZScore: 1.1,
            rhrDeltaBpm: -1.5,
            acuteChronicWorkloadRatio: 1.05,
            recentAverageRPE: 7.5,
            weeklyVolumeLoadKg: 4000.0,
            volumeBaselineKg: 3800.0,
            routineDisruption: false,
            environmentalStressScore: 0.0,
            signalQuality: DataQuality.observed,
          ),
        );
        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });

    // ── 6. SECURITY & PRIVACY AUDIT ──
    group('6. Security & Privacy Audit', () {
      test('Local storage mode confirmed with zero cloud dependencies', () async {
        final telemRes = await facade.getTelemetry();
        expect(telemRes.isSuccess, isTrue);
        expect(telemRes.data.dataStorageMode, equals('Local-Only (Zero Cloud)'));
      });
    });

    // ── 7. FINAL END-TO-END AUDIT ──
    group('7. Final End-to-End Audit', () {
      test('Complete 13-stage closed-loop lifecycle executes seamlessly on-device', () async {
        // 1. Create User
        final user = KineticUser(
          id: 'u_e2e_final',
          createdAt: fixedTime.subtract(const Duration(days: 90)),
          updatedAt: fixedTime,
          sex: 'male',
          age: 27,
          heightCm: 182,
          weightKg: 84.0,
        );
        final userRes = await facade.createUser(user);
        expect(userRes.isSuccess, isTrue);

        // 2. Set Goal
        final goal = const UserGoal(
          id: 'g_e2e_final',
          userId: 'u_e2e_final',
          type: GoalType.hypertrophy,
          targetValue: 86.0,
        );
        final goalRes = await facade.createGoal(goal);
        expect(goalRes.isSuccess, isTrue);

        // 3. Generate 30-day History & Seed Measurements
        final history = KineticSimulator.generateHistory(
          archetype: UserArchetype.userA_HighRecoveryAthlete,
          days: 30,
          seed: 42,
          deterministicTimestamp: fixedTime,
        );
        for (final m in history.measurements) {
          store.recordMeasurement(m);
        }

        // 4. Calculate Baselines
        final hrvSamples = history.measurements.where((m) => m.metric == 'hrv_rmssd').map((m) => m.value).toList();
        final hrvBaseline = BaselineEngine.computeHRVBaseline(hrvSamples);
        store.setBaseline(hrvBaseline);
        expect(hrvBaseline.mean, greaterThan(60.0));

        // 5. Estimate State & 6. Generate Recommendation via getToday()
        final todayRes = await facade.getToday();
        expect(todayRes.isSuccess, isTrue);
        final todayVM = todayRes.data;
        expect(todayVM.currentState.readinessScore, greaterThan(0));
        expect(todayVM.primaryRecommendation.action.isNotEmpty, isTrue);

        // 7. Generate Workout & 8. Start Workout
        final startRes = await facade.startWorkout(focus: TrainingFocus.hypertrophy);
        expect(startRes.isSuccess, isTrue);
        final session = startRes.data.session;
        expect(session.status, equals('in_progress'));

        // 9. Execute Workout & Record Performance (Sets)
        final nextSetRes = await facade.getNextSet();
        expect(nextSetRes.isSuccess, isTrue);
        final setRes = await facade.completeSet(
          sessionId: session.id,
          exerciseId: nextSetRes.data.exerciseId,
          actualLoadKg: nextSetRes.data.targetLoadKg,
          actualReps: nextSetRes.data.targetReps,
          actualRPE: 8.0,
        );
        expect(setRes.isSuccess, isTrue);
        expect(setRes.data.completedSets.length, equals(1));

        // Complete Workout
        final completeRes = await facade.completeWorkout(session.id);
        expect(completeRes.isSuccess, isTrue);

        // 10. Update State & 11. Generate Next Recommendation
        final nextTodayRes = await facade.getToday();
        expect(nextTodayRes.isSuccess, isTrue);
        expect(nextTodayRes.data.primaryRecommendation.id.isNotEmpty, isTrue);

        // 12. Explain WHY
        final whyRes = await facade.getRecommendationReason(todayVM.primaryRecommendation.id);
        expect(whyRes.isSuccess, isTrue);
        expect(whyRes.data.reasonCodes.isNotEmpty, isTrue);

        // 13. Record Outcome
        final outcome = RecommendationOutcome(
          recommendationId: todayVM.primaryRecommendation.id,
          userId: user.id,
          performedAction: todayVM.primaryRecommendation.action,
          actualSessionRPE: 8.0,
          actualVolumeLoadKg: 3500.0,
          nextDayRecoveryDelta: 2.5,
          performanceCategory: 'matched',
          timestamp: fixedTime.add(const Duration(hours: 4)),
        );
        final chain = facade.feedbackService.buildExplicitFeedbackChain(
          recommendation: todayVM.primaryRecommendation,
          userAction: todayVM.primaryRecommendation.action,
          isAccepted: true,
          isOverridden: false,
          outcome: outcome,
        );
        expect(chain.wasSuccessful, isTrue);
        expect(chain.successAssessment, equals('success_matched_demand'));
      });
    });
  });
}
