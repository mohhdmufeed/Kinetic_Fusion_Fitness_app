import '../../domain/models.dart';

enum HealthConnectAvailability {
  installed,
  notInstalled,
  notSupported,
}

enum HealthConnectPermissionStatus {
  notDetermined,
  authorized,
  denied,
  partiallyAuthorized,
}

/// Ingestion client for Android Health Connect conforming to the Kinetic measurement contract
class HealthConnectService {
  HealthConnectAvailability _availability = HealthConnectAvailability.installed;
  HealthConnectPermissionStatus _status = HealthConnectPermissionStatus.notDetermined;
  Set<String> _grantedTypes = {};

  HealthConnectAvailability get availability => _availability;
  HealthConnectPermissionStatus get permissionStatus => _status;
  Set<String> get grantedTypes => _grantedTypes;

  /// Checks if Health Connect is installed on Android device
  Future<HealthConnectAvailability> checkAvailability() async {
    return _availability;
  }

  /// Sets availability status explicitly for testing or device capability resolution
  void setAvailability(HealthConnectAvailability availability) {
    _availability = availability;
  }

  /// Alias for testing convenience
  void setAvailabilityForTesting(HealthConnectAvailability availability) {
    setAvailability(availability);
  }

  /// Sets permission status explicitly for testing or manual overrides
  void setPermissionStatus(HealthConnectPermissionStatus status, {Set<String>? grantedTypes}) {
    _status = status;
    if (grantedTypes != null) {
      _grantedTypes = grantedTypes;
    }
  }

  /// Alias for testing convenience
  void setPermissionStatusForTesting(HealthConnectPermissionStatus status, {Set<String>? grantedTypes}) {
    setPermissionStatus(status, grantedTypes: grantedTypes);
  }

  /// Requests permission from Health Connect
  Future<HealthConnectPermissionStatus> requestPermissions({List<String>? requestedTypes}) async {
    if (_availability != HealthConnectAvailability.installed) {
      _status = HealthConnectPermissionStatus.denied;
      return _status;
    }
    _grantedTypes = (requestedTypes ?? [
      'heart_rate',
      'hrv',
      'sleep',
      'steps',
      'active_energy',
      'workout',
    ]).toSet();
    _status = HealthConnectPermissionStatus.authorized;
    return _status;
  }

  /// Reads raw Health Connect physiological metrics for a given date range
  Future<List<Measurement>> readMetrics({
    required String userId,
    required DateTime start,
    required DateTime end,
    List<Map<String, dynamic>>? mockSamples,
  }) async {
    if (_availability != HealthConnectAvailability.installed ||
        _status == HealthConnectPermissionStatus.denied) {
      return [];
    }

    final List<Measurement> measurements = [];

    if (mockSamples != null) {
      for (final sample in mockSamples) {
        final metricType = sample['type'] as String;

        // If partially authorized and this specific type is not granted, skip gracefully
        if (_status == HealthConnectPermissionStatus.partiallyAuthorized && _grantedTypes.isNotEmpty) {
          final normalizedType = _normalizeType(metricType);
          if (!_grantedTypes.contains(normalizedType)) {
            continue;
          }
        }

        final value = (sample['value'] as num).toDouble();
        DateTime timestamp;
        if (sample['timestamp'] is DateTime) {
          timestamp = sample['timestamp'] as DateTime;
        } else if (sample['timestamp'] is String) {
          timestamp = DateTime.parse(sample['timestamp'] as String).toUtc();
        } else {
          timestamp = DateTime.now().toUtc();
        }
        final unit = sample['unit'] as String? ?? '';

        final mapped = mapSampleToMeasurement(
          userId: userId,
          type: metricType,
          value: value,
          timestamp: timestamp,
          unit: unit,
        );
        if (mapped != null) {
          measurements.add(mapped);
        }
      }
    }

    return measurements;
  }

  String _normalizeType(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('heartratevariability') || lower.contains('hrv')) return 'hrv';
    if (lower.contains('heartrate') || lower.contains('heart_rate')) return 'heart_rate';
    if (lower.contains('sleep')) return 'sleep';
    if (lower.contains('step')) return 'steps';
    if (lower.contains('energy') || lower.contains('calories')) return 'active_energy';
    if (lower.contains('workout') || lower.contains('exercise')) return 'workout';
    return lower;
  }

  /// Maps Android Health Connect records to normalized Kinetic Measurements (identical to HealthKit)
  Measurement? mapSampleToMeasurement({
    required String userId,
    required String type,
    required double value,
    required DateTime timestamp,
    required String unit,
  }) {
    final lower = type.toLowerCase();

    if (lower == 'heart_rate' ||
        lower == 'heartrate' ||
        lower == 'heartrateseriesrecord' ||
        lower == 'heartraterecord') {
      return Measurement(
        id: 'hc_hr_${timestamp.millisecondsSinceEpoch}',
        userId: userId,
        metric: 'rhr',
        value: value,
        unit: 'bpm',
        timestamp: timestamp,
        source: 'health_connect',
        quality: DataQuality.observed,
        metadata: {'platform': 'Android', 'type': 'HealthConnect'},
      );
    } else if (lower == 'hrv' ||
        lower == 'hrv_rmssd' ||
        lower == 'heartratevariabilityrmssdrecord' ||
        lower == 'heartratevariabilitysdnnrecord') {
      return Measurement(
        id: 'hc_hrv_${timestamp.millisecondsSinceEpoch}',
        userId: userId,
        metric: 'hrv_rmssd',
        value: value,
        unit: 'ms',
        timestamp: timestamp,
        source: 'health_connect',
        quality: DataQuality.observed,
        metadata: {'platform': 'Android', 'type': 'HealthConnect'},
      );
    } else if (lower == 'sleep' ||
        lower == 'sleepsessionrecord' ||
        lower == 'sleep_duration_hrs') {
      return Measurement(
        id: 'hc_sleep_${timestamp.millisecondsSinceEpoch}',
        userId: userId,
        metric: 'sleep_duration_hrs',
        value: value,
        unit: 'hours',
        timestamp: timestamp,
        source: 'health_connect',
        quality: DataQuality.observed,
        metadata: {'platform': 'Android', 'type': 'HealthConnect'},
      );
    } else if (lower == 'steps' ||
        lower == 'stepsrecord') {
      return Measurement(
        id: 'hc_steps_${timestamp.millisecondsSinceEpoch}',
        userId: userId,
        metric: 'steps',
        value: value,
        unit: 'count',
        timestamp: timestamp,
        source: 'health_connect',
        quality: DataQuality.observed,
        metadata: {'platform': 'Android', 'type': 'HealthConnect'},
      );
    } else if (lower == 'active_energy' ||
        lower == 'activecaloriesburnedrecord' ||
        lower == 'totalcaloriesburnedrecord') {
      return Measurement(
        id: 'hc_energy_${timestamp.millisecondsSinceEpoch}',
        userId: userId,
        metric: 'active_energy',
        value: value,
        unit: 'kcal',
        timestamp: timestamp,
        source: 'health_connect',
        quality: DataQuality.observed,
        metadata: {'platform': 'Android', 'type': 'HealthConnect'},
      );
    }

    return null;
  }
}
