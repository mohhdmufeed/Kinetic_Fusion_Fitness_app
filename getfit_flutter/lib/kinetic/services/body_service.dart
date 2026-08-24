import '../domain/models.dart';
import '../math/time_series.dart';
import '../math/baseline_calc.dart';
import '../persistence/kinetic_store.dart';

/// Body composition and weight trajectory view model
class BodyTrajectoryViewModel {
  final double currentWeightKg;
  final double baselineWeightKg;
  final double weightVelocityKgPerWeek;
  final double? targetWeightKg;
  final String trendDirection; // 'losing', 'maintaining', 'gaining'
  final List<Measurement> history;

  const BodyTrajectoryViewModel({
    required this.currentWeightKg,
    required this.baselineWeightKg,
    required this.weightVelocityKgPerWeek,
    this.targetWeightKg,
    required this.trendDirection,
    required this.history,
  });

  Map<String, dynamic> toJson() => {
        'currentWeightKg': currentWeightKg,
        'baselineWeightKg': baselineWeightKg,
        'weightVelocityKgPerWeek': weightVelocityKgPerWeek,
        'targetWeightKg': targetWeightKg,
        'trendDirection': trendDirection,
      };
}

/// Application Service for Body Composition, Weight Tracking & Trajectory (SPEC.md Section 3)
class BodyService {
  final KineticStore store;

  BodyService({KineticStore? store}) : store = store ?? KineticStore.instance;

  /// 1. getBodyTrajectory(): Computes weight velocity, slope, and goal progress
  Future<BodyTrajectoryViewModel> getBodyTrajectory() async {
    final weightMeasurements = store.getMeasurements(metric: 'weight_kg');
    final user = store.getUser();
    final goals = store.getGoals();
    final weightGoal = goals.where((g) => g.targetMetric == 'weight_kg').firstOrNull;

    final values = weightMeasurements.map((m) => m.value).toList();
    final currentWeight = values.isNotEmpty ? values.last : (user?.weightKg ?? 75.0);

    final baseline = BaselineEngine.computeBaseline('weight_kg', values.isNotEmpty ? values : [currentWeight]);
    final slopePerDay = values.length >= 2 ? TimeSeriesEngine.computeTrendSlope(values) : 0.0;
    final weeklyVelocity = (slopePerDay * 7.0 * 100).round() / 100.0;

    String direction = 'maintaining';
    if (weeklyVelocity < -0.15) {
      direction = 'losing';
    } else if (weeklyVelocity > 0.15) {
      direction = 'gaining';
    }

    return BodyTrajectoryViewModel(
      currentWeightKg: currentWeight,
      baselineWeightKg: baseline.mean,
      weightVelocityKgPerWeek: weeklyVelocity,
      targetWeightKg: weightGoal?.targetValue,
      trendDirection: direction,
      history: weightMeasurements,
    );
  }

  /// 2. logWeight(): Records an observed bodyweight measurement
  Future<void> logWeight({
    required double weightKg,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final user = store.getUser();
    final userId = user?.id ?? 'default_user';

    store.recordMeasurement(Measurement(
      id: 'meas_weight_${now.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'weight_kg',
      value: weightKg,
      unit: 'kg',
      timestamp: now,
      source: 'manual_log',
      quality: DataQuality.observed,
    ));

    store.recordEvent(KineticEvent(
      id: 'evt_weight_${now.millisecondsSinceEpoch}',
      userId: userId,
      eventType: 'WeightRecorded',
      timestamp: now,
      payload: {'weightKg': weightKg},
    ));
  }

  /// 3. getWeightHistory(): Retrieves chronological weight measurements
  Future<List<Measurement>> getWeightHistory({int days = 90}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    return store.getMeasurements(metric: 'weight_kg', since: since);
  }

  /// 4. getCompositionEstimates(): Estimates fat mass and lean mass from body state
  Future<Map<String, double>> getCompositionEstimates() async {
    final trajectory = await getBodyTrajectory();
    final weight = trajectory.currentWeightKg;

    // Approximate lean mass and fat mass baseline estimates
    const estBodyFat = 18.0;
    final fatMass = weight * (estBodyFat / 100.0);
    final leanMass = weight - fatMass;

    return {
      'weightKg': weight,
      'bodyFatPercent': estBodyFat,
      'fatMassKg': (fatMass * 10).round() / 10.0,
      'leanMassKg': (leanMass * 10).round() / 10.0,
    };
  }
}
