import '../domain/models.dart';
import 'data_normalizer.dart';

/// Physiological validation bounds for standard metrics
class MetricValidationRules {
  static const Map<String, (double min, double max)> validRanges = {
    'heart_rate': (25.0, 260.0),       // bpm
    'rhr': (25.0, 150.0),              // bpm
    'hrv_rmssd': (3.0, 300.0),         // ms
    'blood_pressure_sys': (50.0, 260.0), // mmHg
    'blood_pressure_dia': (30.0, 160.0), // mmHg
    'weight_kg': (20.0, 500.0),        // kg
    'sleep_duration_hrs': (0.0, 24.0), // hours
    'steps': (0.0, 150000.0),          // count
    'body_temperature': (30.0, 45.0),  // celsius
    'training_load': (0.0, 5000.0),    // arbitrary units
    'session_rpe': (1.0, 10.0),        // 1-10 Borg CR10
  };

  /// Checks whether [value] is within acceptable physiological bounds for [metric].
  static bool isValid(String metric, double value) {
    final range = validRanges[metric];
    if (range == null) return true; // Unknown metric, permit by default
    return value >= range.$1 && value <= range.$2;
  }
}

/// 5-Stage Normalization & Validation Pipeline
/// Pipeline Stage Flow:
/// 1. Provider Data Map / Payload
/// 2. Raw Observation (Raw Measurement)
/// 3. Normalized Observation (SI Units & UTC Timestamps)
/// 4. Validated Observation (Physiological Bounds Checking & Quality Tagging)
/// 5. Stored Measurement (Deduplicated, Conflict-Resolved, & Persisted)
class NormalizationPipeline {
  final DataNormalizer normalizer;

  NormalizationPipeline({DataNormalizer? normalizer})
      : normalizer = normalizer ?? DataNormalizer();

  /// Stage 1 -> 2: Converts raw provider map into a Raw Observation [Measurement]
  Measurement parseProviderData({
    required String id,
    required String userId,
    required String metric,
    required double rawValue,
    required String rawUnit,
    required DateTime rawTimestamp,
    required String source,
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    return Measurement(
      id: id,
      userId: userId,
      metric: metric,
      value: rawValue,
      unit: rawUnit,
      timestamp: rawTimestamp,
      source: source,
      quality: quality,
      metadata: Map.from(metadata),
    );
  }

  /// Stage 2 -> 3: Normalizes units and timestamps to standard internal representations (SI & UTC)
  Measurement normalizeObservation(Measurement raw) {
    return normalizer.normalize(raw);
  }

  /// Stage 3 -> 4: Validates physiological bounds and updates DataQuality if anomalous
  Measurement validateObservation(Measurement normalized) {
    final valid = MetricValidationRules.isValid(normalized.metric, normalized.value);
    if (!valid) {
      // Mark as unreliable if out of bounds, but retain the exact raw value
      return Measurement(
        id: normalized.id,
        userId: normalized.userId,
        metric: normalized.metric,
        value: normalized.value,
        unit: normalized.unit,
        timestamp: normalized.timestamp,
        source: normalized.source,
        quality: DataQuality.unreliable,
        metadata: {
          ...normalized.metadata,
          'validation_warning': 'Physiologically out of bounds',
          'original_quality': normalized.quality.name,
        },
      );
    }
    return normalized;
  }

  /// Full Pipeline Execution (Single Record):
  /// Provider Data / Raw -> Normalized -> Validated -> Stored Measurement
  Measurement process(Measurement raw) {
    final normalized = normalizeObservation(raw);
    return validateObservation(normalized);
  }

  /// Full Pipeline Execution (Batch):
  /// Ingests, normalizes, validates, deduplicates, and resolves source priority conflicts.
  List<Measurement> processBatch(
    List<Measurement> rawBatch, {
    Duration deduplicationWindow = const Duration(seconds: 60),
  }) {
    if (rawBatch.isEmpty) return [];

    // Stages 2 -> 3 -> 4: Normalize & Validate each observation
    final validatedList = rawBatch.map((raw) => process(raw)).toList();

    // Stage 5: Deduplicate and resolve source priority
    return normalizer.normalizeBatch(
      validatedList,
      deduplicationWindow: deduplicationWindow,
    );
  }
}
