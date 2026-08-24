import 'dart:math';
import 'time_series.dart';

/// Container for session data passed to load calculation models
class TrainingSessionData {
  final double durationMinutes;
  final double? sessionRPE; // 1.0 to 10.0
  final List<Map<String, dynamic>> completedSets; // each map has {'reps': num, 'weightKg': num, 'rpe': num}
  final double? avgHeartRate;
  final double? restingHeartRate;
  final double? maxHeartRate;
  final bool isFemale;

  const TrainingSessionData({
    required this.durationMinutes,
    this.sessionRPE,
    this.completedSets = const [],
    this.avgHeartRate,
    this.restingHeartRate,
    this.maxHeartRate,
    this.isFemale = false,
  });
}

/// Pluggable interface for Training Load Models (SPEC.md Section 14)
abstract class TrainingLoadModel {
  String get modelId;
  String get displayName;
  String get unit;

  /// Calculates training load from session parameters
  double calculateSessionLoad(TrainingSessionData session);
}

/// 1. Resistance Volume Load Implementation: sum(reps * weightKg)
class VolumeLoadModel implements TrainingLoadModel {
  @override
  String get modelId => 'volume_load_v1';
  @override
  String get displayName => 'Tonnage / Volume Load';
  @override
  String get unit => 'kg';

  @override
  double calculateSessionLoad(TrainingSessionData session) {
    double total = 0.0;
    for (final s in session.completedSets) {
      final reps = (s['reps'] as num?)?.toDouble() ?? 0.0;
      final weight = (s['weightKg'] as num?)?.toDouble() ?? 0.0;
      total += reps * weight;
    }
    return total;
  }
}

/// 2. Foster Session-RPE (sRPE) Load Implementation: duration (minutes) * RPE
class RPEBasedLoadModel implements TrainingLoadModel {
  @override
  String get modelId => 'session_rpe_load_v1';
  @override
  String get displayName => 'Foster Session RPE Load';
  @override
  String get unit => 'AU'; // Arbitrary units

  @override
  double calculateSessionLoad(TrainingSessionData session) {
    final rpe = session.sessionRPE ?? 7.0;
    return session.durationMinutes * rpe.clamp(1.0, 10.0);
  }
}

/// 3. Banister TRIMP (Training Impulse) Implementation
class TRIMPHeartRateLoadModel implements TrainingLoadModel {
  @override
  String get modelId => 'trimp_hr_load_v1';
  @override
  String get displayName => 'Banister TRIMP';
  @override
  String get unit => 'TRIMP_AU';

  @override
  double calculateSessionLoad(TrainingSessionData session) {
    if (session.avgHeartRate == null ||
        session.restingHeartRate == null ||
        session.maxHeartRate == null) {
      return 0.0;
    }
    return TrainingLoadEngine.computeTRIMP(
      durationMinutes: session.durationMinutes,
      avgHR: session.avgHeartRate!,
      restingHR: session.restingHeartRate!,
      maxHR: session.maxHeartRate!,
      isFemale: session.isFemale,
    );
  }
}

/// Static Training Load Computation Engine
class TrainingLoadEngine {
  static const String version = 'training_load_engine_v1.0';

  /// Computes volume load
  static double computeVolumeLoad(List<Map<String, dynamic>> sets) {
    return VolumeLoadModel().calculateSessionLoad(TrainingSessionData(
      durationMinutes: 60,
      completedSets: sets,
    ));
  }

  /// Computes Foster Session RPE Load
  static double computeSessionRPELoad({
    required double durationMinutes,
    required double rpe,
  }) {
    return RPEBasedLoadModel().calculateSessionLoad(TrainingSessionData(
      durationMinutes: durationMinutes,
      sessionRPE: rpe,
    ));
  }

  /// Computes Acute:Chronic Workload Ratio (ACWR) using exponentially weighted moving averages
  /// Acute window = 7 days (alpha = 0.25), Chronic window = 28 days (alpha = 0.07)
  static double computeACWR(List<double> dailyLoads) {
    if (dailyLoads.isEmpty) return 1.0;

    final acuteDays = dailyLoads.length > 7
        ? dailyLoads.sublist(dailyLoads.length - 7)
        : dailyLoads;
    final acuteLoad = TimeSeriesEngine.computeEWMA(acuteDays, alpha: 0.25);

    final chronicDays = dailyLoads.length > 28
        ? dailyLoads.sublist(dailyLoads.length - 28)
        : dailyLoads;
    final chronicLoad = TimeSeriesEngine.computeEWMA(chronicDays, alpha: 0.07);

    if (chronicLoad < 1e-4) return 1.0;
    return (acuteLoad / chronicLoad).clamp(0.1, 3.5);
  }

  /// Computes Bannister's TRIMP (Training Impulse)
  static double computeTRIMP({
    required double durationMinutes,
    required double avgHR,
    required double restingHR,
    required double maxHR,
    bool isFemale = false,
  }) {
    if (maxHR <= restingHR) return 0.0;
    final hrRatio = ((avgHR - restingHR) / (maxHR - restingHR)).clamp(0.0, 1.0);
    final factor = isFemale ? 1.67 : 1.92;
    final y = 0.64 * exp(factor * hrRatio);
    return durationMinutes * hrRatio * y;
  }
}
