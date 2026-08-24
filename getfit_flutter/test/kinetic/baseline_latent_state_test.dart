import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/kinetic_core.dart';

void main() {
  group('Phase 4: Personal Baselines & Latent State Engine Tests', () {
    test('1. Adaptive Baselines across all 9 Metrics', () {
      // 1. RHR
      final rhrBaseline = BaselineEngine.computeRHRBaseline([56.0, 58.0, 57.0, 55.0, 56.0]);
      expect(rhrBaseline.metric, equals('rhr'));
      expect(rhrBaseline.mean, closeTo(56.4, 0.1));

      // 2. HRV
      final hrvBaseline = BaselineEngine.computeHRVBaseline([65.0, 70.0, 68.0, 72.0, 69.0]);
      expect(hrvBaseline.metric, equals('hrv_rmssd'));
      expect(hrvBaseline.mean, closeTo(68.8, 0.1));

      // 3. Sleep
      final sleepBaseline = BaselineEngine.computeSleepBaseline([7.5, 8.0, 7.8, 8.2, 7.9]);
      expect(sleepBaseline.metric, equals('sleep_duration_hrs'));
      expect(sleepBaseline.mean, closeTo(7.88, 0.1));

      // 4. Activity
      final actBaseline = BaselineEngine.computeActivityBaseline([8500, 10200, 9300, 11000]);
      expect(actBaseline.metric, equals('steps'));
      expect(actBaseline.mean, closeTo(9750.0, 1.0));

      // 5. Volume
      final volBaseline = BaselineEngine.computeVolumeBaseline([240.0, 310.0, 280.0, 350.0]);
      expect(volBaseline.metric, equals('session_load'));
      expect(volBaseline.mean, closeTo(295.0, 1.0));

      // 6. RPE
      final rpeBaseline = BaselineEngine.computeRPEBaseline([7.5, 8.0, 8.5, 7.0]);
      expect(rpeBaseline.metric, equals('set_rpe'));
      expect(rpeBaseline.mean, closeTo(7.75, 0.1));

      // 7. Weight
      final wtBaseline = BaselineEngine.computeWeightBaseline([76.5, 76.3, 76.4, 76.2]);
      expect(wtBaseline.metric, equals('weight_kg'));
      expect(wtBaseline.mean, closeTo(76.35, 0.1));

      // 8. Performance (Estimated 1RM)
      final perfBaseline = BaselineEngine.computePerformanceBaseline('bench_press', [100.0, 102.5, 105.0]);
      expect(perfBaseline.metric, equals('1rm_bench_press'));
      expect(perfBaseline.mean, closeTo(102.5, 0.1));

      // 9. Active HR
      final hrBaseline = BaselineEngine.computeHeartRateBaseline([135.0, 142.0, 138.0, 145.0]);
      expect(hrBaseline.metric, equals('heart_rate'));
      expect(hrBaseline.mean, closeTo(140.0, 0.1));
    });

    test('2. Baseline Adaptation Over Time: Continuous update step avoids frozen onboarding state', () {
      // User starts with baseline RHR = 65 bpm
      var baseline = PersonalBaseline(
        metric: 'rhr',
        mean: 65.0,
        stdDev: 3.0,
        min: 60.0,
        max: 70.0,
        sampleCount: 14,
        lastCalculated: DateTime.utc(2026, 8, 1),
      );

      // As cardiovascular fitness improves, incoming daily readings are ~55 bpm over 30 days
      for (int i = 0; i < 30; i++) {
        baseline = BaselineEngine.updateBaselineOnline(baseline, 55.0, adaptationRate: 0.1);
      }

      // Baseline should have adaptively shifted downwards towards 55 bpm (not frozen at 65 bpm)
      expect(baseline.mean, lessThan(56.0));
      expect(baseline.sampleCount, equals(44));
    });

    test('3. Baseline Service API: getBaseline, getBaselineDeviation, getBaselineTrend', () {
      final store = KineticStore.instance..reset();
      final now = DateTime.utc(2026, 8, 18, 12, 0);

      // Save initial baseline
      store.saveBaseline(PersonalBaseline(
        metric: 'hrv_rmssd',
        mean: 60.0,
        stdDev: 5.0,
        min: 45.0,
        max: 75.0,
        sampleCount: 28,
        lastCalculated: now,
      ));

      // Add measurements to store for trend analysis
      for (int i = 0; i < 10; i++) {
        store.recordMeasurement(Measurement(
          id: 'hrv_$i',
          userId: 'u1',
          metric: 'hrv_rmssd',
          value: 60.0 + (i * 1.5), // Upward progression
          unit: 'ms',
          timestamp: now.subtract(Duration(days: 10 - i)),
          source: 'sensor',
        ));
      }

      final service = BaselineService(store: store);

      // 1. getBaseline
      final baseResult = service.getBaseline('u1', 'hrv_rmssd');
      expect(baseResult.mean, equals(60.0));
      expect(baseResult.confidence, equals(1.0));
      expect(baseResult.calculationVersion, equals('baseline_service_v1.0'));

      // 2. getBaselineDeviation
      // Current reading = 70.0 -> delta = +10.0, zScore = (70 - 60) / 5 = +2.0, pctDev = +16.7%
      final devResult = service.getBaselineDeviation('u1', 'hrv_rmssd', 70.0);
      expect(devResult.delta, equals(10.0));
      expect(devResult.zScore, equals(2.0));
      expect(devResult.status, equals('elevated'));
      expect(devResult.direction, equals(TrendDirection.improving));

      // 3. getBaselineTrend
      final trendResult = service.getBaselineTrend('u1', 'hrv_rmssd');
      expect(trendResult.slope, greaterThan(0.0));
      expect(trendResult.direction, equals(TrendDirection.improving));
    });

    test('4. Latent State Estimator: Normal well-recovered user scenario', () {
      final estimator = KineticStateEstimator();

      // Normal optimal features: high HRV, low RHR, zero sleep debt, balanced ACWR
      const features = PhysiologicalFeatures(
        hrvZScore: 1.2,
        rhrDeltaBpm: -2.5,
        sleepDebtHours: -0.5,
        sleepQualityScore: 92.0,
        acuteTrainingLoad: 250.0,
        chronicTrainingLoad: 240.0,
        acwr: 1.04,
        activityStepsDelta: 1200.0,
        dataCompleteness: 1.0,
        rawFeatureMap: {},
      );

      final composite = estimator.estimateCompositeState(
        features,
        userId: 'user_optimal',
        deterministicTimestamp: DateTime.utc(2026, 8, 18, 12, 0),
      );

      // Check all 6 latent state models
      expect(composite.recovery.level, equals(RecoveryLevel.optimal));
      expect(composite.recovery.score, greaterThanOrEqualTo(80.0));
      expect(composite.recovery.contributingFactors, contains('hrv_elevated_above_baseline'));

      expect(composite.fatigue.level, equals(FatigueLevel.low));
      expect(composite.fatigue.score, lessThan(30.0));

      expect(composite.adaptation.level, equals(AdaptationLevel.peaking));

      expect(composite.energy.level, equals(EnergyLevel.high));
      expect(composite.energy.score, greaterThanOrEqualTo(80.0));

      expect(composite.performance.level, equals(PerformanceLevel.peak));

      expect(composite.readiness.level, equals(ReadinessLevel.train_hard));
      expect(composite.readiness.compositeScore, greaterThanOrEqualTo(78.0));
    });

    test('5. Latent State Estimator: Severe fatigue and acute workload spike scenario', () {
      final estimator = KineticStateEstimator();

      // Exhausted features: suppressed HRV, elevated RHR, 4 hours sleep debt, acute spike ACWR = 1.95
      const exhaustedFeatures = PhysiologicalFeatures(
        hrvZScore: -1.8,
        rhrDeltaBpm: 6.0,
        sleepDebtHours: 4.0,
        sleepQualityScore: 40.0,
        acuteTrainingLoad: 550.0,
        chronicTrainingLoad: 280.0,
        acwr: 1.96,
        activityStepsDelta: -3000.0,
        dataCompleteness: 0.9,
        rawFeatureMap: {},
      );

      final composite = estimator.estimateCompositeState(
        exhaustedFeatures,
        userId: 'user_exhausted',
        deterministicTimestamp: DateTime.utc(2026, 8, 18, 12, 0),
      );

      // Check compromised state
      expect(composite.recovery.level, equals(RecoveryLevel.exhausted));
      expect(composite.recovery.score, lessThan(40.0));
      expect(composite.recovery.contributingFactors, contains('hrv_suppressed'));
      expect(composite.recovery.contributingFactors, contains('resting_hr_elevated'));
      expect(composite.recovery.contributingFactors, contains('sleep_debt_accumulated'));

      expect(composite.fatigue.level, equals(FatigueLevel.high));
      expect(composite.fatigue.score, greaterThan(60.0));
      expect(composite.fatigue.contributingFactors, contains('acute_workload_spike'));

      expect(composite.adaptation.level, equals(AdaptationLevel.overreaching));

      expect(composite.energy.level, equals(EnergyLevel.depleted));

      expect(composite.readiness.level, equals(ReadinessLevel.rest));
      expect(composite.readiness.direction, equals(TrendDirection.declining));
    });

    test('6. Latent State Estimator: Sparse / missing data scenario degrades confidence gracefully', () {
      final estimator = KineticStateEstimator();

      // Incomplete data: only 1 metric present
      const sparseFeatures = PhysiologicalFeatures(
        hrvZScore: 0.0,
        rhrDeltaBpm: 0.0,
        sleepDebtHours: 0.0,
        sleepQualityScore: 70.0,
        acuteTrainingLoad: 100.0,
        chronicTrainingLoad: 100.0,
        acwr: 1.0,
        activityStepsDelta: 0.0,
        dataCompleteness: 0.2, // 20% data completeness
        rawFeatureMap: {},
      );

      final composite = estimator.estimateCompositeState(
        sparseFeatures,
        userId: 'user_sparse',
        deterministicTimestamp: DateTime.utc(2026, 8, 18, 12, 0),
      );

      expect(composite.recovery.confidence, equals(0.2));
      expect(composite.recovery.dataQuality, equals(DataQuality.estimated));
      expect(composite.readiness.confidence, equals(0.2));
    });

    test('7. Determinism: Identical inputs produce bit-for-bit identical CompositeLatentState', () {
      final estimator = KineticStateEstimator();
      final now = DateTime.utc(2026, 8, 18, 12, 0);

      const features = PhysiologicalFeatures(
        hrvZScore: 0.65,
        rhrDeltaBpm: -1.2,
        sleepDebtHours: 0.2,
        sleepQualityScore: 84.0,
        acuteTrainingLoad: 210.0,
        chronicTrainingLoad: 195.0,
        acwr: 1.08,
        activityStepsDelta: 500.0,
        dataCompleteness: 0.95,
        rawFeatureMap: {},
      );

      final stateA = estimator.estimateCompositeState(features, userId: 'u1', deterministicTimestamp: now);
      final stateB = estimator.estimateCompositeState(features, userId: 'u1', deterministicTimestamp: now);

      expect(stateA.recovery.score, equals(stateB.recovery.score));
      expect(stateA.recovery.level, equals(stateB.recovery.level));
      expect(stateA.fatigue.score, equals(stateB.fatigue.score));
      expect(stateA.fatigue.level, equals(stateB.fatigue.level));
      expect(stateA.adaptation.level, equals(stateB.adaptation.level));
      expect(stateA.energy.level, equals(stateB.energy.level));
      expect(stateA.performance.level, equals(stateB.performance.level));
      expect(stateA.readiness.level, equals(stateB.readiness.level));
      expect(stateA.readiness.compositeScore, equals(stateB.readiness.compositeScore));
      expect(stateA.toJson(), equals(stateB.toJson()));
    });
  });
}
