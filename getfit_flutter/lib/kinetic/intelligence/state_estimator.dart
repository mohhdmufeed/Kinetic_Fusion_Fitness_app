import '../domain/models.dart';
import '../domain/latent_states.dart';
import 'contracts.dart';
import 'feature_engine.dart';

/// Latent State Estimator converting normalized physiological features into latent states
class KineticStateEstimator implements StateEstimator<PhysiologicalFeatures, Map<String, dynamic>> {
  @override
  String get version => 'latent_state_estimator_v1.0';

  /// [deterministicTimestamp] must be supplied by callers that need
  /// reproducible output (tests, simulations). Defaults to DateTime.now()
  /// only at the outermost service boundary, never inside pure math.
  @override
  LatentPhysiologicalState estimateState(
    PhysiologicalFeatures features,
    Map<String, dynamic> context, {
    DateTime? deterministicTimestamp,
  }) {
    final composite = estimateCompositeState(
      features,
      userId: context['userId']?.toString() ?? 'anonymous',
      deterministicTimestamp: deterministicTimestamp,
    );

    return LatentPhysiologicalState(
      recoveryScore: composite.recovery.score,
      fatigueScore: composite.fatigue.score,
      readinessScore: composite.readiness.compositeScore,
      adaptationScore: composite.adaptation.score,
      energyScore: composite.energy.score,
      direction: composite.readiness.direction,
      contributingFactors: composite.readiness.primaryDrivers,
      dataQualityScore: composite.recovery.confidence,
      timestamp: composite.timestamp,
      modelVersion: version,
    );
  }

  /// Produces the complete, structured multi-dimensional latent state estimate
  CompositeLatentState estimateCompositeState(
    PhysiologicalFeatures features, {
    required String userId,
    DateTime? deterministicTimestamp,
  }) {
    final effectiveTimestamp = (deterministicTimestamp ?? DateTime.now()).toUtc();

    // ─────────────────────────────────────────────
    // 1. RECOVERY STATE
    // ─────────────────────────────────────────────
    final List<String> recoveryFactors = [];
    double hrvContribution = (features.hrvZScore * 15.0).clamp(-30.0, 30.0);
    if (features.hrvZScore > 0.5) {
      recoveryFactors.add('hrv_elevated_above_baseline');
    } else if (features.hrvZScore < -1.0) {
      recoveryFactors.add('hrv_suppressed');
    }

    double rhrContribution = (-features.rhrDeltaBpm * 3.0).clamp(-25.0, 20.0);
    if (features.rhrDeltaBpm > 3.0) {
      recoveryFactors.add('resting_hr_elevated');
    } else if (features.rhrDeltaBpm <= -2.0) {
      recoveryFactors.add('resting_hr_optimal');
    }

    double sleepContribution = (-features.sleepDebtHours * 8.0).clamp(-35.0, 15.0);
    if (features.sleepDebtHours > 1.5) {
      recoveryFactors.add('sleep_debt_accumulated');
    } else if (features.sleepDebtHours <= 0.0) {
      recoveryFactors.add('sleep_duration_restored');
    }

    final double recoveryScore = (70.0 + hrvContribution + rhrContribution + sleepContribution).clamp(10.0, 100.0);
    RecoveryLevel recoveryLevel;
    if (recoveryScore >= 80.0) {
      recoveryLevel = RecoveryLevel.optimal;
    } else if (recoveryScore >= 60.0) {
      recoveryLevel = RecoveryLevel.moderate;
    } else if (recoveryScore >= 35.0) {
      recoveryLevel = RecoveryLevel.compromised;
    } else {
      recoveryLevel = RecoveryLevel.exhausted;
    }

    final recoveryState = KineticRecoveryState(
      level: recoveryLevel,
      score: (recoveryScore * 10).round() / 10.0,
      direction: features.hrvZScore >= 0.2 ? TrendDirection.improving : (features.hrvZScore < -0.5 ? TrendDirection.declining : TrendDirection.stable),
      confidence: features.dataCompleteness.clamp(0.2, 1.0),
      contributingFactors: recoveryFactors.isNotEmpty ? recoveryFactors : ['parasympathetic_balance_stable'],
      dataQuality: features.dataCompleteness > 0.8 ? DataQuality.observed : DataQuality.estimated,
      calculationVersion: version,
    );

    // ─────────────────────────────────────────────
    // 2. FATIGUE STATE
    // ─────────────────────────────────────────────
    final List<String> fatigueFactors = [];
    double fatigueScore = 20.0;
    if (features.acwr > 1.4) {
      fatigueScore += (features.acwr - 1.4) * 40.0;
      fatigueFactors.add('acute_workload_spike');
    } else if (features.acwr < 0.8) {
      fatigueScore -= 10.0;
    }

    if (features.sleepDebtHours > 2.0) {
      fatigueScore += features.sleepDebtHours * 5.0;
      fatigueFactors.add('chronic_sleep_deprivation');
    }

    fatigueScore = fatigueScore.clamp(5.0, 100.0);
    FatigueLevel fatigueLevel;
    if (fatigueScore >= 75.0) {
      fatigueLevel = FatigueLevel.critical;
    } else if (fatigueScore >= 50.0) {
      fatigueLevel = FatigueLevel.high;
    } else if (fatigueScore >= 30.0) {
      fatigueLevel = FatigueLevel.moderate;
    } else {
      fatigueLevel = FatigueLevel.low;
    }

    final fatigueState = KineticFatigueState(
      level: fatigueLevel,
      score: (fatigueScore * 10).round() / 10.0,
      direction: features.acwr > 1.3 ? TrendDirection.declining : TrendDirection.stable,
      acwr: (features.acwr * 100).round() / 100.0,
      confidence: features.dataCompleteness,
      contributingFactors: fatigueFactors.isNotEmpty ? fatigueFactors : ['systemic_fatigue_nominal'],
      calculationVersion: version,
    );

    // ─────────────────────────────────────────────
    // 3. TRAINING ADAPTATION STATE
    // ─────────────────────────────────────────────
    final List<String> adaptationFactors = [];
    double adaptationScore = 75.0;
    if (features.chronicTrainingLoad > 200.0) {
      adaptationScore += 10.0;
      adaptationFactors.add('high_chronic_workload_base');
    }
    if (features.acwr > 1.6) {
      adaptationScore -= 20.0;
      adaptationFactors.add('overreaching_risk');
    }

    AdaptationLevel adaptLevel;
    if (features.acwr < 0.6 && features.chronicTrainingLoad < 80.0) {
      adaptLevel = AdaptationLevel.detraining;
      adaptationFactors.add('undertraining_stimulus');
    } else if (features.acwr > 1.5) {
      adaptLevel = AdaptationLevel.overreaching;
    } else if (recoveryScore >= 80.0 && features.chronicTrainingLoad > 150.0) {
      adaptLevel = AdaptationLevel.peaking;
      adaptationFactors.add('supercompensation_achieved');
    } else {
      adaptLevel = AdaptationLevel.adapting;
      adaptationFactors.add('progressive_adaptation_in_progress');
    }

    final adaptationState = KineticAdaptationState(
      level: adaptLevel,
      score: (adaptationScore.clamp(10.0, 100.0) * 10).round() / 10.0,
      direction: adaptLevel == AdaptationLevel.peaking ? TrendDirection.improving : TrendDirection.stable,
      acuteLoad: features.acuteTrainingLoad,
      chronicLoad: features.chronicTrainingLoad,
      contributingFactors: adaptationFactors,
      calculationVersion: version,
    );

    // ─────────────────────────────────────────────
    // 4. ENERGY STATE
    // ─────────────────────────────────────────────
    final List<String> energyFactors = [];
    double energyScore = (recoveryScore * 0.6 + features.sleepQualityScore * 0.4).clamp(10.0, 100.0);
    EnergyLevel energyLevel;
    if (energyScore >= 80.0) {
      energyLevel = EnergyLevel.high;
      energyFactors.add('vitality_optimal');
    } else if (energyScore >= 60.0) {
      energyLevel = EnergyLevel.moderate;
      energyFactors.add('functional_energy_reserves');
    } else if (energyScore >= 35.0) {
      energyLevel = EnergyLevel.low;
      energyFactors.add('energy_reserves_depleted');
    } else {
      energyLevel = EnergyLevel.depleted;
      energyFactors.add('severe_energy_deficit');
    }

    final energyState = KineticEnergyState(
      level: energyLevel,
      score: (energyScore * 10).round() / 10.0,
      direction: features.sleepDebtHours > 1.0 ? TrendDirection.declining : TrendDirection.stable,
      sleepDebtHours: features.sleepDebtHours,
      contributingFactors: energyFactors,
      calculationVersion: version,
    );

    // ─────────────────────────────────────────────
    // 5. PERFORMANCE STATE
    // ─────────────────────────────────────────────
    final List<String> perfFactors = [];
    double perfScore = (recoveryScore * 0.5 + (100.0 - fatigueScore) * 0.5).clamp(10.0, 100.0);
    PerformanceLevel perfLevel;
    if (perfScore >= 80.0 && recoveryLevel == RecoveryLevel.optimal) {
      perfLevel = PerformanceLevel.peak;
      perfFactors.add('neuromuscular_potentiation_high');
    } else if (perfScore >= 50.0) {
      perfLevel = PerformanceLevel.normal;
      perfFactors.add('standard_neuromuscular_capacity');
    } else {
      perfLevel = PerformanceLevel.diminished;
      perfFactors.add('central_nervous_fatigue');
    }

    final performanceState = KineticPerformanceState(
      level: perfLevel,
      score: (perfScore * 10).round() / 10.0,
      direction: perfLevel == PerformanceLevel.peak ? TrendDirection.improving : TrendDirection.stable,
      estimatedRPECapacity: (10.0 - (fatigueScore / 20.0)).clamp(4.0, 10.0),
      contributingFactors: perfFactors,
      calculationVersion: version,
    );

    // ─────────────────────────────────────────────
    // 6. READINESS STATE (COMPOSITE)
    // ─────────────────────────────────────────────
    final double readinessScore = (recoveryScore * 0.7 + (100.0 - fatigueScore) * 0.3).clamp(10.0, 100.0);
    ReadinessLevel readinessLevel;
    if (readinessScore >= 78.0) {
      readinessLevel = ReadinessLevel.train_hard;
    } else if (readinessScore >= 55.0) {
      readinessLevel = ReadinessLevel.train_moderate;
    } else if (readinessScore >= 35.0) {
      readinessLevel = ReadinessLevel.active_recovery;
    } else {
      readinessLevel = ReadinessLevel.rest;
    }

    TrendDirection readinessDirection = TrendDirection.stable;
    if (readinessScore >= 78.0 && features.hrvZScore >= 0.2) {
      readinessDirection = TrendDirection.improving;
    } else if (readinessScore < 50.0 || features.acwr > 1.5) {
      readinessDirection = TrendDirection.declining;
    }

    final List<String> primaryDrivers = [
      ...recoveryFactors,
      ...fatigueFactors,
    ];

    final readinessState = KineticReadinessState(
      level: readinessLevel,
      compositeScore: (readinessScore * 10).round() / 10.0,
      direction: readinessDirection,
      confidence: features.dataCompleteness,
      primaryDrivers: primaryDrivers.isNotEmpty ? primaryDrivers : ['balanced_homeostasis'],
      calculationVersion: version,
    );

    return CompositeLatentState(
      userId: userId,
      timestamp: effectiveTimestamp,
      modelVersion: version,
      recovery: recoveryState,
      fatigue: fatigueState,
      adaptation: adaptationState,
      energy: energyState,
      performance: performanceState,
      readiness: readinessState,
    );
  }
}
