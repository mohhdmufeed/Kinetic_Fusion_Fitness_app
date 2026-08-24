import '../domain/models.dart';

/// Target nutrition, energy, and macronutrient profile
class NutritionTarget {
  final int energyKcal;
  final double proteinGrams;
  final double carbGrams;
  final double fatGrams;
  final double hydrationLiters;
  final String timingStrategy;
  final String primaryGoalReason;
  final List<String> contributingFactors;
  final String dataQuality;
  final double confidence;
  final String strategyVersion;

  const NutritionTarget({
    required this.energyKcal,
    required this.proteinGrams,
    required this.carbGrams,
    required this.fatGrams,
    required this.hydrationLiters,
    required this.timingStrategy,
    required this.primaryGoalReason,
    this.contributingFactors = const [],
    this.dataQuality = 'high',
    this.confidence = 0.95,
    required this.strategyVersion,
  });

  String get modelVersion => strategyVersion;

  Map<String, dynamic> toJson() => {
        'energyKcal': energyKcal,
        'proteinGrams': proteinGrams,
        'carbGrams': carbGrams,
        'fatGrams': fatGrams,
        'hydrationLiters': hydrationLiters,
        'timingStrategy': timingStrategy,
        'primaryGoalReason': primaryGoalReason,
        'contributingFactors': contributingFactors,
        'dataQuality': dataQuality,
        'confidence': confidence,
        'strategyVersion': strategyVersion,
      };
}

/// Input container for swappable nutrition calculation strategies
class NutritionCalculationInput {
  final KineticUser? user;
  final UserGoal goal;
  final double todayTrainingLoad;
  final bool isTrainingDay;
  final double dailySteps;
  final double weightTrendSlopeKgPerWeek; // e.g. -0.25 kg/week
  final double? bodyWeightKg;
  final double? heightCm;
  final int? age;
  final String? sex;

  const NutritionCalculationInput({
    this.user,
    required this.goal,
    this.todayTrainingLoad = 0.0,
    this.isTrainingDay = false,
    this.dailySteps = 8000,
    this.weightTrendSlopeKgPerWeek = 0.0,
    this.bodyWeightKg,
    this.heightCm,
    this.age,
    this.sex,
  });
}

/// Pluggable interface for versioned, swappable nutrition calculation strategies (SPEC.md Section 17)
abstract class NutritionCalculationStrategy {
  String get strategyId;
  String get displayName;

  NutritionTarget calculate(NutritionCalculationInput input);
}

/// Default Versioned Strategy: `nutrition_calc_v1`
/// Implements Mifflin-St Jeor BMR + dynamic Physical Activity Level + training load demand + macronutrient partitioning
class StandardMifflinStJeorStrategy implements NutritionCalculationStrategy {
  @override
  String get strategyId => 'nutrition_calc_v1';

  @override
  String get displayName => 'Mifflin-St Jeor Dynamic Expenditure Strategy';

  @override
  NutritionTarget calculate(NutritionCalculationInput input) {
    final List<String> factors = [];
    double baseConfidence = 0.95;

    final user = input.user;
    final goal = input.goal;
    
    // Resolve anthropometric data with safe fallbacks
    double weight = input.bodyWeightKg ?? user?.weightKg ?? 75.0;
    double height = input.heightCm ?? user?.heightCm ?? 175.0;
    int age = input.age ?? user?.age ?? 28;
    String sexStr = input.sex ?? user?.sex ?? 'male';
    bool isMale = sexStr.toLowerCase() == 'male';

    if (input.bodyWeightKg == null && user?.weightKg == null) {
      baseConfidence = 0.65;
      factors.add('body_weight_fallback_75kg_used');
    }

    // 1. Basal Metabolic Rate (BMR) - Mifflin-St Jeor
    double bmr = (10.0 * weight) + (6.25 * height) - (5.0 * age);
    bmr += isMale ? 5.0 : -161.0;
    factors.add('bmr_${bmr.round()}kcal');

    // 2. Physical Activity Level (PAL)
    double activityFactor = 1.25; // Base sedentary
    if (input.dailySteps > 12000) {
      activityFactor = 1.50;
      factors.add('pal_active_locomotion');
    } else if (input.dailySteps > 8000) {
      activityFactor = 1.375;
      factors.add('pal_moderate_locomotion');
    } else {
      factors.add('pal_sedentary_baseline');
    }

    double tdee = bmr * activityFactor;

    // 3. Training Load Expenditure
    if (input.isTrainingDay || input.todayTrainingLoad > 0) {
      final trainingExpenditure = (input.todayTrainingLoad * 0.45).clamp(150.0, 600.0);
      tdee += trainingExpenditure;
      factors.add('training_day_expenditure_+${trainingExpenditure.round()}kcal');
    }

    // 4. Goal-Based Energy Delta
    double calorieTarget = tdee;
    String goalReason;

    switch (goal.type) {
      case GoalType.fatLoss:
        // ~18% deficit modulated by weight trend
        double deficit = 0.18;
        if (input.weightTrendSlopeKgPerWeek < -0.75) {
          // Losing too fast (>0.75 kg/week) -> ease deficit to protect LBM
          deficit = 0.12;
          factors.add('rapid_weight_loss_deficit_eased');
        } else {
          factors.add('fat_loss_standard_deficit_applied');
        }
        calorieTarget *= (1.0 - deficit);
        goalReason = 'caloric_deficit_fat_loss_preservation';
        break;

      case GoalType.hypertrophy:
        // ~10% surplus for lean muscle gain
        calorieTarget *= 1.10;
        goalReason = 'caloric_surplus_lean_hypertrophy';
        factors.add('lean_mass_surplus_applied');
        break;

      case GoalType.strength:
        // 5% slight surplus for neuromuscular recovery
        calorieTarget *= 1.05;
        goalReason = 'caloric_slight_surplus_strength_peaking';
        factors.add('strength_peaking_surplus_applied');
        break;

      case GoalType.endurance:
        // High glycogen replacement
        calorieTarget *= 1.08;
        goalReason = 'glycogen_replenishment_endurance';
        factors.add('endurance_glycogen_surplus_applied');
        break;

      default:
        goalReason = 'energy_balance_homeostasis';
        factors.add('maintenance_isocaloric_balance');
        break;
    }

    // 5. Macronutrient Partitioning
    // Protein: 2.2g/kg for fat loss, 2.0g/kg for hypertrophy/strength, 1.8g/kg for maintenance
    double proteinMultiplier;
    if (goal.type == GoalType.fatLoss) {
      proteinMultiplier = 2.2;
    } else if (goal.type == GoalType.hypertrophy || goal.type == GoalType.strength) {
      proteinMultiplier = 2.0;
    } else {
      proteinMultiplier = 1.8;
    }
    double proteinGrams = (weight * proteinMultiplier).roundToDouble();

    // Fat: 25% of total calories (9 kcal per gram)
    double fatCalories = calorieTarget * 0.25;
    double fatGrams = (fatCalories / 9.0 * 10).round() / 10.0;

    // Carbs: Remainder of energy (4 kcal per gram)
    double proteinCalories = proteinGrams * 4.0;
    double carbCalories = (calorieTarget - proteinCalories - fatCalories).clamp(100.0, 3500.0);
    double carbGrams = (carbCalories / 4.0 * 10).round() / 10.0;

    // 6. Hydration
    double hydrationLiters = (weight * 0.035) + (input.isTrainingDay ? 0.75 : 0.0);

    // 7. Nutrient Timing Guidance
    String timingStrategy;
    if (input.isTrainingDay) {
      timingStrategy = 'Peri-workout: 35g protein + 50g fast carbs within 90 mins post-workout; balance across 4 feedings.';
    } else {
      timingStrategy = 'Evenly distributed: 4 meals spaced ~3.5h apart with 30g+ high-quality protein per meal.';
    }

    final dataQuality = baseConfidence >= 0.9 ? 'high' : (baseConfidence >= 0.6 ? 'moderate' : 'low');

    return NutritionTarget(
      energyKcal: calorieTarget.round(),
      proteinGrams: proteinGrams,
      carbGrams: carbGrams,
      fatGrams: fatGrams,
      hydrationLiters: (hydrationLiters * 10).round() / 10.0,
      timingStrategy: timingStrategy,
      primaryGoalReason: goalReason,
      contributingFactors: factors,
      dataQuality: dataQuality,
      confidence: baseConfidence,
      strategyVersion: strategyId,
    );
  }
}

/// Nutrition Engine (SPEC.md Section 17)
class KineticNutritionEngine {
  static const String version = 'nutrition_model_v1.0';

  /// Active swappable strategy (defaults to nutrition_calc_v1)
  static NutritionCalculationStrategy activeStrategy = StandardMifflinStJeorStrategy();

  /// Sets a custom or updated nutrition calculation strategy
  static void setStrategy(NutritionCalculationStrategy strategy) {
    activeStrategy = strategy;
  }

  /// Resets to default strategy
  static void resetStrategy() {
    activeStrategy = StandardMifflinStJeorStrategy();
  }

  /// Calculates personalized calorie and macro targets using the active swappable strategy
  static NutritionTarget calculateTargets({
    required KineticUser user,
    required UserGoal goal,
    required double todayTrainingLoad,
    required bool isTrainingDay,
    double dailySteps = 8000,
    double weightTrendSlopeKgPerWeek = 0.0,
  }) {
    return activeStrategy.calculate(NutritionCalculationInput(
      user: user,
      goal: goal,
      todayTrainingLoad: todayTrainingLoad,
      isTrainingDay: isTrainingDay,
      dailySteps: dailySteps,
      weightTrendSlopeKgPerWeek: weightTrendSlopeKgPerWeek,
    ));
  }

  /// Evaluates nutrition targets directly from input container
  static NutritionTarget evaluate(NutritionCalculationInput input) {
    return activeStrategy.calculate(input);
  }
}
