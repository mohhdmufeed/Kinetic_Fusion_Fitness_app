import '../domain/models.dart';
import '../intelligence/sleep_engine.dart';
import '../persistence/kinetic_store.dart';

/// Application service providing personalized sleep recommendations
class SleepService {
  final KineticStore store;

  SleepService({KineticStore? store})
      : store = store ?? KineticStore.instance;

  /// Returns recommended sleep duration, circadian window, and factor explanation
  SleepRecommendation getRecommendedSleep({
    required String userId,
    double? baselineSleepHours,
    double? sleepDebtHours,
    double acuteTrainingLoad = 0.0,
    LatentPhysiologicalState? recoveryState,
    double dailySteps = 8000,
    int preferredWakeHour = 7,
    int preferredWakeMinute = 0,
    bool routineDisrupted = false,
  }) {
    // If baseline is not passed, attempt lookup in store
    double? effectiveBaseline = baselineSleepHours;
    if (effectiveBaseline == null) {
      final storedBaseline = store.getBaseline('sleep_duration_hrs');
      effectiveBaseline = storedBaseline?.value;
    }

    return KineticSleepEngine.evaluate(SleepEvaluationInput(
      baselineSleepHours: effectiveBaseline,
      sleepDebtHours: sleepDebtHours,
      acuteTrainingLoad: acuteTrainingLoad,
      recoveryState: recoveryState,
      dailySteps: dailySteps,
      preferredWakeHour: preferredWakeHour,
      preferredWakeMinute: preferredWakeMinute,
      routineDisrupted: routineDisrupted,
    ));
  }
}
