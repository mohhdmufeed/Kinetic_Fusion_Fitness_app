import 'dart:math';
import '../domain/models.dart';

/// Explicit multi-dimensional Latent Recovery State output matching SPEC.md sections 11-12
class RecoveryState {
  /// Structured state category: 'optimal', 'primed', 'recovering', 'fatigued', 'depleted'
  final String state;

  /// Trend trajectory: 'improving', 'stable', 'declining'
  final String direction;

  /// Explicit physiological and behavioral drivers
  final List<String> contributingFactors;

  /// Prescribed physiological action: 'train_hard', 'train_normal', 'train_light', 'active_recovery', 'rest'
  final String recommendedAction;

  /// Overall data freshness & quality: 'high', 'moderate', 'low', 'stale'
  final String dataQuality;

  /// Underlying continuous score breakdown (0.0 to 100.0)
  final double recoveryScore;
  final double readinessScore;
  final double fatigueScore;
  final double confidenceScore; // 0.0 to 1.0

  /// Semantic engine version identifier
  final String modelVersion;

  const RecoveryState({
    required this.state,
    required this.direction,
    required this.contributingFactors,
    required this.recommendedAction,
    required this.dataQuality,
    required this.recoveryScore,
    required this.readinessScore,
    required this.fatigueScore,
    required this.confidenceScore,
    required this.modelVersion,
  });

  String get statusCategory => state;
  double get confidence => confidenceScore;

  Map<String, dynamic> toJson() => {
        'state': state,
        'direction': direction,
        'contributingFactors': contributingFactors,
        'recommendedAction': recommendedAction,
        'dataQuality': dataQuality,
        'recoveryScore': recoveryScore,
        'readinessScore': readinessScore,
        'fatigueScore': fatigueScore,
        'confidenceScore': confidenceScore,
        'modelVersion': modelVersion,
      };
}

/// Raw physiological and behavioral inputs required to estimate latent recovery
class RecoveryEvaluationInput {
  final double? sleepDurationHours; // Nullable if sleep tracker was not worn
  final double sleepDebtHours; // Accumulated sleep deficit
  final double? hrvZScore; // Z-score deviation from personal HRV baseline (nullable if sensor missing)
  final double rhrDeltaBpm; // Difference from baseline RHR (positive = elevated/fatigued)
  final double acuteChronicWorkloadRatio; // ACWR (e.g. 0.8 to 1.5)
  final double recentAverageRPE; // Recent session RPE (1-10)
  final double weeklyVolumeLoadKg;
  final double volumeBaselineKg;
  final bool routineDisruption; // Jet lag, shift work, or abnormal bedtime
  final double environmentalStressScore; // 0.0 (ideal) to 1.0 (extreme heat/altitude)
  final DataQuality signalQuality; // Quality of input stream

  const RecoveryEvaluationInput({
    this.sleepDurationHours,
    this.sleepDebtHours = 0.0,
    this.hrvZScore,
    this.rhrDeltaBpm = 0.0,
    this.acuteChronicWorkloadRatio = 1.0,
    this.recentAverageRPE = 6.0,
    this.weeklyVolumeLoadKg = 1000.0,
    this.volumeBaselineKg = 1000.0,
    this.routineDisruption = false,
    this.environmentalStressScore = 0.0,
    this.signalQuality = DataQuality.observed,
  });
}

/// Abstraction for pluggable recovery models (Rule-Based, Bayesian, Kalman, State-Space)
abstract class RecoveryModel {
  String get modelVersion;
  RecoveryState estimate(RecoveryEvaluationInput input);
}

/// Transparent, deterministic rule-based recovery estimation model (v1.0)
class RuleBasedRecoveryModelV1 implements RecoveryModel {
  @override
  String get modelVersion => 'recovery_model_v1';

  @override
  RecoveryState estimate(RecoveryEvaluationInput input) {
    final List<String> contributingFactors = [];
    double confidenceMax = 1.0;

    // ── 1. Sleep Component ──
    double sleepScore = 70.0;
    double sleepWeight = 0.35;
    if (input.sleepDurationHours != null) {
      final sleepDur = input.sleepDurationHours!;
      if (sleepDur >= 8.0) {
        sleepScore = 100.0;
        contributingFactors.add('sleep_fully_restored');
      } else if (sleepDur >= 7.0) {
        sleepScore = 80.0 + ((sleepDur - 7.0) * 20.0);
      } else {
        sleepScore = max(0.0, 80.0 - ((7.0 - sleepDur) * 30.0));
        contributingFactors.add('acute_sleep_deficit');
      }

      if (input.sleepDebtHours > 2.0) {
        sleepScore = max(0.0, sleepScore - (input.sleepDebtHours * 10.0));
        contributingFactors.add('chronic_sleep_debt_accumulated');
      }
    } else {
      // Sleep signal missing
      sleepWeight = 0.0;
      confidenceMax = min(confidenceMax, 0.65);
      contributingFactors.add('sleep_signal_unavailable');
    }

    // ── 2. Autonomic Nervous System: HRV Component ──
    double hrvScore = 50.0;
    double hrvWeight = 0.30;
    if (input.hrvZScore != null) {
      final z = input.hrvZScore!;
      hrvScore = (50.0 + (z * 25.0)).clamp(0.0, 100.0);

      if (z >= 0.8) {
        contributingFactors.add('hrv_significantly_above_baseline');
      } else if (z <= -1.2) {
        contributingFactors.add('autonomic_sympathetic_strain_detected');
      }
    } else {
      // HRV signal missing
      hrvWeight = 0.0;
      confidenceMax = min(confidenceMax, 0.60);
      contributingFactors.add('hrv_signal_unavailable');
    }

    // ── 3. Resting Heart Rate Component ──
    double rhrScore = (100.0 - (input.rhrDeltaBpm * 8.0)).clamp(0.0, 100.0);
    double rhrWeight = 0.15;
    if (input.rhrDeltaBpm >= 4.0) {
      contributingFactors.add('resting_heart_rate_elevated');
    } else if (input.rhrDeltaBpm <= -2.0) {
      contributingFactors.add('resting_heart_rate_depressed_optimal');
    }

    // ── 4. Training Workload & Fatigue Component ──
    double workloadScore = 100.0;
    double fatigueScore = 20.0;
    double workloadWeight = 0.20;

    if (input.acuteChronicWorkloadRatio > 1.5) {
      workloadScore -= 40.0;
      fatigueScore += 50.0;
      contributingFactors.add('acute_workload_spike_exceeds_chronic');
    } else if (input.acuteChronicWorkloadRatio > 1.25) {
      workloadScore -= 15.0;
      fatigueScore += 25.0;
      contributingFactors.add('elevated_training_load');
    } else if (input.acuteChronicWorkloadRatio < 0.7) {
      workloadScore -= 10.0;
      contributingFactors.add('underload_taper_detected');
    }

    if (input.recentAverageRPE >= 8.5) {
      workloadScore -= 20.0;
      fatigueScore += 20.0;
      contributingFactors.add('high_perceived_exertion_recent_sessions');
    }

    // ── 5. Routine & Environmental Penalties ──
    if (input.routineDisruption) {
      sleepScore -= 15.0;
      contributingFactors.add('circadian_routine_disruption');
    }
    if (input.environmentalStressScore > 0.5) {
      workloadScore -= (input.environmentalStressScore * 20.0);
      contributingFactors.add('environmental_heat_altitude_stress');
    }

    // ── 6. Conflicting Signals Detection ──
    if (input.hrvZScore != null && input.hrvZScore! >= 0.8 && (input.acuteChronicWorkloadRatio > 1.5 || input.sleepDebtHours > 3.0)) {
      contributingFactors.add('conflicting_autonomic_signals_detected');
      // Parasympathetic saturation or acute fatigue offset
      hrvScore = max(50.0, hrvScore - 20.0);
    }

    // ── 7. Dynamic Normalization of Component Weights ──
    final totalWeight = sleepWeight + hrvWeight + rhrWeight + workloadWeight;
    double rawRecovery;
    if (totalWeight > 0) {
      rawRecovery = ((sleepScore * sleepWeight) +
              (hrvScore * hrvWeight) +
              (rhrScore * rhrWeight) +
              (workloadScore * workloadWeight)) /
          totalWeight;
    } else {
      rawRecovery = 50.0;
    }

    final double recoveryScore = (rawRecovery.clamp(0.0, 100.0) * 10).round() / 10.0;
    final double readinessScore = ((recoveryScore * 0.8) + ((100.0 - fatigueScore.clamp(0.0, 100.0)) * 0.2)).clamp(0.0, 100.0);

    // ── 8. Trajectory Direction ──
    String direction;
    final z = input.hrvZScore ?? 0.0;
    if (z >= 0.5 && input.sleepDebtHours <= 1.0) {
      direction = 'improving';
    } else if (z <= -0.8 || input.sleepDebtHours > 3.0 || input.acuteChronicWorkloadRatio > 1.4) {
      direction = 'declining';
    } else {
      direction = 'stable';
    }

    // ── 9. State Categorization & Action Prescription ──
    String state;
    String recommendedAction;

    if (recoveryScore >= 85.0) {
      state = 'optimal';
      recommendedAction = 'train_hard';
    } else if (recoveryScore >= 70.0) {
      state = 'primed';
      recommendedAction = 'train_normal';
    } else if (recoveryScore >= 55.0) {
      state = 'recovering';
      recommendedAction = 'train_light';
    } else if (recoveryScore >= 40.0) {
      state = 'fatigued';
      recommendedAction = 'active_recovery';
    } else {
      state = 'depleted';
      recommendedAction = 'rest';
    }

    // ── 10. Data Quality & Confidence Mapping ──
    String dataQuality;
    double baseConfidence;

    switch (input.signalQuality) {
      case DataQuality.observed:
        dataQuality = 'high';
        baseConfidence = 0.95;
        break;
      case DataQuality.estimated:
        dataQuality = 'moderate';
        baseConfidence = 0.75;
        break;
      case DataQuality.stale:
        dataQuality = 'stale';
        baseConfidence = 0.40;
        break;
      case DataQuality.missing:
      case DataQuality.unreliable:
        dataQuality = 'low';
        baseConfidence = 0.30;
        break;
    }

    final confidence = (min(baseConfidence, confidenceMax) * 100).round() / 100.0;

    return RecoveryState(
      state: state,
      direction: direction,
      contributingFactors: contributingFactors,
      recommendedAction: recommendedAction,
      dataQuality: (confidence < 0.7 && dataQuality == 'high') ? 'moderate' : dataQuality,
      recoveryScore: recoveryScore,
      readinessScore: (readinessScore * 10).round() / 10.0,
      fatigueScore: (fatigueScore.clamp(0.0, 100.0) * 10).round() / 10.0,
      confidenceScore: confidence,
      modelVersion: modelVersion,
    );
  }
}

/// Recovery Engine Facade providing unified access to the active recovery model
class KineticRecoveryEngine {
  static RecoveryModel _activeModel = RuleBasedRecoveryModelV1();

  static String get version => _activeModel.modelVersion;

  /// Injects a custom or updated recovery model (e.g. Bayesian / Kalman)
  static void setModel(RecoveryModel model) {
    _activeModel = model;
  }

  /// Resets to default rule-based model
  static void resetModel() {
    _activeModel = RuleBasedRecoveryModelV1();
  }

  /// Estimates latent recovery state from physiological and behavioral inputs
  static RecoveryState estimate(RecoveryEvaluationInput input) {
    return _activeModel.estimate(input);
  }

  /// Evaluates latent state object directly
  static RecoveryState evaluate(LatentPhysiologicalState state) {
    String action;
    String category;
    if (state.recoveryScore >= 85.0) {
      category = 'optimal';
      action = 'train_hard';
    } else if (state.recoveryScore >= 70.0) {
      category = 'primed';
      action = 'train_normal';
    } else if (state.recoveryScore >= 55.0) {
      category = 'recovering';
      action = 'train_light';
    } else if (state.recoveryScore >= 40.0) {
      category = 'fatigued';
      action = 'active_recovery';
    } else {
      category = 'depleted';
      action = 'rest';
    }

    return RecoveryState(
      state: category,
      direction: state.direction.name,
      contributingFactors: state.contributingFactors,
      recommendedAction: action,
      dataQuality: state.dataQualityScore >= 0.8 ? 'high' : 'moderate',
      recoveryScore: state.recoveryScore,
      readinessScore: state.readinessScore,
      fatigueScore: state.fatigueScore,
      confidenceScore: (state.dataQualityScore * 0.9 + 0.1).clamp(0.2, 1.0),
      modelVersion: _activeModel.modelVersion,
    );
  }
}
