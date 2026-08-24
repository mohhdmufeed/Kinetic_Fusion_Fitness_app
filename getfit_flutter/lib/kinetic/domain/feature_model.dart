import 'models.dart';
import '../math/time_series.dart';

/// Single versioned, deterministic feature extracted from raw time-series measurements
class KineticFeature<T> {
  final String name;
  final T value;
  final String source;
  final DateTime windowStart;
  final DateTime windowEnd;
  final String calculationVersion;
  final List<String> inputMetricIds;
  final DataQuality quality;
  final Map<String, dynamic> metadata;

  const KineticFeature({
    required this.name,
    required this.value,
    required this.source,
    required this.windowStart,
    required this.windowEnd,
    required this.calculationVersion,
    required this.inputMetricIds,
    this.quality = DataQuality.observed,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'value': value,
        'source': source,
        'windowStart': windowStart.toIso8601String(),
        'windowEnd': windowEnd.toIso8601String(),
        'calculationVersion': calculationVersion,
        'inputMetricIds': inputMetricIds,
        'quality': quality.name,
        'metadata': metadata,
      };
}

/// Immutable container of extracted features for a specific user and calculation window
class KineticFeatureSet {
  final String userId;
  final DateTime timestamp;
  final String version;
  final Map<String, KineticFeature> features;

  const KineticFeatureSet({
    required this.userId,
    required this.timestamp,
    required this.version,
    required this.features,
  });

  KineticFeature? getFeature(String name) => features[name];

  double? getDouble(String name) {
    final feat = features[name];
    if (feat == null) return null;
    if (feat.value is double) return feat.value as double;
    if (feat.value is num) return (feat.value as num).toDouble();
    return null;
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'version': version,
        'features': features.map((k, v) => MapEntry(k, v.toJson())),
      };
}

/// Standard deterministic time-series feature extractor
class TimeFeatureExtractor {
  static const String currentVersion = 'feature_extractor_v1.0';

  final String version;

  TimeFeatureExtractor({String? version})
      : version = version ?? currentVersion;

  /// Extracts versioned features deterministically from multi-metric measurements
  KineticFeatureSet extract({
    required String userId,
    required DateTime timestamp,
    required Map<String, List<Measurement>> measurements,
    Map<String, PersonalBaseline> baselines = const {},
  }) {
    final Map<String, KineticFeature> feats = {};
    final windowStart = timestamp.subtract(const Duration(days: 28));
    final windowEnd = timestamp;

    // 1. HRV 7-Day Rolling Mean & Baseline Z-Score
    final hrvList = measurements['hrv_rmssd'] ?? [];
    if (hrvList.isNotEmpty) {
      final hrvValues = hrvList.map((m) => m.value).toList();
      final rollingMean = TimeSeriesEngine.computeRollingMean(hrvValues, 7);
      final currentHRV = hrvValues.last;
      final hrvMean = rollingMean.isNotEmpty ? rollingMean.last : currentHRV;

      double hrvZ = 0.0;
      final baseline = baselines['hrv_rmssd'];
      if (baseline != null && baseline.stdDev > 0) {
        hrvZ = TimeSeriesEngine.computeZScore(currentHRV, baseline.mean, baseline.stdDev);
      }

      feats['hrv_rolling_7d'] = KineticFeature<double>(
        name: 'hrv_rolling_7d',
        value: (hrvMean * 100).round() / 100.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: hrvList.map((m) => m.id).toList(),
        quality: hrvList.last.quality,
      );

      feats['hrv_z_score'] = KineticFeature<double>(
        name: 'hrv_z_score',
        value: (hrvZ * 1000).round() / 1000.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: hrvList.map((m) => m.id).toList(),
        quality: hrvList.last.quality,
      );
    }

    // 2. Resting Heart Rate Delta & Trend
    final rhrList = measurements['rhr'] ?? [];
    if (rhrList.isNotEmpty) {
      final rhrValues = rhrList.map((m) => m.value).toList();
      final currentRHR = rhrValues.last;
      final baselineRHR = baselines['rhr']?.mean ?? 60.0;
      final rhrDelta = currentRHR - baselineRHR;
      final rhrTrend = TimeSeriesEngine.computeTrendSlope(rhrValues);

      feats['rhr_delta'] = KineticFeature<double>(
        name: 'rhr_delta',
        value: (rhrDelta * 100).round() / 100.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: rhrList.map((m) => m.id).toList(),
        quality: rhrList.last.quality,
      );

      feats['rhr_trend_slope'] = KineticFeature<double>(
        name: 'rhr_trend_slope',
        value: (rhrTrend * 1000).round() / 1000.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: rhrList.map((m) => m.id).toList(),
        quality: rhrList.last.quality,
      );
    }

    // 3. Sleep Debt & Sleep EWMA
    final sleepList = measurements['sleep_duration_hrs'] ?? [];
    if (sleepList.isNotEmpty) {
      final sleepValues = sleepList.map((m) => m.value).toList();
      final sleepEWMA = TimeSeriesEngine.computeEWMA(sleepValues, span: 7);
      final targetSleep = baselines['sleep_duration_hrs']?.mean ?? 8.0;
      final sleepDebt = (targetSleep - sleepEWMA).clamp(-2.0, 8.0);

      feats['sleep_ewma_7d'] = KineticFeature<double>(
        name: 'sleep_ewma_7d',
        value: (sleepEWMA * 100).round() / 100.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: sleepList.map((m) => m.id).toList(),
        quality: sleepList.last.quality,
      );

      feats['sleep_debt_hours'] = KineticFeature<double>(
        name: 'sleep_debt_hours',
        value: (sleepDebt * 100).round() / 100.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: sleepList.map((m) => m.id).toList(),
        quality: sleepList.last.quality,
      );
    }

    // 4. Acute & Chronic Training Load & ACWR
    final loadList = measurements['training_load'] ?? [];
    if (loadList.isNotEmpty) {
      final loadValues = loadList.map((m) => m.value).toList();
      final acuteLoad = TimeSeriesEngine.computeEWMA(
        loadValues.length > 7 ? loadValues.sublist(loadValues.length - 7) : loadValues,
        alpha: 0.25,
      );
      final chronicLoad = TimeSeriesEngine.computeEWMA(
        loadValues.length > 28 ? loadValues.sublist(loadValues.length - 28) : loadValues,
        alpha: 0.07,
      );
      final acwr = chronicLoad > 0.01 ? (acuteLoad / chronicLoad).clamp(0.1, 4.0) : 1.0;

      feats['acute_training_load'] = KineticFeature<double>(
        name: 'acute_training_load',
        value: (acuteLoad * 10).round() / 10.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: loadList.map((m) => m.id).toList(),
        quality: loadList.last.quality,
      );

      feats['chronic_training_load'] = KineticFeature<double>(
        name: 'chronic_training_load',
        value: (chronicLoad * 10).round() / 10.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: loadList.map((m) => m.id).toList(),
        quality: loadList.last.quality,
      );

      feats['acwr'] = KineticFeature<double>(
        name: 'acwr',
        value: (acwr * 100).round() / 100.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: loadList.map((m) => m.id).toList(),
        quality: loadList.last.quality,
      );
    }

    // 5. Weight Trend Slope
    final weightList = measurements['weight_kg'] ?? [];
    if (weightList.isNotEmpty) {
      final weightValues = weightList.map((m) => m.value).toList();
      final weightSlope = TimeSeriesEngine.computeTrendSlope(weightValues);

      feats['weight_trend_slope'] = KineticFeature<double>(
        name: 'weight_trend_slope',
        value: (weightSlope * 1000).round() / 1000.0,
        source: 'TimeSeriesEngine',
        windowStart: windowStart,
        windowEnd: windowEnd,
        calculationVersion: version,
        inputMetricIds: weightList.map((m) => m.id).toList(),
        quality: weightList.last.quality,
      );
    }

    return KineticFeatureSet(
      userId: userId,
      timestamp: timestamp,
      version: version,
      features: feats,
    );
  }
}
