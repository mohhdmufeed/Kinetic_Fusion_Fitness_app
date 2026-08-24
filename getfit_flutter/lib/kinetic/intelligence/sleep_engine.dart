import '../domain/models.dart';

/// Structured sleep recommendation matching SPEC.md Section 16
class SleepRecommendation {
  /// Recommended primary duration in hours (rounded to realistic 15-min increments, e.g. 8.25)
  final double recommendedSleepDuration;

  /// Uncertainty / tolerance duration range to prevent false precision
  final double durationRangeMin;
  final double durationRangeMax;

  /// Recommended circadian sleep window string (e.g. "22:30 - 07:00")
  final String recommendedSleepWindow;
  final String bedtimeStart;
  final String bedtimeEnd;
  final String targetWakeTime;

  final double sleepDebtHours;
  final String reason;
  final List<String> contributingFactors;
  final double confidence;
  final String modelVersion;

  const SleepRecommendation({
    required this.recommendedSleepDuration,
    required this.durationRangeMin,
    required this.durationRangeMax,
    required this.recommendedSleepWindow,
    required this.bedtimeStart,
    required this.bedtimeEnd,
    required this.targetWakeTime,
    required this.sleepDebtHours,
    required this.reason,
    required this.contributingFactors,
    required this.confidence,
    required this.modelVersion,
  });

  double get targetDurationHours => recommendedSleepDuration;
  String get primaryReason => reason;

  Map<String, dynamic> toJson() => {
        'recommendedSleepDuration': recommendedSleepDuration,
        'durationRangeMin': durationRangeMin,
        'durationRangeMax': durationRangeMax,
        'recommendedSleepWindow': recommendedSleepWindow,
        'bedtimeStart': bedtimeStart,
        'bedtimeEnd': bedtimeEnd,
        'targetWakeTime': targetWakeTime,
        'sleepDebtHours': sleepDebtHours,
        'reason': reason,
        'contributingFactors': contributingFactors,
        'confidence': confidence,
        'modelVersion': modelVersion,
      };
}

/// Raw physiological and behavioral inputs for sleep need evaluation
class SleepEvaluationInput {
  final double? baselineSleepHours; // Nullable if baseline not yet established
  final double? sleepDebtHours; // Nullable if sleep history incomplete
  final double acuteTrainingLoad; // Foster AU or Volume score
  final LatentPhysiologicalState? recoveryState;
  final double dailySteps;
  final int preferredWakeHour;
  final int preferredWakeMinute;
  final bool routineDisrupted;

  const SleepEvaluationInput({
    this.baselineSleepHours,
    this.sleepDebtHours,
    this.acuteTrainingLoad = 0.0,
    this.recoveryState,
    this.dailySteps = 8000,
    this.preferredWakeHour = 7,
    this.preferredWakeMinute = 0,
    this.routineDisrupted = false,
  });
}

/// Pluggable interface for versioned sleep models
abstract class SleepModel {
  String get modelVersion;
  SleepRecommendation calculateNeed(SleepEvaluationInput input);
}

/// Default rule-based sleep recommendation model (sleep_model_v1.0)
class RuleBasedSleepModelV1 implements SleepModel {
  @override
  String get modelVersion => 'sleep_model_v1.0';

  @override
  SleepRecommendation calculateNeed(SleepEvaluationInput input) {
    final List<String> factors = [];
    double baseConfidence = 0.95;

    // 1. Establish individual base requirement (avoid one-size-fits-all 8h hardcoding)
    double duration;
    if (input.baselineSleepHours != null && input.baselineSleepHours! > 0) {
      duration = input.baselineSleepHours!;
      factors.add('personalized_baseline_${duration.toStringAsFixed(1)}h');
    } else {
      duration = 7.75; // Standard population starting prior
      baseConfidence = 0.70;
      factors.add('population_prior_fallback_used');
    }

    // 2. Training load demand: High training volume adds 20-45 mins sleep requirement
    if (input.acuteTrainingLoad > 400) {
      duration += 0.75; // +45 mins
      factors.add('high_training_volume_demand');
    } else if (input.acuteTrainingLoad > 250) {
      duration += 0.5; // +30 mins
      factors.add('moderate_training_strain');
    }

    // 3. Sleep debt repayment: Pay back ~33% of accumulated debt (capped at 1.25h max to protect circadian rhythm)
    final debt = input.sleepDebtHours ?? 0.0;
    if (input.sleepDebtHours == null) {
      baseConfidence = (baseConfidence * 0.85);
      factors.add('sleep_debt_signal_unavailable');
    } else if (debt > 0.5) {
      final debtPayment = (debt * 0.33).clamp(0.25, 1.25);
      duration += debtPayment;
      factors.add('sleep_debt_repayment_${(debtPayment * 60).round()}mins');
    }

    // 4. Systemic fatigue recovery compensation
    if (input.recoveryState != null && input.recoveryState!.fatigueScore > 70.0) {
      duration += 0.25;
      factors.add('elevated_systemic_fatigue_recovery');
    }

    // 5. Heavy daily activity / locomotion adjustment
    if (input.dailySteps > 15000) {
      duration += 0.25;
      factors.add('high_daily_locomotion_activity');
    }

    // 6. Routine disruption penalty
    if (input.routineDisrupted) {
      duration += 0.25;
      factors.add('circadian_routine_disruption_buffer');
    }

    // Bound realistic duration between 6.5h and 10.0h
    duration = duration.clamp(6.5, 10.0);
    // Round to nearest 15 minutes (0.25h) to avoid false precision
    final roundedDuration = (duration * 4).round() / 4.0;
    final rangeMin = (roundedDuration - 0.25).clamp(6.0, 10.0);
    final rangeMax = (roundedDuration + 0.25).clamp(6.5, 10.5);

    // 7. Circadian Bedtime Window Calculation
    final wakeMinuteOfDay = (input.preferredWakeHour * 60) + input.preferredWakeMinute;
    final idealBedMinute = (wakeMinuteOfDay - (roundedDuration * 60).round() + 1440) % 1440;
    final bedStartMinute = (idealBedMinute - 15 + 1440) % 1440;
    final bedEndMinute = (idealBedMinute + 15 + 1440) % 1440;

    final bedStartStr = '${(bedStartMinute ~/ 60).toString().padLeft(2, '0')}:${(bedStartMinute % 60).toString().padLeft(2, '0')}';
    final bedEndStr = '${(bedEndMinute ~/ 60).toString().padLeft(2, '0')}:${(bedEndMinute % 60).toString().padLeft(2, '0')}';
    final wakeStr = '${input.preferredWakeHour.toString().padLeft(2, '0')}:${input.preferredWakeMinute.toString().padLeft(2, '0')}';
    final windowStr = '$bedStartStr - $wakeStr';

    final confidenceScore = input.recoveryState != null
        ? (input.recoveryState!.dataQualityScore * baseConfidence).clamp(0.3, 0.95)
        : baseConfidence;

    return SleepRecommendation(
      recommendedSleepDuration: roundedDuration,
      durationRangeMin: rangeMin,
      durationRangeMax: rangeMax,
      recommendedSleepWindow: windowStr,
      bedtimeStart: bedStartStr,
      bedtimeEnd: bedEndStr,
      targetWakeTime: wakeStr,
      sleepDebtHours: debt,
      reason: factors.isNotEmpty ? factors.first : 'circadian_baseline_homeostasis',
      contributingFactors: factors.isNotEmpty ? factors : ['baseline_homeostasis'],
      confidence: (confidenceScore * 100).round() / 100.0,
      modelVersion: modelVersion,
    );
  }
}

/// Sleep Recommendation Engine (SPEC.md Section 16)
class KineticSleepEngine {
  static SleepModel _activeModel = RuleBasedSleepModelV1();

  static String get version => _activeModel.modelVersion;

  /// Injects a custom sleep model
  static void setModel(SleepModel model) {
    _activeModel = model;
  }

  /// Resets to default rule-based sleep model
  static void resetModel() {
    _activeModel = RuleBasedSleepModelV1();
  }

  /// Computes personalized sleep need based on baseline, acute training load, sleep debt, and recovery state
  static SleepRecommendation calculateNeed({
    required double baselineSleepHours,
    required double sleepDebtHours,
    required double acuteTrainingLoad,
    required LatentPhysiologicalState recoveryState,
    double dailySteps = 8000,
    int preferredWakeHour = 7,
    int preferredWakeMinute = 0,
    bool routineDisrupted = false,
  }) {
    return _activeModel.calculateNeed(SleepEvaluationInput(
      baselineSleepHours: baselineSleepHours,
      sleepDebtHours: sleepDebtHours,
      acuteTrainingLoad: acuteTrainingLoad,
      recoveryState: recoveryState,
      dailySteps: dailySteps,
      preferredWakeHour: preferredWakeHour,
      preferredWakeMinute: preferredWakeMinute,
      routineDisrupted: routineDisrupted,
    ));
  }

  /// Evaluates sleep need directly from an evaluation input object
  static SleepRecommendation evaluate(SleepEvaluationInput input) {
    return _activeModel.calculateNeed(input);
  }
}
