import '../contracts/app_view_models.dart';
import '../domain/models.dart';
import '../math/time_series.dart';
import '../persistence/kinetic_store.dart';
import 'today_service.dart';
import 'training_service.dart';
import 'decision_service.dart';
import 'progression_service.dart';
import 'sleep_service.dart';
import 'nutrition_service.dart';
import 'feedback_service.dart';
import 'telemetry_service.dart';

/// Single unified application facade providing stable, type-safe API contracts for the Kinetic UI
class KineticAppFacade {
  final KineticStore store;
  final TodayService todayService;
  final TrainingService trainingService;
  final DecisionService decisionService;
  final ProgressionService progressionService;
  final SleepService sleepService;
  final NutritionService nutritionService;
  final FeedbackService feedbackService;
  final TelemetryService telemetryService;

  KineticAppFacade({
    KineticStore? store,
    TodayService? todayService,
    TrainingService? trainingService,
    DecisionService? decisionService,
    ProgressionService? progressionService,
    SleepService? sleepService,
    NutritionService? nutritionService,
    FeedbackService? feedbackService,
    TelemetryService? telemetryService,
  })  : store = store ?? KineticStore.instance,
        todayService = todayService ?? TodayService(store: store ?? KineticStore.instance),
        trainingService = trainingService ?? TrainingService(store: store ?? KineticStore.instance),
        decisionService = decisionService ?? DecisionService(store: store ?? KineticStore.instance),
        progressionService = progressionService ?? ProgressionService(store: store ?? KineticStore.instance),
        sleepService = sleepService ?? SleepService(store: store ?? KineticStore.instance),
        nutritionService = nutritionService ?? NutritionService(store: store ?? KineticStore.instance),
        feedbackService = feedbackService ?? FeedbackService(store: store ?? KineticStore.instance),
        telemetryService = telemetryService ?? TelemetryService(store: store ?? KineticStore.instance);

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY APIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 1. Retrieves Today Screen View Model
  Future<KineticResult<TodayViewModel>> getToday() async {
    try {
      final vm = await todayService.getToday();
      return KineticResult.success(vm);
    } catch (e, st) {
      return KineticResult.failure(StoreError(message: e.toString(), details: st));
    }
  }

  /// 2. Retrieves current active or upcoming planned workout
  Future<KineticResult<WorkoutViewModel>> getCurrentWorkout() async {
    try {
      final active = store.getActiveSession();
      if (active == null) {
        final planned = store.getSessions().where((s) => s.status == 'planned').lastOrNull;
        if (planned == null) {
          return const KineticResult.failure(MissingDataError(
            resource: 'WorkoutSession',
            message: 'No active or planned workout session found.',
          ));
        }
        return KineticResult.success(trainingService.buildViewModel(planned));
      }
      return KineticResult.success(trainingService.buildViewModel(active));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 3. Retrieves current active primary recommendation
  Future<KineticResult<RecommendationViewModel>> getCurrentRecommendation() async {
    try {
      final rec = store.getLatestRecommendation();
      if (rec == null) {
        return const KineticResult.failure(MissingDataError(
          resource: 'Recommendation',
          message: 'No recommendation generated for today yet.',
        ));
      }
      return KineticResult.success(RecommendationViewModel.fromDomain(rec));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 4. Retrieves WHY explanation audit trace for a specific recommendation
  Future<KineticResult<WhyViewModel>> getRecommendationReason(String recommendationId) async {
    try {
      if (recommendationId.trim().isEmpty) {
        return const KineticResult.failure(ValidationError(
          field: 'recommendationId',
          message: 'Recommendation ID cannot be empty.',
        ));
      }

      final trace = store.getTrace(recommendationId);
      if (trace == null) {
        return KineticResult.failure(MissingDataError(
          resource: 'RecommendationTrace',
          message: 'No audit trace found for recommendation $recommendationId.',
        ));
      }

      return KineticResult.success(WhyViewModel.fromTrace(trace));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 5. Retrieves next immediate exercise set to perform in active session
  Future<KineticResult<NextSetViewModel>> getNextSet() async {
    try {
      final active = store.getActiveSession();
      if (active == null) {
        return const KineticResult.failure(InvalidStateTransitionError(
          currentStatus: 'no_active_session',
          attemptedTransition: 'getNextSet',
          message: 'Cannot query next set without an active in-progress workout.',
        ));
      }

      final vm = trainingService.buildViewModel(active);
      final currentPrescription = vm.currentPrescription;

      if (currentPrescription == null || vm.isCompleted) {
        return const KineticResult.failure(MissingDataError(
          resource: 'NextSet',
          message: 'Workout is already completed. No remaining sets.',
        ));
      }

      final isLastSetOfExercise = vm.nextSetNumber >= currentPrescription.targetSets;
      final isLastSetOfWorkout = isLastSetOfExercise &&
          vm.currentPrescriptionIndex >= active.prescriptions.length - 1;

      return KineticResult.success(NextSetViewModel(
        prescriptionIndex: vm.currentPrescriptionIndex,
        setNumber: vm.nextSetNumber,
        exerciseId: currentPrescription.exerciseId,
        exerciseName: currentPrescription.exerciseName,
        targetLoadKg: vm.prescribedLoadKg,
        targetReps: vm.prescribedReps,
        targetRPE: vm.prescribedTargetRPE,
        restSeconds: currentPrescription.restSeconds,
        isLastSetOfExercise: isLastSetOfExercise,
        isLastSetOfWorkout: isLastSetOfWorkout,
      ));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 6. Retrieves current latent physiological recovery state
  Future<KineticResult<RecoveryStateViewModel>> getRecoveryState() async {
    try {
      final state = store.getLatestLatentState();
      if (state == null) {
        return const KineticResult.failure(MissingDataError(
          resource: 'LatentPhysiologicalState',
          message: 'No latent physiological state estimated yet.',
        ));
      }
      return KineticResult.success(RecoveryStateViewModel.fromDomain(state));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 7. Retrieves body composition trajectory and goal ETA
  Future<KineticResult<BodyTrajectoryViewModel>> getBodyTrajectory() async {
    try {
      final weightMeasurements = store.getMeasurements(metric: 'weight_kg');
      if (weightMeasurements.isEmpty) {
        return const KineticResult.failure(MissingDataError(
          resource: 'weight_kg',
          message: 'No bodyweight measurements recorded yet.',
        ));
      }

      weightMeasurements.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final currentWeight = weightMeasurements.last.value;
      final weights = weightMeasurements.map((m) => m.value).toList();

      final slope = TimeSeriesEngine.computeTrendSlope(weights); // kg per measurement
      final weeklySlope = slope * 7.0;

      final goal = store.getGoals().firstOrNull;
      double? targetWeight;
      double? projectedEta;

      if (goal != null && goal.targetValue != null) {
        targetWeight = goal.targetValue;
        final delta = (currentWeight - targetWeight!).abs();
        if (weeklySlope.abs() > 0.05) {
          projectedEta = delta / weeklySlope.abs();
        }
      }

      final trend = weeklySlope < -0.1 ? 'losing' : (weeklySlope > 0.1 ? 'gaining' : 'stable');

      return KineticResult.success(BodyTrajectoryViewModel(
        currentWeightKg: currentWeight,
        targetWeightKg: targetWeight,
        weeklyWeightSlopeKg: double.parse(weeklySlope.toStringAsFixed(2)),
        projectedEtaWeeks: projectedEta != null ? double.parse(projectedEta.toStringAsFixed(1)) : null,
        trendDirection: trend,
        lastMeasured: weightMeasurements.last.timestamp,
      ));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 8. Retrieves daily nutrition, steps, and sleep targets
  Future<KineticResult<TargetsViewModel>> getTargets() async {
    try {
      final user = store.getUser() ?? KineticUser(id: 'default', createdAt: DateTime.now(), updatedAt: DateTime.now());
      final goal = store.getGoals().firstOrNull ?? UserGoal(id: 'g', userId: user.id, type: GoalType.generalFitness);

      final nutrition = nutritionService.calculateNutritionTargets(user: user, goal: goal, isTrainingDay: true);
      final sleep = sleepService.getRecommendedSleep(userId: user.id);

      return KineticResult.success(TargetsViewModel(
        dailyStepsTarget: 10000,
        targetCaloriesKcal: nutrition.energyKcal.toDouble(),
        targetProteinGrams: nutrition.proteinGrams,
        targetSleepDurationHours: sleep.targetDurationHours,
        recommendedBedtimeWindow: sleep.recommendedSleepWindow,
      ));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 9. Retrieves telemetry and local audit statistics
  Future<KineticResult<TelemetryViewModel>> getTelemetry() async {
    try {
      return KineticResult.success(TelemetryViewModel(
        totalEventsRecorded: store.getEvents().length,
        totalMeasurementsRecorded: store.getMeasurements().length,
        totalWorkoutsLogged: store.getSessions().length,
        totalTracesStored: store.getEvents().where((e) => e.eventType == 'RecommendationGenerated').length,
        dataStorageMode: 'Local-Only (Zero Cloud)',
        lastAuditTimestamp: DateTime.now(),
      ));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMAND APIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 1. Creates or updates a Kinetic User
  Future<KineticResult<KineticUser>> createUser(KineticUser user) async {
    if (user.id.trim().isEmpty) {
      return const KineticResult.failure(ValidationError(
        field: 'id',
        message: 'User ID cannot be empty.',
      ));
    }
    if (user.age != null && user.age! <= 0) {
      return const KineticResult.failure(ValidationError(
        field: 'age',
        message: 'Age must be greater than 0.',
      ));
    }
    if (user.weightKg != null && user.weightKg! <= 0) {
      return const KineticResult.failure(ValidationError(
        field: 'weightKg',
        message: 'Weight must be greater than 0 kg.',
      ));
    }

    try {
      store.saveUser(user);
      return KineticResult.success(user);
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 2. Creates or updates a User Goal
  Future<KineticResult<UserGoal>> createGoal(UserGoal goal) async {
    if (goal.id.trim().isEmpty) {
      return const KineticResult.failure(ValidationError(
        field: 'id',
        message: 'Goal ID cannot be empty.',
      ));
    }
    if (goal.userId.trim().isEmpty) {
      return const KineticResult.failure(ValidationError(
        field: 'userId',
        message: 'User ID associated with goal cannot be empty.',
      ));
    }

    try {
      store.addGoal(goal);
      return KineticResult.success(goal);
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 3. Starts an interactive workout session
  Future<KineticResult<WorkoutViewModel>> startWorkout({
    WorkoutSession? session,
    String? workoutId,
    TrainingFocus? focus,
  }) async {
    try {
      final defaultState = LatentPhysiologicalState(
        recoveryScore: 80.0,
        fatigueScore: 20.0,
        readinessScore: 80.0,
        adaptationScore: 75.0,
        energyScore: 80.0,
        direction: TrendDirection.stable,
        contributingFactors: const ['ready'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'v1',
      );

      final effectiveSession = session ??
          progressionService.generateWorkout(
            userId: store.getUser()?.id ?? 'default_user',
            goal: store.getGoals().firstOrNull ?? const UserGoal(id: 'g', userId: 'default', type: GoalType.hypertrophy),
            focus: focus ?? TrainingFocus.hypertrophy,
            readinessState: store.getLatestLatentState() ?? defaultState,
          );

      final vm = await trainingService.startSession(effectiveSession);
      return KineticResult.success(vm);
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 4. Logs a completed set with real-time autoregulation
  Future<KineticResult<WorkoutViewModel>> completeSet({
    required String sessionId,
    required String exerciseId,
    required double actualLoadKg,
    required int actualReps,
    required double actualRPE,
    int restSeconds = 90,
  }) async {
    if (actualLoadKg < 0) {
      return const KineticResult.failure(ValidationError(
        field: 'actualLoadKg',
        message: 'Load (kg) cannot be negative.',
      ));
    }
    if (actualReps < 0) {
      return const KineticResult.failure(ValidationError(
        field: 'actualReps',
        message: 'Reps count cannot be negative.',
      ));
    }
    if (actualRPE < 1.0 || actualRPE > 10.0) {
      return const KineticResult.failure(ValidationError(
        field: 'actualRPE',
        message: 'RPE must be on the Borg CR-10 scale between 1.0 and 10.0.',
      ));
    }

    final active = store.getActiveSession();
    if (active == null || active.id != sessionId) {
      return KineticResult.failure(InvalidStateTransitionError(
        currentStatus: active?.status ?? 'none',
        attemptedTransition: 'completeSet',
        message: 'Session $sessionId is not currently in progress.',
      ));
    }

    try {
      final vm = await trainingService.logSet(
        sessionId: sessionId,
        exerciseId: exerciseId,
        actualLoadKg: actualLoadKg,
        actualReps: actualReps,
        actualRPE: actualRPE,
        restSeconds: restSeconds,
      );
      return KineticResult.success(vm);
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 5. Pauses an active workout session
  Future<KineticResult<WorkoutViewModel>> pauseWorkout(String sessionId) async {
    final active = store.getActiveSession();
    if (active == null || active.id != sessionId) {
      return KineticResult.failure(InvalidStateTransitionError(
        currentStatus: active?.status ?? 'none',
        attemptedTransition: 'pauseWorkout',
        message: 'Session $sessionId is not currently in progress.',
      ));
    }

    try {
      final pausedSession = WorkoutSession(
        id: active.id,
        userId: active.userId,
        startTime: active.startTime,
        endTime: active.endTime,
        goal: active.goal,
        focus: active.focus,
        prescriptions: active.prescriptions,
        completedSets: active.completedSets,
        trainingLoad: active.trainingLoad,
        averageRPE: active.averageRPE,
        status: 'paused',
      );
      store.saveSession(pausedSession);
      return KineticResult.success(trainingService.buildViewModel(pausedSession));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 6. Completes an active workout session and triggers volume overload & recovery updates
  Future<KineticResult<WorkoutViewModel>> completeWorkout(String sessionId) async {
    final session = store.getSessions().where((s) => s.id == sessionId).lastOrNull;
    if (session == null) {
      return KineticResult.failure(MissingDataError(
        resource: 'WorkoutSession',
        message: 'Session $sessionId does not exist.',
      ));
    }
    if (session.status == 'completed') {
      return KineticResult.failure(InvalidStateTransitionError(
        currentStatus: 'completed',
        attemptedTransition: 'completeWorkout',
        message: 'Session $sessionId is already marked completed.',
      ));
    }

    try {
      final completed = await trainingService.completeSession(sessionId);
      return KineticResult.success(trainingService.buildViewModel(completed));
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 7. Accepts a recommendation
  Future<KineticResult<void>> acceptRecommendation(String recommendationId) async {
    if (recommendationId.trim().isEmpty) {
      return const KineticResult.failure(ValidationError(
        field: 'recommendationId',
        message: 'Recommendation ID cannot be empty.',
      ));
    }

    try {
      decisionService.acceptRecommendation(recommendationId);
      return const KineticResult.success(null);
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 8. Overrides a recommendation with custom action and reason
  Future<KineticResult<void>> overrideRecommendation({
    required String recommendationId,
    required String overrideAction,
    required String overrideReason,
    String? notes,
  }) async {
    if (recommendationId.trim().isEmpty) {
      return const KineticResult.failure(ValidationError(
        field: 'recommendationId',
        message: 'Recommendation ID cannot be empty.',
      ));
    }
    if (overrideAction.trim().isEmpty) {
      return const KineticResult.failure(ValidationError(
        field: 'overrideAction',
        message: 'Override action cannot be empty.',
      ));
    }

    try {
      decisionService.overrideRecommendation(
        recommendationId: recommendationId,
        overrideAction: overrideAction,
        overrideReason: overrideReason,
        notes: notes,
      );
      return const KineticResult.success(null);
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }

  /// 9. Records a raw physiological or behavioral measurement
  Future<KineticResult<Measurement>> recordMeasurement({
    required String metric,
    required double value,
    required String unit,
    DateTime? timestamp,
    String source = 'user_entry',
  }) async {
    if (metric.trim().isEmpty) {
      return const KineticResult.failure(ValidationError(
        field: 'metric',
        message: 'Metric identifier cannot be empty.',
      ));
    }
    if (value < 0 && (metric == 'weight_kg' || metric == 'hrv_rmssd' || metric == 'rhr' || metric == 'steps')) {
      return KineticResult.failure(ValidationError(
        field: 'value',
        message: 'Value for metric $metric cannot be negative.',
      ));
    }

    try {
      final now = timestamp ?? DateTime.now();
      final user = store.getUser();
      final measurement = Measurement(
        id: 'meas_${metric}_${now.millisecondsSinceEpoch}',
        userId: user?.id ?? 'default_user',
        metric: metric,
        value: value,
        unit: unit,
        timestamp: now,
        source: source,
        quality: DataQuality.observed,
      );
      store.recordMeasurement(measurement);
      return KineticResult.success(measurement);
    } catch (e) {
      return KineticResult.failure(StoreError(message: e.toString()));
    }
  }
}
