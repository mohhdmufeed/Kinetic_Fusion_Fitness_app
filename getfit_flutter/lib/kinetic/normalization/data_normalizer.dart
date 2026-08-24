import '../domain/models.dart';

/// Source priority weights for conflict resolution (higher = higher confidence)
const Map<String, int> kDefaultSourcePriorities = {
  'sensor_ble_polar': 100,
  'sensor_chest_strap': 100,
  'oura_ring': 90,
  'whoop_strap': 85,
  'apple_health': 80,
  'google_fit': 75,
  'manual_entry': 50,
  'manual_cuff': 50,
  'metabolic_estimator_v1': 30,
  'synthetic_sim': 10,
};

/// Kinetic Precision Normalization Layer
/// Handles unit conversion, UTC timestamp alignment, deduplication, and source conflict resolution.
class DataNormalizer {
  final Map<String, int> sourcePriorities;

  DataNormalizer({Map<String, int>? customPriorities})
      : sourcePriorities = customPriorities ?? kDefaultSourcePriorities;

  /// Normalizes a single measurement (unit conversion & UTC timestamp)
  Measurement normalize(Measurement m) {
    double normalizedValue = m.value;
    String normalizedUnit = m.unit.trim().toLowerCase();

    // 1. Unit Normalization
    switch (normalizedUnit) {
      // Weight -> kg
      case 'lbs':
      case 'lb':
      case 'pounds':
        normalizedValue = m.value * 0.45359237;
        normalizedUnit = 'kg';
        break;
      case 'g':
      case 'grams':
        normalizedValue = m.value / 1000.0;
        normalizedUnit = 'kg';
        break;

      // Distance -> km
      case 'miles':
      case 'mi':
        normalizedValue = m.value * 1.609344;
        normalizedUnit = 'km';
        break;
      case 'meters':
      case 'm':
        normalizedValue = m.value / 1000.0;
        normalizedUnit = 'km';
        break;

      // Length / Height -> cm
      case 'inches':
      case 'in':
        normalizedValue = m.value * 2.54;
        normalizedUnit = 'cm';
        break;
      case 'feet':
      case 'ft':
        normalizedValue = m.value * 30.48;
        normalizedUnit = 'cm';
        break;

      // Energy -> kcal
      case 'kj':
      case 'kilojoules':
        normalizedValue = m.value / 4.184;
        normalizedUnit = 'kcal';
        break;

      // Duration -> hours
      case 'minutes':
      case 'min':
      case 'mins':
        normalizedValue = m.value / 60.0;
        normalizedUnit = 'hours';
        break;
      case 'seconds':
      case 'sec':
      case 's':
        normalizedValue = m.value / 3600.0;
        normalizedUnit = 'hours';
        break;

      // Temperature -> celsius
      case 'f':
      case 'fahrenheit':
      case '°f':
      case 'degf':
        normalizedValue = (m.value - 32.0) * 5.0 / 9.0;
        normalizedUnit = 'celsius';
        break;
      case 'c':
      case '°c':
      case 'degc':
        normalizedUnit = 'celsius';
        break;

      // Pressure -> mmHg
      case 'mmhg':
        normalizedUnit = 'mmhg';
        break;
    }

    // 2. Timestamp Normalization (UTC)
    final utcTimestamp = m.timestamp.toUtc();

    return Measurement(
      id: m.id,
      userId: m.userId,
      metric: m.metric,
      value: (normalizedValue * 10000).round() / 10000.0, // Precision rounding
      unit: normalizedUnit,
      timestamp: utcTimestamp,
      source: m.source,
      quality: m.quality,
      metadata: Map.from(m.metadata),
    );
  }

  /// Normalizes, sorts, deduplicates, and resolves source conflicts for a batch of measurements
  List<Measurement> normalizeBatch(
    List<Measurement> rawBatch, {
    Duration deduplicationWindow = const Duration(seconds: 60),
  }) {
    if (rawBatch.isEmpty) return [];

    // Step 1: Normalize all individual records
    final normalized = rawBatch.map((m) => normalize(m)).toList();

    // Step 2: Sort chronologically by UTC timestamp (handles out-of-order inputs)
    normalized.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Step 3: Deduplicate and resolve source priority conflicts
    final List<Measurement> resolved = [];

    for (final candidate in normalized) {
      // Find if there is an existing measurement for the same metric within the deduplication window
      final existingIndex = resolved.indexWhere((r) =>
          r.metric == candidate.metric &&
          r.timestamp.difference(candidate.timestamp).abs() <= deduplicationWindow);

      if (existingIndex == -1) {
        // No conflict, append candidate
        resolved.add(candidate);
      } else {
        // Conflict detected: resolve via source priority
        final existing = resolved[existingIndex];
        final existingScore = _getSourcePriority(existing.source);
        final candidateScore = _getSourcePriority(candidate.source);

        if (candidateScore > existingScore) {
          // Higher priority source wins, replace existing
          resolved[existingIndex] = candidate;
        }
        // If equal or lower, keep the existing one
      }
    }

    return resolved;
  }

  int _getSourcePriority(String source) {
    return sourcePriorities[source] ?? 20; // Default baseline priority
  }
}
