/// Goal types supported by Kinetic Precision
enum GoalType {
  hypertrophy,
  strength,
  endurance,
  fatLoss,
  weightMaintenance,
  generalFitness,
  activeRecovery,
  custom,
}

/// Training focus preferences
enum TrainingFocus {
  hypertrophy,
  strength,
  endurance,
  power,
  hypertrophyStrengthHybrid,
  activeRecovery,
}

/// Primary movement patterns
enum MovementPattern {
  squat,
  hinge,
  horizontalPush,
  verticalPush,
  horizontalPull,
  verticalPull,
  lunge,
  carry,
  isolation,
  cardio,
  mobility,
}

/// Muscle groups
enum MuscleGroup {
  chest,
  back,
  quadriceps,
  hamstrings,
  glutes,
  shoulders,
  biceps,
  triceps,
  calves,
  core,
  fullBody,
  cardiovascular,
}

/// Data quality flags for measurements
enum DataQuality {
  observed,
  estimated,
  stale,
  missing,
  unreliable,
}

/// Direction of physiological trends
enum TrendDirection {
  improving,
  stable,
  declining,
  recovering,
  spiking,
}

/// Action types recommended by the decision engine
enum RecommendationAction {
  trainHard,
  trainNormal,
  trainLight,
  activeRecovery,
  rest,
  increaseLoad,
  increaseReps,
  maintainLoad,
  reduceLoad,
  reduceVolume,
  deload,
  sleepExtension,
  hydrateSurge,
  fuelSurge,
}

// ─────────────────────────────────────────────
//  DOMAIN MODELS
// ─────────────────────────────────────────────

class KineticUser {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? sex; // 'male', 'female', 'unspecified'
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String units; // 'metric' or 'imperial'
  final String timezone;
  final Map<String, dynamic> preferences;

  const KineticUser({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.sex,
    this.age,
    this.heightCm,
    this.weightKg,
    this.units = 'metric',
    this.timezone = 'UTC',
    this.preferences = const {},
  });

  KineticUser copyWith({
    String? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    String? units,
    String? timezone,
    Map<String, dynamic>? preferences,
  }) {
    return KineticUser(
      id: id,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      units: units ?? this.units,
      timezone: timezone ?? this.timezone,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserGoal {
  final String id;
  final String userId;
  final GoalType type;
  final int priority; // 1 = highest
  final double? targetValue;
  final String? targetMetric;
  final DateTime? deadline;
  final Map<String, dynamic> constraints;
  final bool isActive;

  const UserGoal({
    required this.id,
    required this.userId,
    required this.type,
    this.priority = 1,
    this.targetValue,
    this.targetMetric,
    this.deadline,
    this.constraints = const {},
    this.isActive = true,
  });
}

class Exercise {
  final String id;
  final String name;
  final MovementPattern movementPattern;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final List<String> equipment;
  final double defaultRestSeconds;
  final bool isCompound;

  const Exercise({
    required this.id,
    required this.name,
    required this.movementPattern,
    required this.primaryMuscles,
    this.secondaryMuscles = const [],
    this.equipment = const ['barbell', 'dumbbell'],
    this.defaultRestSeconds = 90,
    this.isCompound = true,
  });
}

class ExercisePrescription {
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final double targetLoadKg;
  final double targetRPE;
  final int restSeconds;
  final String tempo; // e.g. "3-1-1-0" (eccentric-pause-concentric-pause)
  final int priority;
  final String reasonCode;

  const ExercisePrescription({
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.targetLoadKg,
    this.targetRPE = 8.0,
    this.restSeconds = 90,
    this.tempo = '2-0-1-0',
    this.priority = 1,
    required this.reasonCode,
  });
}

class ExerciseSet {
  final int setNumber;
  final String exerciseId;
  final double prescribedLoadKg;
  final double actualLoadKg;
  final int prescribedReps;
  final int actualReps;
  final double targetRPE;
  final double actualRPE;
  final int restSeconds;
  final DateTime timestamp;
  final bool isCompleted;

  const ExerciseSet({
    required this.setNumber,
    required this.exerciseId,
    required this.prescribedLoadKg,
    required this.actualLoadKg,
    required this.prescribedReps,
    required this.actualReps,
    required this.targetRPE,
    required this.actualRPE,
    this.restSeconds = 90,
    required this.timestamp,
    this.isCompleted = true,
  });

  double get volumeKg => actualLoadKg * actualReps;
}

class WorkoutSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final GoalType goal;
  final TrainingFocus focus;
  final List<ExercisePrescription> prescriptions;
  final List<ExerciseSet> completedSets;
  final double? averageRPE;
  final double trainingLoad;
  final String status; // 'planned', 'in_progress', 'completed', 'cancelled'

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.goal,
    required this.focus,
    this.prescriptions = const [],
    this.completedSets = const [],
    this.averageRPE,
    this.trainingLoad = 0.0,
    this.status = 'planned',
  });

  double get totalVolumeKg =>
      completedSets.fold(0.0, (sum, set) => sum + set.volumeKg);
}

// ─────────────────────────────────────────────
//  GENERALIZED MEASUREMENT MODEL
// ─────────────────────────────────────────────

class Measurement {
  final String id;
  final String userId;
  final String metric; // 'hrv_rmssd', 'rhr', 'sleep_duration_hrs', 'weight_kg', 'steps', 'blood_pressure_sys', 'blood_pressure_dia', etc.
  final double value;
  final String unit;
  final DateTime timestamp;
  final String source; // 'sensor_ble', 'apple_health', 'oura', 'manual_entry', 'synthetic_sim'
  final DataQuality quality;
  final Map<String, dynamic> metadata;

  const Measurement({
    required this.id,
    required this.userId,
    required this.metric,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.source,
    this.quality = DataQuality.observed,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'metric': metric,
        'value': value,
        'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'quality': quality.name,
        'metadata': metadata,
      };
}

// ─────────────────────────────────────────────
//  IMMUTABLE EVENT MODEL
// ─────────────────────────────────────────────

abstract class KineticEventType {
  static const String workoutStarted = 'WorkoutStarted';
  static const String setCompleted = 'SetCompleted';
  static const String workoutCompleted = 'WorkoutCompleted';
  static const String sleepRecorded = 'SleepRecorded';
  static const String weightRecorded = 'WeightRecorded';
  static const String deviceMeasurementReceived = 'DeviceMeasurementReceived';
  static const String goalChanged = 'GoalChanged';
  static const String targetChanged = 'TargetChanged';
  static const String recommendationGenerated = 'RecommendationGenerated';
  static const String recommendationAccepted = 'RecommendationAccepted';
  static const String recommendationOverridden = 'RecommendationOverridden';
}

class KineticEvent {
  final String id;
  final String userId;
  final String eventType;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const KineticEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.timestamp,
    required this.payload,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'eventType': eventType,
        'timestamp': timestamp.toIso8601String(),
        'payload': payload,
      };
}

// ─────────────────────────────────────────────
//  PERSONAL BASELINE MODEL
// ─────────────────────────────────────────────

class PersonalBaseline {
  final String metric;
  final double mean;
  final double stdDev;
  final double min;
  final double max;
  final int sampleCount;
  final DateTime lastCalculated;

  const PersonalBaseline({
    required this.metric,
    required this.mean,
    required this.stdDev,
    required this.min,
    required this.max,
    required this.sampleCount,
    required this.lastCalculated,
  });

  double get value => mean;

  /// Standardized Z-Score deviation: (x - mean) / stdDev
  double zScore(double value) {
    if (stdDev.abs() < 1e-6) return 0.0;
    return (value - mean) / stdDev;
  }

  double computeZScoreDeviation(double value) => zScore(value);

  /// Percentage deviation: ((x - mean) / mean) * 100
  double percentageDeviation(double value) {
    if (mean.abs() < 1e-6) return 0.0;
    return ((value - mean) / mean) * 100.0;
  }

  double computePercentageDeviation(double value) => percentageDeviation(value);

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'mean': mean,
        'stdDev': stdDev,
        'min': min,
        'max': max,
        'sampleCount': sampleCount,
        'lastCalculated': lastCalculated.toIso8601String(),
      };
}

// ─────────────────────────────────────────────
//  LATENT PHYSIOLOGICAL STATES
// ─────────────────────────────────────────────

class LatentPhysiologicalState {
  final double recoveryScore; // 0.0 to 100.0
  final double fatigueScore; // 0.0 to 100.0
  final double readinessScore; // 0.0 to 100.0
  final double adaptationScore; // 0.0 to 100.0
  final double energyScore; // 0.0 to 100.0
  final TrendDirection direction;
  final List<String> contributingFactors;
  final double dataQualityScore; // 0.0 to 1.0
  final DateTime timestamp;
  final String modelVersion;

  const LatentPhysiologicalState({
    required this.recoveryScore,
    required this.fatigueScore,
    required this.readinessScore,
    required this.adaptationScore,
    required this.energyScore,
    required this.direction,
    required this.contributingFactors,
    required this.dataQualityScore,
    required this.timestamp,
    required this.modelVersion,
  });
}

// ─────────────────────────────────────────────
//  RECOMMENDATIONS & AUDIT TRACE
// ─────────────────────────────────────────────

class Recommendation {
  final String id;
  final String userId;
  final String type; // 'training', 'sleep', 'nutrition', 'recovery'
  final String action; // 'train_hard', 'train_normal', 'train_light', 'active_recovery', 'walk', 'rest'
  final int priority; // 1 = highest
  final String headline;
  final String rationale;
  final List<String> evidence;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String status; // 'pending', 'accepted', 'overridden', 'dismissed', 'completed'
  final String modelVersion;
  final Map<String, dynamic> payload;

  const Recommendation({
    required this.id,
    required this.userId,
    required this.type,
    required this.action,
    this.priority = 1,
    required this.headline,
    required this.rationale,
    required this.evidence,
    required this.createdAt,
    required this.expiresAt,
    this.status = 'pending',
    required this.modelVersion,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'type': type,
        'action': action,
        'priority': priority,
        'headline': headline,
        'rationale': rationale,
        'evidence': evidence,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'status': status,
        'modelVersion': modelVersion,
        'payload': payload,
      };
}

class RecommendationTrace {
  final String recommendationId;
  final String userId;
  final String modelVersion;
  final DateTime timestamp;
  final Map<String, dynamic> rawInputs;
  final Map<String, dynamic> derivedFeatures;
  final Map<String, dynamic> estimatedLatentState;
  final List<Map<String, dynamic>> candidateEvaluations;
  final String selectedDecision;
  final List<String> reasonCodes;

  const RecommendationTrace({
    required this.recommendationId,
    required this.userId,
    required this.modelVersion,
    required this.timestamp,
    required this.rawInputs,
    required this.derivedFeatures,
    required this.estimatedLatentState,
    required this.candidateEvaluations,
    required this.selectedDecision,
    required this.reasonCodes,
  });

  Map<String, dynamic> toJson() => {
        'recommendationId': recommendationId,
        'userId': userId,
        'modelVersion': modelVersion,
        'timestamp': timestamp.toIso8601String(),
        'rawInputs': rawInputs,
        'derivedFeatures': derivedFeatures,
        'estimatedLatentState': estimatedLatentState,
        'candidateEvaluations': candidateEvaluations,
        'selectedDecision': selectedDecision,
        'reasonCodes': reasonCodes,
      };
}

class UserOverride {
  final String id;
  final String recommendationId;
  final String userId;
  final RecommendationAction recommendedAction;
  final String userAction;
  final String overrideReason;
  final DateTime timestamp;
  final Map<String, dynamic> outcome;

  const UserOverride({
    required this.id,
    required this.recommendationId,
    required this.userId,
    required this.recommendedAction,
    required this.userAction,
    required this.overrideReason,
    required this.timestamp,
    this.outcome = const {},
  });
}
