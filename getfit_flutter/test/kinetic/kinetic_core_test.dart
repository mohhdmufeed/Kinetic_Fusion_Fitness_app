import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/kinetic_core.dart';

void main() {
  group('1. Mathematical & Time-Series Engine Tests', () {
    test('EWMA accurately smooths values with alpha decay', () {
      final values = [10.0, 20.0, 30.0, 40.0, 50.0];
      final ewma = TimeSeriesEngine.computeEWMA(values, alpha: 0.5);
      expect(ewma, greaterThan(35.0));
      expect(ewma, lessThan(50.0));
    });

    test('Mean, Median, and Variance calculate correctly', () {
      final values = [10.0, 20.0, 30.0, 40.0, 50.0];
      expect(TimeSeriesEngine.computeMean(values), equals(30.0));
      expect(TimeSeriesEngine.computeMedian(values), equals(30.0));
      expect(TimeSeriesEngine.computeStandardDeviation(values), closeTo(15.81, 0.05));
    });

    test('Trend slope accurately detects positive velocity', () {
      final risingValues = [10.0, 15.0, 20.0, 25.0, 30.0];
      final slope = TimeSeriesEngine.computeTrendSlope(risingValues);
      expect(slope, closeTo(5.0, 0.01));
    });

    test('Z-Score and IQR outlier filters remove spurious artifacts', () {
      final noisyValues = [50.0, 52.0, 51.0, 50.5, 500.0, 51.2]; // 500.0 is outlier
      final clean = TimeSeriesEngine.filterOutliersZScore(noisyValues, threshold: 2.0);
      expect(clean.contains(500.0), isFalse);
    });

    test('Training Load: ACWR computes acute vs chronic workload ratio', () {
      // 28 days of moderate load (100) with recent 7 days spiking (250)
      final dailyLoads = List<double>.filled(21, 100.0, growable: true)
        ..addAll(List<double>.filled(7, 250.0));
      final acwr = TrainingLoadEngine.computeACWR(dailyLoads);
      expect(acwr, greaterThan(1.3)); // Spiking acute load
    });
  });

  group('2. Personal Baseline & Latent State Engine Tests', () {
    test('PersonalBaseline adapts to history and calculates Z-score deviation', () {
      final history = [60.0, 62.0, 61.0, 63.0, 59.0, 60.5];
      final baseline = BaselineEngine.computeBaseline('rhr', history);

      expect(baseline.mean, closeTo(60.9, 0.2));
      // Observation of 70 bpm is elevated (> +2.0 std dev)
      final zScore = baseline.computeZScoreDeviation(70.0);
      expect(zScore, greaterThan(2.0));
    });

    test('StateEstimator computes balanced recovery and readiness from features', () {
      const features = PhysiologicalFeatures(
        hrvZScore: 1.2, // Elevated HRV (+1.2 sigma)
        rhrDeltaBpm: -3.0, // Suppressed RHR (-3 bpm)
        sleepDebtHours: 0.0, // Zero sleep debt
        sleepQualityScore: 92.0,
        acuteTrainingLoad: 120.0,
        chronicTrainingLoad: 140.0,
        acwr: 0.95, // Safe sweet spot
        activityStepsDelta: 500.0,
        dataCompleteness: 1.0,
        rawFeatureMap: {},
      );

      final estimator = KineticStateEstimator();
      final state = estimator.estimateState(features, {});

      expect(state.recoveryScore, greaterThan(80.0));
      expect(state.readinessScore, greaterThan(80.0));
      expect(state.direction, equals(TrendDirection.improving));
    });
  });

  group('3. Specialized Domain Engines Tests', () {
    test('RecoveryEngine generates structured recovery and confidence output', () {
      final state = LatentPhysiologicalState(
        recoveryScore: 88.0,
        fatigueScore: 22.0,
        readinessScore: 86.0,
        adaptationScore: 80.0,
        energyScore: 85.0,
        direction: TrendDirection.improving,
        contributingFactors: ['hrv_elevated', 'sleep_restored'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'test',
      );

      final output = KineticRecoveryEngine.evaluate(state);
      expect(output.statusCategory, equals('optimal'));
      expect(output.recommendedAction, equals('train_hard'));
      expect(output.confidence, greaterThan(0.9));
    });

    test('TrainingEngine autoregulates set load on RPE overshoot', () {
      const prescription = ExercisePrescription(
        exerciseId: 'ex_bench',
        exerciseName: 'Barbell Bench Press',
        targetSets: 3,
        targetReps: 8,
        targetLoadKg: 80.0,
        targetRPE: 8.0,
        reasonCode: 'target_progression',
      );

      // User logged 80kg x 6 @ RPE 9.5 (overshot RPE by +1.5 and missed 2 reps)
      final completedSet = ExerciseSet(
        setNumber: 1,
        exerciseId: 'ex_bench',
        prescribedLoadKg: 80.0,
        actualLoadKg: 80.0,
        prescribedReps: 8,
        actualReps: 6,
        targetRPE: 8.0,
        actualRPE: 9.5,
        timestamp: DateTime.now(),
      );

      final adjustment = KineticTrainingEngine.autoregulateNextSet(
        prescription: prescription,
        previousSet: completedSet,
        nextSetNumber: 2,
      );

      expect(adjustment.adjustedLoadKg, lessThan(80.0)); // Load reduced to 75.0kg
      expect(adjustment.reasonCode, equals('rpe_overshoot_fatigue_mitigation'));
    });

    test('ProgressionEngine recommends load increase when rep ceiling achieved', () {
      const exercise = Exercise(
        id: 'ex_squat',
        name: 'Back Squat',
        movementPattern: MovementPattern.squat,
        primaryMuscles: [MuscleGroup.quadriceps],
        isCompound: true,
      );

      final state = LatentPhysiologicalState(
        recoveryScore: 85.0,
        fatigueScore: 25.0,
        readinessScore: 85.0,
        adaptationScore: 80.0,
        energyScore: 85.0,
        direction: TrendDirection.improving,
        contributingFactors: [],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'test',
      );

      // 3 sets hitting the top of the rep range (10 reps @ RPE 8.0)
      final recentSets = [
        ExerciseSet(setNumber: 1, exerciseId: 'ex_squat', prescribedLoadKg: 100.0, actualLoadKg: 100.0, prescribedReps: 10, actualReps: 10, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 2, exerciseId: 'ex_squat', prescribedLoadKg: 100.0, actualLoadKg: 100.0, prescribedReps: 10, actualReps: 10, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 3, exerciseId: 'ex_squat', prescribedLoadKg: 100.0, actualLoadKg: 100.0, prescribedReps: 10, actualReps: 10, targetRPE: 8.0, actualRPE: 8.5, timestamp: DateTime.now()),
      ];

      final rec = KineticProgressionEngine.evaluateProgression(
        exercise: exercise,
        recentSets: recentSets,
        recoveryState: state,
        maxRepTarget: 10,
      );

      expect(rec.action, equals(RecommendationAction.increaseLoad));
      expect(rec.recommendedLoadKg, equals(102.5)); // +2.5kg compound jump
      expect(rec.primaryReasonCode, equals('double_progression_rep_ceiling_achieved'));
    });

    test('SleepEngine calculates personalized sleep target and bedtime window', () {
      final state = LatentPhysiologicalState(
        recoveryScore: 60.0,
        fatigueScore: 75.0, // High fatigue
        readinessScore: 60.0,
        adaptationScore: 65.0,
        energyScore: 60.0,
        direction: TrendDirection.declining,
        contributingFactors: [],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'test',
      );

      final sleepRec = KineticSleepEngine.calculateNeed(
        baselineSleepHours: 8.0,
        sleepDebtHours: 2.0, // 2h debt
        acuteTrainingLoad: 350.0, // Heavy training
        recoveryState: state,
      );

      // Baseline 8.0 + debt payment (0.66h) + load demand (0.5h) + fatigue (0.25h)
      expect(sleepRec.targetDurationHours, greaterThanOrEqualTo(9.0));
      expect(sleepRec.recommendedSleepWindow.isNotEmpty, isTrue);
    });

    test('NutritionEngine calculates calories and macronutrients by training demand', () {
      final user = KineticUser(
        id: 'u1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sex: 'male',
        age: 28,
        heightCm: 180,
        weightKg: 80.0,
      );

      const hypertrophyGoal = UserGoal(
        id: 'g1',
        userId: 'u1',
        type: GoalType.hypertrophy,
      );

      final nutrition = KineticNutritionEngine.calculateTargets(
        user: user,
        goal: hypertrophyGoal,
        todayTrainingLoad: 250.0,
        isTrainingDay: true,
      );

      expect(nutrition.energyKcal, greaterThan(2600));
      expect(nutrition.proteinGrams, equals(160.0)); // 2.0g/kg * 80kg
      expect(nutrition.carbGrams, greaterThan(250.0));
      expect(nutrition.hydrationLiters, greaterThan(3.0));
    });
  });

  group('4. Deterministic Simulation & Archetypes Tests', () {
    test('KineticSimulator produces reproducible deterministic history across all 5 archetypes', () {
      for (final archetype in UserArchetype.values) {
        final sim = KineticSimulator.generateHistory(
          archetype: archetype,
          days: 30,
          seed: 12345,
        );

        expect(sim.days, equals(30));
        expect(sim.measurements.isNotEmpty, isTrue);
        expect(sim.events.isNotEmpty, isTrue);
      }
    });

    test('User A (High Recovery Athlete) exhibits superior HRV and recovery trends', () {
      final simA = KineticSimulator.generateHistory(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 14,
        seed: 42,
      );
      final simB = KineticSimulator.generateHistory(
        archetype: UserArchetype.userB_HighFatiguePoorSleep,
        days: 14,
        seed: 42,
      );

      final avgHRV_A = TimeSeriesEngine.computeMean(
        simA.measurements.where((m) => m.metric == 'hrv_rmssd').map((m) => m.value).toList(),
      );
      final avgHRV_B = TimeSeriesEngine.computeMean(
        simB.measurements.where((m) => m.metric == 'hrv_rmssd').map((m) => m.value).toList(),
      );

      expect(avgHRV_A, greaterThan(avgHRV_B));
    });
  });

  group('5. Complete End-to-End Mechanics & Application Contract Loop', () {
    test('Full Loop: Seed -> Baseline -> State -> TodayViewModel -> Workout -> Autoregulation -> Complete -> WHY Trace', () async {
      final store = KineticStore.instance..reset();

      // 1. Create User & Goal
      final user = KineticUser(
        id: 'athlete_prime',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sex: 'male',
        age: 27,
        heightCm: 182,
        weightKg: 85.0,
      );
      store.saveUser(user);

      final goal = UserGoal(
        id: 'goal_prime',
        userId: user.id,
        type: GoalType.hypertrophy,
        priority: 1,
      );
      store.addGoal(goal);

      // 2. Import 30 days of simulation history
      final sim = KineticSimulator.generateHistory(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 30,
        seed: 999,
      );
      store.recordMeasurementsBatch(sim.measurements);

      // 3. Compute Baselines
      final hrvHistory = store.getMeasurements(metric: 'hrv_rmssd').map((m) => m.value).toList();
      final rhrHistory = store.getMeasurements(metric: 'rhr').map((m) => m.value).toList();
      final sleepHistory = store.getMeasurements(metric: 'sleep_duration_hrs').map((m) => m.value).toList();

      store.setBaseline(BaselineEngine.computeBaseline('hrv_rmssd', hrvHistory));
      store.setBaseline(BaselineEngine.computeBaseline('rhr', rhrHistory));
      store.setBaseline(BaselineEngine.computeBaseline('sleep_duration_hrs', sleepHistory));

      expect(store.getBaseline('hrv_rmssd'), isNotNull);

      // 4. Request TodayViewModel from TodayService
      final todayService = TodayService(store: store);
      final todayVM = await todayService.getToday();

      expect(todayVM.currentState.recoveryScore, greaterThan(0));
      expect(todayVM.primaryRecommendation.headline.isNotEmpty, isTrue);
      expect(todayVM.nutritionTarget.energyKcal, greaterThan(2000));
      expect(todayVM.sleepTarget.targetDurationHours, greaterThan(7.0));
      expect(todayVM.upcomingWorkout, isNotNull);

      // 5. Execute Workout Session via TrainingService
      final trainingService = TrainingService(store: store);
      final session = todayVM.upcomingWorkout!;
      var workoutVM = await trainingService.startSession(session);

      expect(workoutVM.session.status, equals('in_progress'));

      // Log Set 1: Exact target
      workoutVM = await trainingService.logSet(
        sessionId: session.id,
        exerciseId: session.prescriptions.first.exerciseId,
        actualLoadKg: session.prescriptions.first.targetLoadKg,
        actualReps: session.prescriptions.first.targetReps,
        actualRPE: 8.0,
      );

      expect(workoutVM.session.completedSets.length, equals(1));

      // Log Set 2: Overshoot RPE to trigger autoregulation
      workoutVM = await trainingService.logSet(
        sessionId: session.id,
        exerciseId: session.prescriptions.first.exerciseId,
        actualLoadKg: session.prescriptions.first.targetLoadKg,
        actualReps: 6,
        actualRPE: 9.5,
      );

      expect(workoutVM.lastAutoregulationReason, equals('rpe_overshoot_fatigue_mitigation'));

      // Complete Workout Session
      final completed = await trainingService.completeSession(session.id, finalAverageRPE: 8.5);
      expect(completed.status, equals('completed'));
      expect(completed.totalVolumeKg, greaterThan(0));

      // 6. Verify "WHY" Telemetry Service Trace
      final telemetry = TelemetryService(store: store);
      final whyVM = telemetry.explainRecommendation(todayVM.primaryRecommendation.id);

      expect(whyVM, isNotNull);
      expect(whyVM!.reasonCodes.isNotEmpty, isTrue);
      expect(whyVM.competingOptionsEvaluated.length, greaterThanOrEqualTo(6));
    });
  });
}
