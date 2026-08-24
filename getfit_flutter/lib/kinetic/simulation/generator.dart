import 'dart:math';
import '../domain/models.dart';
import '../math/baseline_calc.dart';
import '../intelligence/feature_engine.dart';
import '../intelligence/state_estimator.dart';
import '../intelligence/decision_engine.dart';
import '../intelligence/feedback_loop.dart';
import 'archetypes.dart';

/// Dataset containing simulated time-series observations, events, and workouts
class SimulationDataset {
  final ArchetypeProfile profile;
  final int days;
  final List<Measurement> measurements;
  final List<KineticEvent> events;
  final List<WorkoutSession> sessions;

  const SimulationDataset({
    required this.profile,
    required this.days,
    required this.measurements,
    required this.events,
    required this.sessions,
  });

  /// Total count of all generated records
  int get totalRecordsCount => measurements.length + events.length + sessions.length;
}

/// Result of running the full closed-loop simulation over multi-day timelines
class ClosedLoopSimulationResult {
  final SimulationDataset dataset;
  final List<Recommendation> recommendations;
  final List<RecommendationTrace> traces;
  final List<RecommendationFeedbackChain> feedbackChains;
  final Map<String, PersonalBaseline> baselines;
  final LatentPhysiologicalState finalState;
  final int overrideCount;
  final double successRate;

  const ClosedLoopSimulationResult({
    required this.dataset,
    required this.recommendations,
    required this.traces,
    required this.feedbackChains,
    required this.baselines,
    required this.finalState,
    required this.overrideCount,
    required this.successRate,
  });
}

/// Deterministic Synthetic Data Simulator (SPEC.md Sections 26 & 27)
class KineticSimulator {
  /// Generates realistic synthetic time-series history for a specified archetype over [days]
  /// Supported standard timeline durations: 30, 90, 180, 365 days.
  /// [seed] ensures 100% deterministic, reproducible test fixtures.
  static SimulationDataset generateHistory({
    required UserArchetype archetype,
    int days = 90,
    int seed = 42,
    DateTime? deterministicTimestamp,
  }) {
    final profile = SyntheticArchetypes.getProfile(archetype);
    final rand = Random(seed);
    final now = deterministicTimestamp ?? DateTime(2026, 8, 18, 12, 0, 0);

    final List<Measurement> measurements = [];
    final List<KineticEvent> events = [];
    final List<WorkoutSession> sessions = [];

    final isSparse = archetype == UserArchetype.userE_SparseNoisyData;
    final isWeightLoss = archetype == UserArchetype.userC_WeightLossGoal;
    final isStrength = archetype == UserArchetype.userD_StrengthFocusedAthlete;

    // Running physiological state trackers
    double currentWeight = profile.initialWeightKg;
    final weightLossPerDay = (profile.initialWeightKg - profile.targetWeightKg) / (days > 0 ? days : 1);

    for (int d = days; d >= 0; d--) {
      final date = now.subtract(Duration(days: d));

      // Skip random days for sparse user (User E: ~30% dropout rate)
      if (isSparse && rand.nextDouble() < 0.30) {
        continue;
      }

      // 1. Sleep Duration (with circadian variance)
      final sleepNoise = (rand.nextDouble() * 1.6) - 0.8;
      final sleepDuration = (profile.targetSleepHours + sleepNoise).clamp(4.0, 11.0);
      measurements.add(Measurement(
        id: 'sleep_${d}_${profile.user.id}',
        userId: profile.user.id,
        metric: 'sleep_duration_hrs',
        value: double.parse(sleepDuration.toStringAsFixed(2)),
        unit: 'hours',
        timestamp: date.copyWith(hour: 7, minute: 0),
        source: 'synthetic_sim',
        quality: DataQuality.observed,
        metadata: {'bedtime': date.subtract(Duration(hours: sleepDuration.round())).toIso8601String()},
      ));
      events.add(KineticEvent(
        id: 'evt_sleep_${d}_${profile.user.id}',
        userId: profile.user.id,
        eventType: 'SleepRecorded',
        timestamp: date.copyWith(hour: 7, minute: 0),
        payload: {'duration_hours': sleepDuration},
      ));

      // 2. Morning HRV (rMSSD in ms)
      final hrvNoise = (rand.nextDouble() * 14.0) - 7.0;
      final hrvValue = (profile.meanHRV + hrvNoise).clamp(18.0, 130.0);
      measurements.add(Measurement(
        id: 'hrv_${d}_${profile.user.id}',
        userId: profile.user.id,
        metric: 'hrv_rmssd',
        value: double.parse(hrvValue.toStringAsFixed(1)),
        unit: 'ms',
        timestamp: date.copyWith(hour: 7, minute: 15),
        source: 'sensor_ble',
        quality: DataQuality.observed,
      ));

      // 3. Morning Resting Heart Rate (bpm)
      final rhrNoise = (rand.nextDouble() * 6.0) - 3.0;
      final rhrValue = (profile.meanRHR + rhrNoise).clamp(40.0, 95.0);
      measurements.add(Measurement(
        id: 'rhr_${d}_${profile.user.id}',
        userId: profile.user.id,
        metric: 'rhr',
        value: double.parse(rhrValue.toStringAsFixed(1)),
        unit: 'bpm',
        timestamp: date.copyWith(hour: 7, minute: 15),
        source: 'sensor_ble',
        quality: DataQuality.observed,
      ));

      // 4. Daily Bodyweight (Logged every 1-3 days, with water weight fluctuation)
      if (d % (isSparse ? 4 : 2) == 0) {
        if (isWeightLoss) {
          currentWeight -= weightLossPerDay * (isSparse ? 4 : 2);
        }
        final weightNoise = (rand.nextDouble() * 0.8) - 0.4;
        final loggedWeight = (currentWeight + weightNoise).clamp(45.0, 150.0);
        measurements.add(Measurement(
          id: 'weight_${d}_${profile.user.id}',
          userId: profile.user.id,
          metric: 'weight_kg',
          value: double.parse(loggedWeight.toStringAsFixed(2)),
          unit: 'kg',
          timestamp: date.copyWith(hour: 7, minute: 30),
          source: 'smart_scale',
          quality: DataQuality.observed,
        ));
      }

      // 5. Daily Steps
      final stepsNoise = (rand.nextDouble() * 3000.0) - 1500.0;
      final stepsValue = (profile.dailyStepsMean + stepsNoise).clamp(1500.0, 35000.0);
      measurements.add(Measurement(
        id: 'steps_${d}_${profile.user.id}',
        userId: profile.user.id,
        metric: 'steps',
        value: stepsValue.roundToDouble(),
        unit: 'steps',
        timestamp: date.copyWith(hour: 22, minute: 0),
        source: 'sensor_pedometer',
        quality: DataQuality.observed,
      ));

      // 6. Workout Session Execution
      final isWorkoutDay = rand.nextDouble() < (profile.weeklyWorkoutFrequency / 7.0);
      if (isWorkoutDay) {
        final loadMultiplier = isStrength ? 1.25 : 1.0;
        final load = (150.0 + (rand.nextDouble() * 200.0)) * loadMultiplier;
        final sessionRPE = isStrength ? (8.0 + rand.nextDouble() * 1.5) : (7.5 + rand.nextDouble() * 1.0);

        measurements.add(Measurement(
          id: 'load_${d}_${profile.user.id}',
          userId: profile.user.id,
          metric: 'daily_training_load',
          value: double.parse(load.toStringAsFixed(1)),
          unit: 'au',
          timestamp: date.copyWith(hour: 18, minute: 30),
          source: 'synthetic_sim',
          quality: DataQuality.observed,
        ));

        measurements.add(Measurement(
          id: 'rpe_${d}_${profile.user.id}',
          userId: profile.user.id,
          metric: 'session_rpe',
          value: double.parse(sessionRPE.toStringAsFixed(1)),
          unit: 'rpe',
          timestamp: date.copyWith(hour: 18, minute: 30),
          source: 'synthetic_sim',
          quality: DataQuality.observed,
        ));

        // Construct workout sets tailored to archetype
        final double baseWeight = isStrength ? 140.0 : 80.0;
        final int targetReps = isStrength ? 4 : 8;

        final session = WorkoutSession(
          id: 'sim_session_${d}_${profile.user.id}',
          userId: profile.user.id,
          startTime: date.copyWith(hour: 17, minute: 30),
          endTime: date.copyWith(hour: 18, minute: 30),
          goal: profile.goal.type,
          focus: profile.trainingFocus,
          trainingLoad: load,
          averageRPE: sessionRPE,
          status: 'completed',
          prescriptions: [
            ExercisePrescription(
              exerciseId: isStrength ? 'ex_squat_heavy' : 'ex_bench_press',
              exerciseName: isStrength ? 'Heavy Barbell Squat' : 'Barbell Bench Press',
              targetSets: 3,
              targetReps: targetReps,
              targetLoadKg: baseWeight,
              targetRPE: sessionRPE,
              restSeconds: isStrength ? 180 : 120,
              reasonCode: 'simulated_main_compound',
            ),
          ],
          completedSets: [
            ExerciseSet(
              setNumber: 1,
              exerciseId: isStrength ? 'ex_squat_heavy' : 'ex_bench_press',
              prescribedLoadKg: baseWeight,
              actualLoadKg: baseWeight,
              prescribedReps: targetReps,
              actualReps: targetReps,
              targetRPE: sessionRPE,
              actualRPE: sessionRPE,
              timestamp: date.copyWith(hour: 17, minute: 40),
            ),
            ExerciseSet(
              setNumber: 2,
              exerciseId: isStrength ? 'ex_squat_heavy' : 'ex_bench_press',
              prescribedLoadKg: baseWeight,
              actualLoadKg: baseWeight,
              prescribedReps: targetReps,
              actualReps: targetReps,
              targetRPE: sessionRPE,
              actualRPE: sessionRPE,
              timestamp: date.copyWith(hour: 17, minute: 45),
            ),
          ],
        );
        sessions.add(session);
        events.add(KineticEvent(
          id: 'evt_workout_${d}_${profile.user.id}',
          userId: profile.user.id,
          eventType: 'WorkoutCompleted',
          timestamp: date.copyWith(hour: 18, minute: 30),
          payload: {
            'session_id': session.id,
            'load': load,
            'rpe': sessionRPE,
            'tonnage': profile.meanSessionTonnage,
          },
        ));
      } else {
        // Rest day
        measurements.add(Measurement(
          id: 'load_${d}_${profile.user.id}',
          userId: profile.user.id,
          metric: 'daily_training_load',
          value: 0.0,
          unit: 'au',
          timestamp: date.copyWith(hour: 22, minute: 0),
          source: 'synthetic_sim',
          quality: DataQuality.observed,
        ));
      }

      // 7. Daily Calorie Intake
      final double baseCalories = isWeightLoss ? 1900.0 : (isStrength ? 3100.0 : 2600.0);
      final double calNoise = (rand.nextDouble() * 300.0) - 150.0;
      measurements.add(Measurement(
        id: 'cal_${d}_${profile.user.id}',
        userId: profile.user.id,
        metric: 'calories_kcal',
        value: (baseCalories + calNoise).roundToDouble(),
        unit: 'kcal',
        timestamp: date.copyWith(hour: 21, minute: 30),
        source: 'manual_log',
        quality: DataQuality.observed,
      ));
    }

    return SimulationDataset(
      profile: profile,
      days: days,
      measurements: measurements,
      events: events,
      sessions: sessions,
    );
  }

  /// Runs complete closed-loop synthetic intelligence loop across months of time
  /// Observe -> Feature Extraction -> State Estimation -> Decision -> User Action -> Outcome -> Baseline Update
  static ClosedLoopSimulationResult simulateClosedLoopHistory({
    required UserArchetype archetype,
    int days = 90,
    int seed = 42,
    DateTime? deterministicTimestamp,
  }) {
    final dataset = generateHistory(
      archetype: archetype,
      days: days,
      seed: seed,
      deterministicTimestamp: deterministicTimestamp,
    );

    final rand = Random(seed + 100);
    final Map<String, PersonalBaseline> baselines = {};
    final List<Recommendation> recommendations = [];
    final List<RecommendationTrace> traces = [];
    final List<RecommendationFeedbackChain> feedbackChains = [];

    int overrideCount = 0;
    int successCount = 0;

    // Running physiological state trackers
    LatentPhysiologicalState currentState = LatentPhysiologicalState(
      recoveryScore: archetype == UserArchetype.userA_HighRecoveryAthlete ? 88.0 : (archetype == UserArchetype.userB_HighFatiguePoorSleep ? 45.0 : 70.0),
      fatigueScore: archetype == UserArchetype.userB_HighFatiguePoorSleep ? 65.0 : 25.0,
      readinessScore: archetype == UserArchetype.userA_HighRecoveryAthlete ? 90.0 : 65.0,
      adaptationScore: 75.0,
      energyScore: 75.0,
      direction: TrendDirection.stable,
      contributingFactors: ['baseline_initialized'],
      dataQualityScore: 1.0,
      timestamp: deterministicTimestamp ?? DateTime(2026, 8, 18),
      modelVersion: 'state_estimator_v1',
    );

    for (int d = days; d >= 0; d--) {
      final simDate = (deterministicTimestamp ?? DateTime(2026, 8, 18)).subtract(Duration(days: d));

      // 1. Filter daily measurements
      final dailyMeasurements = dataset.measurements.where((m) =>
          m.timestamp.year == simDate.year &&
          m.timestamp.month == simDate.month &&
          m.timestamp.day == simDate.day).toList();

      if (dailyMeasurements.isEmpty) continue;

      // 2. Feature Vector for day
      final hrvM = dailyMeasurements.where((m) => m.metric == 'hrv_rmssd').lastOrNull;
      final rhrM = dailyMeasurements.where((m) => m.metric == 'rhr').lastOrNull;
      final sleepM = dailyMeasurements.where((m) => m.metric == 'sleep_duration_hrs').lastOrNull;
      final loadM = dailyMeasurements.where((m) => m.metric == 'daily_training_load').lastOrNull;

      final hrvVal = hrvM?.value ?? dataset.profile.meanHRV;
      final rhrVal = rhrM?.value ?? dataset.profile.meanRHR;
      final sleepVal = sleepM?.value ?? dataset.profile.targetSleepHours;
      final loadVal = loadM?.value ?? 0.0;

      // Update rolling baselines
      baselines['hrv_rmssd'] = baselines.containsKey('hrv_rmssd')
          ? BaselineEngine.updateBaselineOnline(baselines['hrv_rmssd']!, hrvVal)
          : BaselineEngine.computeHRVBaseline([hrvVal]);
      baselines['rhr'] = baselines.containsKey('rhr')
          ? BaselineEngine.updateBaselineOnline(baselines['rhr']!, rhrVal)
          : BaselineEngine.computeRHRBaseline([rhrVal]);

      final hrvBaseline = baselines['hrv_rmssd']!;
      final effectiveHrvStd = max(hrvBaseline.stdDev, 4.0);
      final hrvZScore = (hrvVal - hrvBaseline.mean) / effectiveHrvStd;
      final rhrDelta = rhrVal - baselines['rhr']!.mean;
      final sleepDebt = (dataset.profile.targetSleepHours - sleepVal).clamp(0.0, 6.0);

      final features = PhysiologicalFeatures(
        hrvZScore: hrvZScore,
        rhrDeltaBpm: rhrDelta,
        sleepDebtHours: sleepDebt,
        sleepQualityScore: sleepVal >= 7.5 ? 85.0 : 50.0,
        acuteTrainingLoad: loadVal > 0 ? loadVal * 1.2 : 200.0,
        chronicTrainingLoad: 250.0,
        acwr: loadVal > 300 ? 1.45 : 1.05,
        activityStepsDelta: 500.0,
        dataCompleteness: 1.0,
        rawFeatureMap: {},
      );

      // 3. Estimate Latent State from physiological signals (HRV 40%, RHR 30%, Sleep 30%)
      final hrvContribution = (hrvVal / 100.0) * 40.0;
      final rhrContribution = ((100.0 - rhrVal).clamp(0.0, 60.0) / 60.0) * 30.0;
      final sleepContribution = ((sleepVal / 8.5).clamp(0.0, 1.0)) * 30.0;
      final recoveryScore = (hrvContribution + rhrContribution + sleepContribution).clamp(20.0, 98.0);

      final fatigueScore = (20.0 + (loadVal > 200 ? 25.0 : 0.0) + (sleepDebt * 8.0)).clamp(10.0, 95.0);
      final readinessScore = (recoveryScore * 0.7 + (100.0 - fatigueScore) * 0.3).clamp(15.0, 99.0);

      currentState = LatentPhysiologicalState(
        recoveryScore: recoveryScore,
        fatigueScore: fatigueScore,
        readinessScore: readinessScore,
        adaptationScore: 75.0,
        energyScore: readinessScore,
        direction: recoveryScore >= 65.0 ? TrendDirection.improving : TrendDirection.declining,
        contributingFactors: [
          if (hrvZScore < -1.0) 'hrv_suppressed',
          if (sleepDebt > 2.0) 'sleep_debt_elevated',
          if (readinessScore >= 80.0) 'readiness_primed',
        ],
        dataQualityScore: 1.0,
        timestamp: simDate,
        modelVersion: 'state_estimator_v1',
      );

      // 4. Recommendation & Trace
      final decision = KineticDecisionEngine.makeDecision(
        userId: dataset.profile.user.id,
        latentState: currentState,
        features: features,
        goal: dataset.profile.goal,
        focus: dataset.profile.trainingFocus,
        deterministicTimestamp: simDate,
      );

      recommendations.add(decision.recommendation);
      traces.add(decision.trace);

      // 5. Simulate User Response (Non-coercive adherence & overrides)
      bool isOverridden = false;
      String userAction = decision.recommendation.action;
      String? overrideReason;

      if (archetype == UserArchetype.userB_HighFatiguePoorSleep && decision.recommendation.action == 'train_hard') {
        isOverridden = true;
        userAction = 'train_light';
        overrideReason = 'fatigue_overriding';
      } else if (archetype == UserArchetype.userA_HighRecoveryAthlete && rand.nextDouble() < 0.08) {
        isOverridden = true;
        userAction = 'train_hard';
        overrideReason = 'felt_exceptionally_primed';
      }

      if (isOverridden) overrideCount++;

      // 6. Simulate Session Outcome & Next-Day Recovery Delta
      final actualRPE = userAction == 'train_hard' ? 8.5 : (userAction == 'rest' ? 0.0 : 7.0);
      final actualVolume = userAction == 'train_hard' ? 6000.0 : (userAction == 'train_normal' ? 4000.0 : 0.0);
      final nextDayRecoveryDelta = (userAction == 'train_hard' && currentState.fatigueScore > 60.0) ? -15.0 : 3.0;
      final performanceCat = (userAction == 'train_hard' && currentState.fatigueScore > 60.0) ? 'fatigue_spike' : 'matched';

      final outcome = RecommendationOutcome(
        recommendationId: decision.recommendation.id,
        userId: dataset.profile.user.id,
        performedAction: userAction,
        actualSessionRPE: actualRPE,
        actualVolumeLoadKg: actualVolume,
        nextDayRecoveryDelta: nextDayRecoveryDelta,
        performanceCategory: performanceCat,
        timestamp: simDate.copyWith(hour: 19),
      );

      final eval = FeedbackEvaluator.evaluate(
        prescribedAction: decision.recommendation.action,
        performedAction: userAction,
        outcome: outcome,
        nextDayState: currentState,
      );

      if (eval['wasSuccessful'] == true) successCount++;

      feedbackChains.add(RecommendationFeedbackChain(
        recommendationId: decision.recommendation.id,
        userId: dataset.profile.user.id,
        recommendation: decision.recommendation,
        recommendedAction: decision.recommendation.action,
        userAction: userAction,
        isAccepted: !isOverridden,
        isOverridden: isOverridden,
        overrideReason: overrideReason,
        outcome: outcome,
        wasSuccessful: eval['wasSuccessful'] as bool,
        successAssessment: eval['successAssessment'] as String,
        generatedAt: simDate,
      ));
    }

    final double successRate = feedbackChains.isNotEmpty ? (successCount / feedbackChains.length) : 1.0;

    return ClosedLoopSimulationResult(
      dataset: dataset,
      recommendations: recommendations,
      traces: traces,
      feedbackChains: feedbackChains,
      baselines: baselines,
      finalState: currentState,
      overrideCount: overrideCount,
      successRate: successRate,
    );
  }
}
