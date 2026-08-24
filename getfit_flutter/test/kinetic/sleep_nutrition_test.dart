import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/intelligence/sleep_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/nutrition_engine.dart';
import 'package:kinetic_precision/kinetic/services/sleep_service.dart';
import 'package:kinetic_precision/kinetic/services/nutrition_service.dart';

void main() {
  group('Phase 7: Sleep & Nutrition Engine Tests', () {
    final athleteUser = KineticUser(
      id: 'u_athlete',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      weightKg: 85.0,
      heightCm: 182.0,
      age: 26,
      sex: 'male',
    );

    final fatLossUser = KineticUser(
      id: 'u_fatloss',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      weightKg: 95.0,
      heightCm: 178.0,
      age: 32,
      sex: 'female',
    );

    test('1. User A (Athlete / Muscle Gain): High training load increases sleep need & caloric surplus', () {
      final sleepService = SleepService();
      final nutritionService = NutritionService();

      const hypertrophyGoal = UserGoal(id: 'g_hyp', userId: 'u_athlete', type: GoalType.hypertrophy);

      // Sleep Evaluation: 8.0h baseline + 450 AU acute load
      final sleepRec = sleepService.getRecommendedSleep(
        userId: 'u_athlete',
        baselineSleepHours: 8.0,
        sleepDebtHours: 0.0,
        acuteTrainingLoad: 450.0,
        dailySteps: 12000,
        preferredWakeHour: 6,
        preferredWakeMinute: 30,
      );

      expect(sleepRec.recommendedSleepDuration, equals(8.75)); // 8.0h + 45m training demand
      expect(sleepRec.contributingFactors, contains('high_training_volume_demand'));
      expect(sleepRec.targetWakeTime, equals('06:30'));
      expect(sleepRec.recommendedSleepWindow.isNotEmpty, isTrue);

      // Nutrition Evaluation: Hypertrophy + Training Day
      final nutrition = nutritionService.calculateNutritionTargets(
        user: athleteUser,
        goal: hypertrophyGoal,
        todayTrainingLoad: 450.0,
        isTrainingDay: true,
        dailySteps: 12000,
      );

      expect(nutrition.proteinGrams, equals(170.0)); // 85kg * 2.0g/kg
      expect(nutrition.primaryGoalReason, equals('caloric_surplus_lean_hypertrophy'));
      expect(nutrition.hydrationLiters, greaterThan(3.5)); // 85kg * 0.035 + 0.75L training day
      expect(nutrition.timingStrategy, contains('Peri-workout'));
    });

    test('2. User B (High Sleep Debt): Sleep debt repayment & recovery compensation', () {
      final sleepService = SleepService();
      final fatiguedRecovery = LatentPhysiologicalState(
        recoveryScore: 35.0,
        fatigueScore: 78.0,
        readinessScore: 38.0,
        adaptationScore: 40.0,
        energyScore: 35.0,
        direction: TrendDirection.declining,
        contributingFactors: ['sleep_debt'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'v1',
      );

      final sleepRec = sleepService.getRecommendedSleep(
        userId: 'u_fatigued',
        baselineSleepHours: 7.5,
        sleepDebtHours: 3.5, // 3.5h accumulated debt
        acuteTrainingLoad: 100.0,
        recoveryState: fatiguedRecovery,
      );

      // 7.5h + debt repayment (1.15h) + fatigue compensation (0.25h) -> ~8.75h to 9.0h
      expect(sleepRec.recommendedSleepDuration, greaterThanOrEqualTo(8.75));
      expect(sleepRec.contributingFactors.any((f) => f.contains('sleep_debt_repayment')), isTrue);
      expect(sleepRec.contributingFactors, contains('elevated_systemic_fatigue_recovery'));
    });

    test('3. User C (Fat Loss Goal): Caloric deficit, high protein protection & weight slope adjustment', () {
      final nutritionService = NutritionService();
      const fatLossGoal = UserGoal(id: 'g_fatloss', userId: 'u_fatloss', type: GoalType.fatLoss);

      // Scenario A: Standard fat loss
      final standardFatLoss = nutritionService.calculateNutritionTargets(
        user: fatLossUser,
        goal: fatLossGoal,
        todayTrainingLoad: 0.0,
        isTrainingDay: false,
        dailySteps: 9000,
        weightTrendSlopeKgPerWeek: -0.40, // Healthy steady loss
      );

      expect(standardFatLoss.proteinGrams, equals(209.0)); // 95kg * 2.2g/kg LBM protection
      expect(standardFatLoss.primaryGoalReason, equals('caloric_deficit_fat_loss_preservation'));
      expect(standardFatLoss.contributingFactors, contains('fat_loss_standard_deficit_applied'));

      // Scenario B: Rapid loss (> 0.75 kg/week) -> eases deficit
      final rapidFatLoss = nutritionService.calculateNutritionTargets(
        user: fatLossUser,
        goal: fatLossGoal,
        todayTrainingLoad: 0.0,
        isTrainingDay: false,
        dailySteps: 9000,
        weightTrendSlopeKgPerWeek: -0.90, // Losing too rapidly
      );

      expect(rapidFatLoss.energyKcal, greaterThan(standardFatLoss.energyKcal));
      expect(rapidFatLoss.contributingFactors, contains('rapid_weight_loss_deficit_eased'));
    });

    test('4. User D (Training Day vs Rest Day): Calorie, carbohydrate & hydration cycling', () {
      final nutritionService = NutritionService();
      const maintenanceGoal = UserGoal(id: 'g_maint', userId: 'u_athlete', type: GoalType.weightMaintenance);

      final trainingDay = nutritionService.calculateNutritionTargets(
        user: athleteUser,
        goal: maintenanceGoal,
        todayTrainingLoad: 350.0,
        isTrainingDay: true,
      );

      final restDay = nutritionService.calculateNutritionTargets(
        user: athleteUser,
        goal: maintenanceGoal,
        todayTrainingLoad: 0.0,
        isTrainingDay: false,
      );

      // Training Day should have higher energy, higher carbs, higher hydration
      expect(trainingDay.energyKcal, greaterThan(restDay.energyKcal));
      expect(trainingDay.carbGrams, greaterThan(restDay.carbGrams));
      expect(trainingDay.hydrationLiters, greaterThan(restDay.hydrationLiters));
      expect(trainingDay.timingStrategy, contains('Peri-workout'));
      expect(restDay.timingStrategy, contains('Evenly distributed'));
    });

    test('5. Missing / Noisy Inputs: Graceful fallback without fake precision', () {
      final sleepService = SleepService();
      final nutritionService = NutritionService();
      const defaultGoal = UserGoal(id: 'g_def', userId: 'u_sparse', type: GoalType.generalFitness);

      // Sleep with null baseline and null debt
      final sparseSleep = sleepService.getRecommendedSleep(
        userId: 'u_sparse',
        baselineSleepHours: null,
        sleepDebtHours: null,
      );
      expect(sparseSleep.contributingFactors, contains('population_prior_fallback_used'));
      expect(sparseSleep.contributingFactors, contains('sleep_debt_signal_unavailable'));
      expect(sparseSleep.confidence, lessThan(0.80));

      // Nutrition with no anthropometric user details
      final sparseNutrition = nutritionService.calculateNutritionTargets(
        user: null,
        goal: defaultGoal,
        bodyWeightKg: null,
      );
      expect(sparseNutrition.contributingFactors, contains('body_weight_fallback_75kg_used'));
      expect(sparseNutrition.dataQuality, equals('moderate'));
      expect(sparseNutrition.confidence, equals(0.65));
    });

    test('6. Pluggable Versioning: Custom strategy & model injection', () {
      // 1. Custom Sleep Model Injection
      final customSleep = _MockSleepModel();
      KineticSleepEngine.setModel(customSleep);
      expect(KineticSleepEngine.version, equals('custom_sleep_v2'));

      final sleepResult = KineticSleepEngine.evaluate(const SleepEvaluationInput());
      expect(sleepResult.modelVersion, equals('custom_sleep_v2'));
      expect(sleepResult.recommendedSleepDuration, equals(9.5));

      KineticSleepEngine.resetModel();
      expect(KineticSleepEngine.version, equals('sleep_model_v1.0'));

      // 2. Custom Nutrition Strategy Injection
      final customNutrition = _MockNutritionStrategy();
      KineticNutritionEngine.setStrategy(customNutrition);

      final nutritionResult = KineticNutritionEngine.evaluate(
        const NutritionCalculationInput(
          goal: UserGoal(id: 'g_cust', userId: 'u1', type: GoalType.hypertrophy),
        ),
      );
      expect(nutritionResult.strategyVersion, equals('keto_custom_v1'));
      expect(nutritionResult.fatGrams, equals(150.0));

      KineticNutritionEngine.resetStrategy();
      expect(KineticNutritionEngine.activeStrategy.strategyId, equals('nutrition_calc_v1'));
    });
  });
}

class _MockSleepModel implements SleepModel {
  @override
  String get modelVersion => 'custom_sleep_v2';

  @override
  SleepRecommendation calculateNeed(SleepEvaluationInput input) {
    return const SleepRecommendation(
      recommendedSleepDuration: 9.5,
      durationRangeMin: 9.0,
      durationRangeMax: 10.0,
      recommendedSleepWindow: '21:30 - 07:00',
      bedtimeStart: '21:15',
      bedtimeEnd: '21:45',
      targetWakeTime: '07:00',
      sleepDebtHours: 0.0,
      reason: 'custom_sleep_prior',
      contributingFactors: ['custom_sleep_prior'],
      confidence: 0.99,
      modelVersion: 'custom_sleep_v2',
    );
  }
}

class _MockNutritionStrategy implements NutritionCalculationStrategy {
  @override
  String get strategyId => 'keto_custom_v1';

  @override
  String get displayName => 'Custom Ketogenic Strategy';

  @override
  NutritionTarget calculate(NutritionCalculationInput input) {
    return const NutritionTarget(
      energyKcal: 2200,
      proteinGrams: 140.0,
      carbGrams: 25.0,
      fatGrams: 150.0,
      hydrationLiters: 3.5,
      timingStrategy: 'Ketogenic high-fat feedings',
      primaryGoalReason: 'ketogenic_adaptation',
      strategyVersion: 'keto_custom_v1',
    );
  }
}
