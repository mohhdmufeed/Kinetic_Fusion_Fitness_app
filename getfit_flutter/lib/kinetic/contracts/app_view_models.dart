import '../domain/models.dart';
import '../intelligence/decision_engine.dart';

// Re-export core Today and Workout ViewModels for convenient UI consumption
export '../services/today_service.dart' show TodayViewModel;
export '../services/training_service.dart' show WorkoutViewModel;

/// Abstract base class for all strongly-typed application errors
sealed class KineticError {
  final String message;
  final String code;

  const KineticError({required this.message, required this.code});

  @override
  String toString() => '[$code] $message';
}

/// Validation error for invalid parameters (e.g. negative weights, empty user IDs)
class ValidationError extends KineticError {
  final String field;

  const ValidationError({required this.field, required super.message})
      : super(code: 'VALIDATION_ERROR');
}

/// Missing data error when requested entity or baseline cannot be located
class MissingDataError extends KineticError {
  final String resource;

  const MissingDataError({required this.resource, required super.message})
      : super(code: 'MISSING_DATA');
}

/// Stale data error when physiological observations exceed maximum freshness thresholds
class StaleDataError extends KineticError {
  final String metric;
  final Duration age;

  const StaleDataError({required this.metric, required this.age, required super.message})
      : super(code: 'STALE_DATA');
}

/// Invalid state transition error (e.g. logging a set without an active session)
class InvalidStateTransitionError extends KineticError {
  final String currentStatus;
  final String attemptedTransition;

  const InvalidStateTransitionError({
    required this.currentStatus,
    required this.attemptedTransition,
    required super.message,
  }) : super(code: 'INVALID_STATE_TRANSITION');
}

/// Storage error for disk or SQLite exceptions
class StoreError extends KineticError {
  final dynamic details;

  const StoreError({required super.message, this.details})
      : super(code: 'STORE_ERROR');
}

/// Strongly-typed Result wrapper for all Kinetic Precision application APIs
class KineticResult<T> {
  final T? _data;
  final KineticError? _error;

  const KineticResult.success(T data)
      : _data = data,
        _error = null;

  const KineticResult.failure(KineticError error)
      : _data = null,
        _error = error;

  bool get isSuccess => _error == null;
  bool get isFailure => _error != null;

  T get data {
    if (isFailure) {
      throw StateError('Cannot access data on KineticResult.failure: $_error');
    }
    return _data as T;
  }

  T? get dataOrNull => _data;
  KineticError? get errorOrNull => _error;

  R match<R>({
    required R Function(T data) onSuccess,
    required R Function(KineticError error) onFailure,
  }) {
    if (isSuccess) {
      return onSuccess(data);
    } else {
      return onFailure(_error!);
    }
  }
}

/// Application ViewModel for the current recommendation
class RecommendationViewModel {
  final String id;
  final String type;
  final String action;
  final int priority;
  final String headline;
  final String rationale;
  final List<String> evidence;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const RecommendationViewModel({
    required this.id,
    required this.type,
    required this.action,
    required this.priority,
    required this.headline,
    required this.rationale,
    required this.evidence,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory RecommendationViewModel.fromDomain(Recommendation r) => RecommendationViewModel(
        id: r.id,
        type: r.type,
        action: r.action,
        priority: r.priority,
        headline: r.headline,
        rationale: r.rationale,
        evidence: r.evidence,
        status: r.status,
        createdAt: r.createdAt,
        expiresAt: r.expiresAt,
      );
}

/// Application ViewModel for the WHY Explanation screen
class WhyViewModel {
  final String recommendationId;
  final String selectedDecision;
  final List<String> reasonCodes;
  final List<CandidateActionEvaluation> competingOptionsEvaluated;
  final Map<String, dynamic> estimatedLatentState;
  final Map<String, dynamic> derivedFeatures;
  final String modelVersion;
  final DateTime timestamp;

  const WhyViewModel({
    required this.recommendationId,
    required this.selectedDecision,
    required this.reasonCodes,
    required this.competingOptionsEvaluated,
    required this.estimatedLatentState,
    required this.derivedFeatures,
    required this.modelVersion,
    required this.timestamp,
  });

  factory WhyViewModel.fromTrace(RecommendationTrace trace) {
    final candidateEvals = trace.candidateEvaluations.map((json) => CandidateActionEvaluation(
          action: json['action'] as String? ?? 'unknown',
          utilityScore: (json['utilityScore'] as num?)?.toDouble() ?? 0.0,
          isEligible: json['isEligible'] as bool? ?? false,
          rationale: json['rationale'] as String? ?? '',
        )).toList();

    return WhyViewModel(
      recommendationId: trace.recommendationId,
      selectedDecision: trace.selectedDecision,
      reasonCodes: trace.reasonCodes,
      competingOptionsEvaluated: candidateEvals,
      estimatedLatentState: trace.estimatedLatentState,
      derivedFeatures: trace.derivedFeatures,
      modelVersion: trace.modelVersion,
      timestamp: trace.timestamp,
    );
  }
}

/// Application ViewModel for the next upcoming exercise set
class NextSetViewModel {
  final int prescriptionIndex;
  final int setNumber;
  final String exerciseId;
  final String exerciseName;
  final double targetLoadKg;
  final int targetReps;
  final double targetRPE;
  final int restSeconds;
  final bool isLastSetOfExercise;
  final bool isLastSetOfWorkout;

  const NextSetViewModel({
    required this.prescriptionIndex,
    required this.setNumber,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetLoadKg,
    required this.targetReps,
    required this.targetRPE,
    required this.restSeconds,
    required this.isLastSetOfExercise,
    required this.isLastSetOfWorkout,
  });
}

/// Application ViewModel for the current latent physiological recovery state
class RecoveryStateViewModel {
  final double recoveryScore;
  final double readinessScore;
  final double fatigueScore;
  final double adaptationScore;
  final double energyScore;
  final TrendDirection direction;
  final List<String> contributingFactors;
  final double confidenceScore;
  final DateTime timestamp;

  const RecoveryStateViewModel({
    required this.recoveryScore,
    required this.readinessScore,
    required this.fatigueScore,
    required this.adaptationScore,
    required this.energyScore,
    required this.direction,
    required this.contributingFactors,
    required this.confidenceScore,
    required this.timestamp,
  });

  factory RecoveryStateViewModel.fromDomain(LatentPhysiologicalState s) => RecoveryStateViewModel(
        recoveryScore: s.recoveryScore,
        readinessScore: s.readinessScore,
        fatigueScore: s.fatigueScore,
        adaptationScore: s.adaptationScore,
        energyScore: s.energyScore,
        direction: s.direction,
        contributingFactors: s.contributingFactors,
        confidenceScore: s.dataQualityScore,
        timestamp: s.timestamp,
      );
}

/// Application ViewModel for body composition and trajectory
class BodyTrajectoryViewModel {
  final double currentWeightKg;
  final double? targetWeightKg;
  final double weeklyWeightSlopeKg;
  final double? projectedEtaWeeks;
  final String trendDirection; // 'losing', 'gaining', 'stable'
  final DateTime lastMeasured;

  const BodyTrajectoryViewModel({
    required this.currentWeightKg,
    this.targetWeightKg,
    required this.weeklyWeightSlopeKg,
    this.projectedEtaWeeks,
    required this.trendDirection,
    required this.lastMeasured,
  });
}

/// Application ViewModel for daily physiological and behavioral targets
class TargetsViewModel {
  final int dailyStepsTarget;
  final double targetCaloriesKcal;
  final double targetProteinGrams;
  final double targetSleepDurationHours;
  final String recommendedBedtimeWindow;

  const TargetsViewModel({
    required this.dailyStepsTarget,
    required this.targetCaloriesKcal,
    required this.targetProteinGrams,
    required this.targetSleepDurationHours,
    required this.recommendedBedtimeWindow,
  });
}

/// Application ViewModel for telemetry and audit summary
class TelemetryViewModel {
  final int totalEventsRecorded;
  final int totalMeasurementsRecorded;
  final int totalWorkoutsLogged;
  final int totalTracesStored;
  final String dataStorageMode; // 'Local-Only (Zero Cloud)'
  final DateTime lastAuditTimestamp;

  const TelemetryViewModel({
    required this.totalEventsRecorded,
    required this.totalMeasurementsRecorded,
    required this.totalWorkoutsLogged,
    required this.totalTracesStored,
    required this.dataStorageMode,
    required this.lastAuditTimestamp,
  });
}
