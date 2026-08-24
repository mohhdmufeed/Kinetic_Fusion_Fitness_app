import '../domain/models.dart';
import '../math/baseline_calc.dart';
import '../math/time_series.dart';
import '../persistence/kinetic_store.dart';

/// Structured result describing a user's personal baseline
class BaselineResult {
  final String metric;
  final double mean;
  final double stdDev;
  final double min;
  final double max;
  final int sampleCount;
  final int windowDays;
  final double confidence; // 0.0 to 1.0
  final String calculationVersion;
  final DateTime timestamp;

  const BaselineResult({
    required this.metric,
    required this.mean,
    required this.stdDev,
    required this.min,
    required this.max,
    required this.sampleCount,
    required this.windowDays,
    required this.confidence,
    required this.calculationVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'mean': mean,
        'stdDev': stdDev,
        'min': min,
        'max': max,
        'sampleCount': sampleCount,
        'windowDays': windowDays,
        'confidence': confidence,
        'calculationVersion': calculationVersion,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Structured deviation of a current measurement from baseline
class BaselineDeviationResult {
  final String metric;
  final double currentValue;
  final double baselineMean;
  final double delta;
  final double zScore;
  final double percentageDeviation;
  final TrendDirection direction;
  final String status; // 'elevated', 'normal', 'suppressed'

  const BaselineDeviationResult({
    required this.metric,
    required this.currentValue,
    required this.baselineMean,
    required this.delta,
    required this.zScore,
    required this.percentageDeviation,
    required this.direction,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'currentValue': currentValue,
        'baselineMean': baselineMean,
        'delta': delta,
        'zScore': zScore,
        'percentageDeviation': percentageDeviation,
        'direction': direction.name,
        'status': status,
      };
}

/// Longitudinal trend analysis of baseline progression
class BaselineTrendResult {
  final String metric;
  final double slope;
  final TrendDirection direction;
  final int sampleCount;

  const BaselineTrendResult({
    required this.metric,
    required this.slope,
    required this.direction,
    required this.sampleCount,
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'slope': slope,
        'direction': direction.name,
        'sampleCount': sampleCount,
      };
}

/// Reusable application service for calculating, updating, and querying personal baselines
class BaselineService {
  static const String version = 'baseline_service_v1.0';

  final KineticStore store;

  BaselineService({KineticStore? store})
      : store = store ?? KineticStore.instance;

  /// Retrieves the adaptive baseline for a given metric and user
  BaselineResult getBaseline(String userId, String metric) {
    final baseline = store.getBaseline(metric);
    if (baseline == null) {
      return BaselineResult(
        metric: metric,
        mean: 0.0,
        stdDev: 1.0,
        min: 0.0,
        max: 0.0,
        sampleCount: 0,
        windowDays: 28,
        confidence: 0.0,
        calculationVersion: version,
        timestamp: DateTime.now().toUtc(),
      );
    }

    final confidence = (baseline.sampleCount / 14.0).clamp(0.1, 1.0);
    return BaselineResult(
      metric: baseline.metric,
      mean: baseline.mean,
      stdDev: baseline.stdDev,
      min: baseline.min,
      max: baseline.max,
      sampleCount: baseline.sampleCount,
      windowDays: 28,
      confidence: (confidence * 100).round() / 100.0,
      calculationVersion: version,
      timestamp: baseline.lastCalculated,
    );
  }

  /// Calculates statistical deviation (delta, z-score, percentage) of a current value against baseline
  BaselineDeviationResult getBaselineDeviation(
    String userId,
    String metric,
    double currentValue,
  ) {
    final baseline = store.getBaseline(metric);
    final mean = baseline?.mean ?? currentValue;
    final stdDev = baseline?.stdDev ?? 1.0;

    final delta = currentValue - mean;
    final zScore = (delta / (stdDev > 0 ? stdDev : 1.0));
    final pctDev = mean.abs() > 1e-6 ? (delta / mean) * 100.0 : 0.0;

    TrendDirection dir = TrendDirection.stable;
    String status = 'normal';

    if (zScore > 1.0) {
      dir = TrendDirection.improving;
      status = 'elevated';
    } else if (zScore < -1.0) {
      dir = TrendDirection.declining;
      status = 'suppressed';
    }

    return BaselineDeviationResult(
      metric: metric,
      currentValue: currentValue,
      baselineMean: mean,
      delta: (delta * 100).round() / 100.0,
      zScore: (zScore * 100).round() / 100.0,
      percentageDeviation: (pctDev * 10).round() / 10.0,
      direction: dir,
      status: status,
    );
  }

  /// Evaluates longitudinal adaptation trend of a metric over historical observations
  BaselineTrendResult getBaselineTrend(String userId, String metric) {
    final measurements = store.getMeasurements(metric: metric);
    if (measurements.length < 2) {
      return BaselineTrendResult(
        metric: metric,
        slope: 0.0,
        direction: TrendDirection.stable,
        sampleCount: measurements.length,
      );
    }

    final values = measurements.map((m) => m.value).toList();
    final slope = TimeSeriesEngine.computeTrendSlope(values);

    TrendDirection dir = TrendDirection.stable;
    if (slope > 0.01) {
      dir = TrendDirection.improving;
    } else if (slope < -0.01) {
      dir = TrendDirection.declining;
    }

    return BaselineTrendResult(
      metric: metric,
      slope: (slope * 1000).round() / 1000.0,
      direction: dir,
      sampleCount: measurements.length,
    );
  }

  /// Computes and saves adaptive baselines across all historical measurements
  Map<String, PersonalBaseline> updateBaselines(
    String userId,
    Map<String, List<Measurement>> history,
  ) {
    final Map<String, PersonalBaseline> updated = {};

    history.forEach((metric, measurements) {
      if (measurements.isNotEmpty) {
        final values = measurements.map((m) => m.value).toList();
        final baseline = BaselineEngine.computeBaseline(metric, values);
        store.saveBaseline(baseline);
        updated[metric] = baseline;
      }
    });

    return updated;
  }
}
