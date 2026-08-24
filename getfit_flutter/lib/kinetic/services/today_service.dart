import '../domain/models.dart';
import '../intelligence/feature_engine.dart';
import '../intelligence/state_estimator.dart';
import '../intelligence/decision_engine.dart';
import '../intelligence/sleep_engine.dart';
import '../intelligence/nutrition_engine.dart';
import '../intelligence/training_engine.dart';
import '../persistence/kinetic_store.dart';
import 'telemetry_service.dart';

/// Complete View Model for rendering the Today Screen with zero additional database queries (SPEC.md Section 29)
class TodayViewModel {
  final KineticUser user;
  final LatentPhysiologicalState currentState;
  final Recommendation primaryRecommendation;
  final String recommendationReason;
  final NutritionTarget nutritionTarget;
  final SleepRecommendation sleepTarget;
  final WorkoutSession? upcomingWorkout;
  final double dataQualityScore;
  final String dataQualityLabel; // 'High Precision', 'Moderate', 'Sparse'
  final DateTime generatedAt;

  const TodayViewModel({
    required this.user,
    required this.currentState,
    required this.primaryRecommendation,
    required this.recommendationReason,
    required this.nutritionTarget,
    required this.sleepTarget,
    this.upcomingWorkout,
    required this.dataQualityScore,
    required this.dataQualityLabel,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': user.id,
        'recoveryScore': currentState.recoveryScore,
        'readinessScore': currentState.readinessScore,
        'fatigueScore': currentState.fatigueScore,
        'direction': currentState.direction.name,
        'recommendationHeadline': primaryRecommendation.headline,
        'recommendationAction': primaryRecommendation.action,
        'recommendationRationale': primaryRecommendation.rationale,
        'targetCalories': nutritionTarget.energyKcal,
        'targetProtein': nutritionTarget.proteinGrams,
        'recommendedSleepDuration': sleepTarget.targetDurationHours,
        'recommendedSleepWindow': sleepTarget.recommendedSleepWindow,
        'dataQuality': dataQualityLabel,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

/// Application Service providing the Today screen contract (SPEC.md Sections 3 & 28)
class TodayService {
  final KineticStore store;
  final KineticFeatureEngine featureEngine;
  final KineticStateEstimator stateEstimator;
  final TelemetryService telemetryService;

  TodayService({
    KineticStore? store,
    KineticFeatureEngine? featureEngine,
    KineticStateEstimator? stateEstimator,
    TelemetryService? telemetryService,
  })  : store = store ?? KineticStore.instance,
        featureEngine = featureEngine ??
            KineticFeatureEngine(baselines: (store ?? KineticStore.instance).getBaselines()),
        stateEstimator = stateEstimator ?? KineticStateEstimator(),
        telemetryService = telemetryService ?? TelemetryService(store: store ?? KineticStore.instance);

  /// 1. getToday(): Returns the full TodayViewModel snapshot
  Future<TodayViewModel> getToday() async {
    final user = store.getUser() ??
        KineticUser(
          id: 'default_user',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

    final goals = store.getGoals();
    final primaryGoal = goals.isNotEmpty
        ? goals.first
        : UserGoal(
            id: 'default_goal',
            userId: user.id,
            type: GoalType.hypertrophy,
          );

    // Group raw measurements by metric
    final Map<String, List<Measurement>> rawGrouped = {};
    for (final m in store.getMeasurements()) {
      rawGrouped.putIfAbsent(m.metric, () => []).add(m);
    }

    // 1. Feature Extraction
    final features = featureEngine.extractFeatures(rawGrouped);

    // 2. Latent State Estimation
    final latentState = stateEstimator.estimateState(features, {});
    store.recordLatentState(latentState);

    // 3. Decision Engine & WHY Trace Generation
    final decision = KineticDecisionEngine.makeDecision(
      userId: user.id,
      latentState: latentState,
      features: features,
      goal: primaryGoal,
      focus: TrainingFocus.hypertrophy,
    );
    store.recordRecommendation(decision.recommendation);
    store.recordTrace(decision.trace);

    // 4. Sleep Target
    final sleepTarget = KineticSleepEngine.calculateNeed(
      baselineSleepHours: store.getBaseline('sleep_duration_hrs')?.mean ?? 8.0,
      sleepDebtHours: features.sleepDebtHours,
      acuteTrainingLoad: features.acuteTrainingLoad,
      recoveryState: latentState,
    );

    // 5. Nutrition Target
    final isTrainingDay = decision.recommendation.action != 'rest';
    final nutritionTarget = KineticNutritionEngine.calculateTargets(
      user: user,
      goal: primaryGoal,
      todayTrainingLoad: features.acuteTrainingLoad,
      isTrainingDay: isTrainingDay,
    );

    // 6. Upcoming Workout
    WorkoutSession? workout;
    if (isTrainingDay) {
      workout = KineticTrainingEngine.generateWorkout(
        userId: user.id,
        goal: primaryGoal,
        focus: TrainingFocus.hypertrophy,
        readinessState: latentState,
      );
      store.saveSession(workout);
    }

    final dataQualityLabel = features.dataCompleteness > 0.8
        ? 'High Precision'
        : (features.dataCompleteness > 0.4 ? 'Moderate' : 'Sparse');

    return TodayViewModel(
      user: user,
      currentState: latentState,
      primaryRecommendation: decision.recommendation,
      recommendationReason: decision.recommendation.rationale,
      nutritionTarget: nutritionTarget,
      sleepTarget: sleepTarget,
      upcomingWorkout: workout,
      dataQualityScore: features.dataCompleteness,
      dataQualityLabel: dataQualityLabel,
      generatedAt: DateTime.now(),
    );
  }

  /// 2. getCurrentRecommendation(): Returns the active primary recommendation
  Future<Recommendation?> getCurrentRecommendation() async {
    final today = await getToday();
    return today.primaryRecommendation;
  }

  /// 3. getRecommendationReason(): Returns explicit diagnostic rationale for a recommendation
  Future<String?> getRecommendationReason(String recommendationId) async {
    final trace = store.getTrace(recommendationId);
    return trace?.reasonCodes.firstOrNull ?? 'Baseline circadian homeostasis';
  }

  /// 4. getRecoveryState(): Returns the current latent physiological state
  Future<LatentPhysiologicalState> getRecoveryState() async {
    final today = await getToday();
    return today.currentState;
  }

  /// 5. getTargets(): Returns active nutrition and sleep targets
  Future<Map<String, dynamic>> getTargets() async {
    final today = await getToday();
    return {
      'nutrition': today.nutritionTarget.toJson(),
      'sleep': today.sleepTarget.toJson(),
    };
  }

  /// 6. getTelemetry(): Retrieves complete WHY explanation for a recommendation
  Future<WhyExplanationViewModel?> getTelemetry(String recommendationId) async {
    return telemetryService.explainRecommendation(recommendationId);
  }
}
