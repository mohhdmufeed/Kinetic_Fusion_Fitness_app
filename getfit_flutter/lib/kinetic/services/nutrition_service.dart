import '../domain/models.dart';
import '../intelligence/nutrition_engine.dart';
import '../persistence/kinetic_store.dart';

/// Application service calculating personalized nutrition targets and hydration needs
class NutritionService {
  final KineticStore store;

  NutritionService({KineticStore? store})
      : store = store ?? KineticStore.instance;

  /// Calculates tailored macronutrient and energy targets based on user, goal, training demands, and weight trends
  NutritionTarget calculateNutritionTargets({
    KineticUser? user,
    required UserGoal goal,
    double todayTrainingLoad = 0.0,
    bool isTrainingDay = false,
    double dailySteps = 8000,
    double weightTrendSlopeKgPerWeek = 0.0,
    double? bodyWeightKg,
    double? heightCm,
    int? age,
    String? sex,
  }) {
    return KineticNutritionEngine.evaluate(NutritionCalculationInput(
      user: user,
      goal: goal,
      todayTrainingLoad: todayTrainingLoad,
      isTrainingDay: isTrainingDay,
      dailySteps: dailySteps,
      weightTrendSlopeKgPerWeek: weightTrendSlopeKgPerWeek,
      bodyWeightKg: bodyWeightKg,
      heightCm: heightCm,
      age: age,
      sex: sex,
    ));
  }
}
