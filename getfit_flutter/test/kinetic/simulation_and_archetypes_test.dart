import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/math/time_series.dart';
import 'package:kinetic_precision/kinetic/math/baseline_calc.dart';
import 'package:kinetic_precision/kinetic/simulation/archetypes.dart';
import 'package:kinetic_precision/kinetic/simulation/generator.dart';
import 'package:kinetic_precision/kinetic/intelligence/recovery_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/training_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/progression_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/sleep_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/nutrition_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/feature_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/decision_engine.dart';

void main() {
  group('SPEC 26-27: Synthetic Archetypes & Deterministic Simulator Fixtures', () {
    test('1. Generates 30, 90, 180, and 365-day timelines across all 5 archetypes', () {
      final durations = [30, 90, 180, 365];

      for (final archetype in UserArchetype.values) {
        for (final days in durations) {
          final dataset = KineticSimulator.generateHistory(
            archetype: archetype,
            days: days,
            seed: 42,
          );

          expect(dataset.days, equals(days));
          expect(dataset.measurements.isNotEmpty, isTrue);
          expect(dataset.events.isNotEmpty, isTrue);

          // Full year has thousands of structured observations
          if (days == 365) {
            expect(dataset.measurements.length, greaterThan(1000));
          }
        }
      }
    });

    test('2. Determinism Test: Identical seed produces bit-for-bit identical simulation history', () {
      final run1 = KineticSimulator.generateHistory(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 90,
        seed: 777,
      );
      final run2 = KineticSimulator.generateHistory(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 90,
        seed: 777,
      );

      expect(run1.measurements.length, equals(run2.measurements.length));
      expect(run1.events.length, equals(run2.events.length));
      expect(run1.sessions.length, equals(run2.sessions.length));

      for (int i = 0; i < run1.measurements.length; i++) {
        expect(run1.measurements[i].id, equals(run2.measurements[i].id));
        expect(run1.measurements[i].value, equals(run2.measurements[i].value));
        expect(run1.measurements[i].metric, equals(run2.measurements[i].metric));
      }
    });

    test('3. Archetype Separation: User A (High Recovery) vs User B (High Fatigue) distinct physiological profiles', () {
      final simA = KineticSimulator.generateHistory(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 90,
        seed: 42,
      );
      final simB = KineticSimulator.generateHistory(
        archetype: UserArchetype.userB_HighFatiguePoorSleep,
        days: 90,
        seed: 42,
      );

      final meanHrvA = TimeSeriesEngine.computeMean(
        simA.measurements.where((m) => m.metric == 'hrv_rmssd').map((m) => m.value).toList(),
      );
      final meanHrvB = TimeSeriesEngine.computeMean(
        simB.measurements.where((m) => m.metric == 'hrv_rmssd').map((m) => m.value).toList(),
      );

      final meanRhrA = TimeSeriesEngine.computeMean(
        simA.measurements.where((m) => m.metric == 'rhr').map((m) => m.value).toList(),
      );
      final meanRhrB = TimeSeriesEngine.computeMean(
        simB.measurements.where((m) => m.metric == 'rhr').map((m) => m.value).toList(),
      );

      expect(meanHrvA, greaterThan(meanHrvB)); // Alex HRV (~78ms) >> Jordan HRV (~38ms)
      expect(meanRhrA, lessThan(meanRhrB));   // Alex RHR (~50bpm) << Jordan RHR (~70bpm)
    });

    test('4. User C (Weight Loss Goal): Shows steady negative weight slope over 180 days', () {
      final simC = KineticSimulator.generateHistory(
        archetype: UserArchetype.userC_WeightLossGoal,
        days: 180,
        seed: 42,
      );

      final weightValues = simC.measurements
          .where((m) => m.metric == 'weight_kg')
          .map((m) => m.value)
          .toList();

      expect(weightValues.length, greaterThan(30));
      // First recorded weight should be higher than last recorded weight
      expect(weightValues.first, greaterThan(weightValues.last));
      final trend = TimeSeriesEngine.computeTrendSlope(weightValues);
      expect(trend, lessThan(0.0)); // Negative slope demonstrating fat loss
    });

    test('5. User D (Strength Peaking): Demonstrates high load resistance training sessions', () {
      final simD = KineticSimulator.generateHistory(
        archetype: UserArchetype.userD_StrengthFocusedAthlete,
        days: 90,
        seed: 42,
      );

      expect(simD.sessions.isNotEmpty, isTrue);
      final firstSession = simD.sessions.first;
      expect(firstSession.prescriptions.first.targetLoadKg, greaterThanOrEqualTo(120.0));
      expect(firstSession.prescriptions.first.targetReps, lessThanOrEqualTo(5)); // Low rep strength
    });

    test('6. User E (Sparse Data): Time-Series Outlier & Imputation algorithms handle missing observations safely', () {
      final simE = KineticSimulator.generateHistory(
        archetype: UserArchetype.userE_SparseNoisyData,
        days: 90,
        seed: 42,
      );

      final hrvValues = simE.measurements
          .where((m) => m.metric == 'hrv_rmssd')
          .map((m) => m.value)
          .toList();

      // Ensure robust statistics calculate without errors on sparse / noisy series
      expect(hrvValues.isNotEmpty, isTrue);
      final baseline = BaselineEngine.computeBaseline('hrv_rmssd', hrvValues);
      expect(baseline.mean, greaterThan(20.0));
      expect(baseline.stdDev, greaterThan(0.0));
    });
  });

  group('SPEC Verification: All Core Engines Evaluated Against Synthetic Archetype Fixtures', () {
    final simA = KineticSimulator.generateHistory(archetype: UserArchetype.userA_HighRecoveryAthlete, days: 90, seed: 101);
    final simB = KineticSimulator.generateHistory(archetype: UserArchetype.userB_HighFatiguePoorSleep, days: 90, seed: 101);
    final simC = KineticSimulator.generateHistory(archetype: UserArchetype.userC_WeightLossGoal, days: 90, seed: 101);
    final simD = KineticSimulator.generateHistory(archetype: UserArchetype.userD_StrengthFocusedAthlete, days: 90, seed: 101);

    test('Engine 1: RecoveryEngine against User A vs User B', () {
      final recoveryA = KineticRecoveryEngine.estimate(const RecoveryEvaluationInput(
        sleepDurationHours: 8.5,
        sleepDebtHours: 0.0,
        hrvZScore: 1.3,
        rhrDeltaBpm: -1.0,
        acuteChronicWorkloadRatio: 1.05,
        recentAverageRPE: 7.5,
        weeklyVolumeLoadKg: 12000,
        volumeBaselineKg: 11500,
        routineDisruption: false,
        environmentalStressScore: 0.0,
        signalQuality: DataQuality.observed,
      ));

      expect(recoveryA.recoveryScore, greaterThan(75.0));
      expect(recoveryA.recommendedAction, equals('train_hard'));

      final recoveryB = KineticRecoveryEngine.estimate(const RecoveryEvaluationInput(
        sleepDurationHours: 5.5,
        sleepDebtHours: 3.5,
        hrvZScore: -1.5,
        rhrDeltaBpm: 5.0,
        acuteChronicWorkloadRatio: 1.65, // Overreaching spike
        recentAverageRPE: 9.0,
        weeklyVolumeLoadKg: 16000,
        volumeBaselineKg: 10000,
        routineDisruption: true,
        environmentalStressScore: 0.2,
        signalQuality: DataQuality.observed,
      ));

      expect(recoveryB.recoveryScore, lessThan(55.0));
      expect(recoveryB.recommendedAction, isIn(['rest', 'active_recovery', 'train_light']));
    });

    test('Engine 2: Training & Progression Engine against User D (Strength Peaking)', () {
      final session = simD.sessions.last;
      const squatExercise = Exercise(
        id: 'ex_squat_heavy',
        name: 'Heavy Barbell Squat',
        movementPattern: MovementPattern.squat,
        primaryMuscles: [MuscleGroup.quadriceps],
        isCompound: true,
      );

      final recovery = LatentPhysiologicalState(
        recoveryScore: 82.0,
        fatigueScore: 25.0,
        readinessScore: 84.0,
        adaptationScore: 80.0,
        energyScore: 82.0,
        direction: TrendDirection.improving,
        contributingFactors: ['primed'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'v1',
      );

      final progression = KineticProgressionEngine.evaluateProgression(
        exercise: squatExercise,
        recentSets: session.completedSets,
        recoveryState: recovery,
        minRepTarget: 3,
        maxRepTarget: 5,
      );

      expect(progression.decision.isNotEmpty, isTrue);
      expect(progression.recommendedLoadKg, greaterThanOrEqualTo(80.0));
    });

    test('Engine 3: Sleep Engine against User B (High Sleep Debt)', () {
      final stateB = LatentPhysiologicalState(
        recoveryScore: 45.0,
        fatigueScore: 75.0,
        readinessScore: 48.0,
        adaptationScore: 50.0,
        energyScore: 45.0,
        direction: TrendDirection.declining,
        contributingFactors: ['sleep_debt'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'v1',
      );

      final sleepTarget = KineticSleepEngine.calculateNeed(
        baselineSleepHours: simB.profile.targetSleepHours,
        sleepDebtHours: 3.5,
        acuteTrainingLoad: 450.0,
        recoveryState: stateB,
      );

      expect(sleepTarget.recommendedSleepDuration, greaterThan(simB.profile.targetSleepHours));
      expect(sleepTarget.contributingFactors, contains('high_training_volume_demand'));
    });

    test('Engine 4: Nutrition Engine against User C (Weight Loss Deficit)', () {
      final target = KineticNutritionEngine.calculateTargets(
        user: simC.profile.user,
        goal: simC.profile.goal,
        todayTrainingLoad: 200.0,
        isTrainingDay: true,
        dailySteps: 14000,
        weightTrendSlopeKgPerWeek: -0.45,
      );

      expect(target.primaryGoalReason, equals('caloric_deficit_fat_loss_preservation'));
      expect(target.proteinGrams, equals(202.0)); // 92kg * 2.2g/kg
      expect(target.strategyVersion, equals('nutrition_calc_v1'));
    });

    test('Engine 5: Decision Engine & WHY Trace against User A Profile', () {
      final stateA = LatentPhysiologicalState(
        recoveryScore: 88.0,
        fatigueScore: 18.0,
        readinessScore: 90.0,
        adaptationScore: 85.0,
        energyScore: 88.0,
        direction: TrendDirection.improving,
        contributingFactors: ['restored'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'v1',
      );

      final decision = KineticDecisionEngine.makeDecision(
        userId: simA.profile.user.id,
        latentState: stateA,
        features: const PhysiologicalFeatures(
          hrvZScore: 1.1,
          rhrDeltaBpm: -2.0,
          sleepDebtHours: 0.0,
          sleepQualityScore: 90.0,
          acuteTrainingLoad: 280.0,
          chronicTrainingLoad: 270.0,
          acwr: 1.04,
          activityStepsDelta: 1000.0,
          dataCompleteness: 1.0,
          rawFeatureMap: {},
        ),
        goal: simA.profile.goal,
        focus: simA.profile.trainingFocus,
      );

      expect(decision.recommendation.action, equals('train_hard'));
      expect(decision.trace.selectedDecision, equals('train_hard'));
      expect(decision.trace.modelVersion, equals('recommendation_policy_v1'));
    });
  });
}
