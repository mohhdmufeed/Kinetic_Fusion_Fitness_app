import 'models.dart';

/// Qualitative level of latent physiological recovery
enum RecoveryLevel { optimal, moderate, compromised, exhausted }

/// Qualitative level of accumulated latent fatigue
enum FatigueLevel { low, moderate, high, critical }

/// Qualitative level of training stimulus adaptation
enum AdaptationLevel { peaking, adapting, overreaching, detraining }

/// Qualitative level of available perceived energetic reserve
enum EnergyLevel { high, moderate, low, depleted }

/// Qualitative level of functional neuromuscular performance
enum PerformanceLevel { peak, normal, diminished }

/// Qualitative level of training readiness
enum ReadinessLevel { train_hard, train_moderate, active_recovery, rest }

/// 1. Recovery State Estimation Model
class KineticRecoveryState {
  final RecoveryLevel level;
  final double score; // 0.0 to 100.0
  final TrendDirection direction;
  final double confidence; // 0.0 to 1.0
  final List<String> contributingFactors;
  final DataQuality dataQuality;
  final String calculationVersion;

  const KineticRecoveryState({
    required this.level,
    required this.score,
    required this.direction,
    required this.confidence,
    required this.contributingFactors,
    required this.dataQuality,
    required this.calculationVersion,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'score': score,
        'direction': direction.name,
        'confidence': confidence,
        'contributingFactors': contributingFactors,
        'dataQuality': dataQuality.name,
        'calculationVersion': calculationVersion,
      };
}

/// 2. Fatigue State Estimation Model
class KineticFatigueState {
  final FatigueLevel level;
  final double score; // 0.0 to 100.0
  final TrendDirection direction;
  final double acwr;
  final double confidence;
  final List<String> contributingFactors;
  final String calculationVersion;

  const KineticFatigueState({
    required this.level,
    required this.score,
    required this.direction,
    required this.acwr,
    required this.confidence,
    required this.contributingFactors,
    required this.calculationVersion,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'score': score,
        'direction': direction.name,
        'acwr': acwr,
        'confidence': confidence,
        'contributingFactors': contributingFactors,
        'calculationVersion': calculationVersion,
      };
}

/// 3. Training Adaptation State Estimation Model
class KineticAdaptationState {
  final AdaptationLevel level;
  final double score; // 0.0 to 100.0
  final TrendDirection direction;
  final double acuteLoad;
  final double chronicLoad;
  final List<String> contributingFactors;
  final String calculationVersion;

  const KineticAdaptationState({
    required this.level,
    required this.score,
    required this.direction,
    required this.acuteLoad,
    required this.chronicLoad,
    required this.contributingFactors,
    required this.calculationVersion,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'score': score,
        'direction': direction.name,
        'acuteLoad': acuteLoad,
        'chronicLoad': chronicLoad,
        'contributingFactors': contributingFactors,
        'calculationVersion': calculationVersion,
      };
}

/// 4. Energy State Estimation Model
class KineticEnergyState {
  final EnergyLevel level;
  final double score; // 0.0 to 100.0
  final TrendDirection direction;
  final double sleepDebtHours;
  final List<String> contributingFactors;
  final String calculationVersion;

  const KineticEnergyState({
    required this.level,
    required this.score,
    required this.direction,
    required this.sleepDebtHours,
    required this.contributingFactors,
    required this.calculationVersion,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'score': score,
        'direction': direction.name,
        'sleepDebtHours': sleepDebtHours,
        'contributingFactors': contributingFactors,
        'calculationVersion': calculationVersion,
      };
}

/// 5. Performance State Estimation Model
class KineticPerformanceState {
  final PerformanceLevel level;
  final double score; // 0.0 to 100.0
  final TrendDirection direction;
  final double estimatedRPECapacity;
  final List<String> contributingFactors;
  final String calculationVersion;

  const KineticPerformanceState({
    required this.level,
    required this.score,
    required this.direction,
    required this.estimatedRPECapacity,
    required this.contributingFactors,
    required this.calculationVersion,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'score': score,
        'direction': direction.name,
        'estimatedRPECapacity': estimatedRPECapacity,
        'contributingFactors': contributingFactors,
        'calculationVersion': calculationVersion,
      };
}

/// 6. Overall Readiness State Estimation Model
class KineticReadinessState {
  final ReadinessLevel level;
  final double compositeScore; // 0.0 to 100.0
  final TrendDirection direction;
  final double confidence;
  final List<String> primaryDrivers;
  final String calculationVersion;

  const KineticReadinessState({
    required this.level,
    required this.compositeScore,
    required this.direction,
    required this.confidence,
    required this.primaryDrivers,
    required this.calculationVersion,
  });

  Map<String, dynamic> toJson() => {
        'level': level.name,
        'compositeScore': compositeScore,
        'direction': direction.name,
        'confidence': confidence,
        'primaryDrivers': primaryDrivers,
        'calculationVersion': calculationVersion,
      };
}

/// Unified Composite Latent State grouping all estimated physiological dimensions
class CompositeLatentState {
  final String userId;
  final DateTime timestamp;
  final String modelVersion;
  final KineticRecoveryState recovery;
  final KineticFatigueState fatigue;
  final KineticAdaptationState adaptation;
  final KineticEnergyState energy;
  final KineticPerformanceState performance;
  final KineticReadinessState readiness;

  const CompositeLatentState({
    required this.userId,
    required this.timestamp,
    required this.modelVersion,
    required this.recovery,
    required this.fatigue,
    required this.adaptation,
    required this.energy,
    required this.performance,
    required this.readiness,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'modelVersion': modelVersion,
        'recovery': recovery.toJson(),
        'fatigue': fatigue.toJson(),
        'adaptation': adaptation.toJson(),
        'energy': energy.toJson(),
        'performance': performance.toJson(),
        'readiness': readiness.toJson(),
      };
}
