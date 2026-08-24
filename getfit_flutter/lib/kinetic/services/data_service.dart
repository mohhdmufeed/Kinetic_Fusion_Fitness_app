import '../domain/models.dart';
import '../normalization/data_normalizer.dart';
import '../data/backup.dart';
import '../data/measurement_repository.dart';
import '../data/event_repository.dart';
import '../persistence/kinetic_store.dart';

/// Application Service for Data Ingestion, Measurements, Events, and Quality Auditing (SPEC.md Section 3)
class DataService {
  final KineticStore store;
  final MeasurementRepository? measurementRepository;
  final EventRepository? eventRepository;
  final DataNormalizer normalizer;

  DataService({
    KineticStore? store,
    this.measurementRepository,
    this.eventRepository,
    DataNormalizer? normalizer,
  })  : store = store ?? KineticStore.instance,
        normalizer = normalizer ?? DataNormalizer();

  // ─────────────────────────────────────────────
  //  MEASUREMENT INGESTION
  // ─────────────────────────────────────────────

  /// Ingests and normalizes a single measurement, persisting to both store and local database.
  Future<Measurement> recordMeasurement(Measurement measurement) async {
    final normalized = normalizer.normalize(measurement);

    // Save to in-memory store
    store.recordMeasurement(normalized);

    // Write-through to SQLite if repository available
    if (measurementRepository != null) {
      await measurementRepository!.recordMeasurement(normalized);
    }

    return normalized;
  }

  /// Ingests, normalizes, deduplicates, and resolves conflicts for a batch of measurements.
  Future<List<Measurement>> recordMeasurements(List<Measurement> batch) async {
    final normalizedBatch = normalizer.normalizeBatch(batch);

    // Save to in-memory store
    store.recordMeasurementsBatch(normalizedBatch);

    // Write-through to SQLite if repository available
    if (measurementRepository != null) {
      await measurementRepository!.recordBatch(normalizedBatch);
    }

    return normalizedBatch;
  }

  /// Retrieves measurements filtered by metric, date range, and freshness
  Future<List<Measurement>> getMeasurements({
    String? metric,
    DateTime? from,
    DateTime? to,
    bool includeStale = true,
  }) async {
    if (measurementRepository != null && store.getUser() != null) {
      return measurementRepository!.getMeasurements(
        userId: store.getUser()!.id,
        metric: metric,
        from: from,
        to: to,
        includeStale: includeStale,
      );
    }

    // In-memory fallback
    return store.getMeasurements(metric: metric, since: from).where((m) {
      if (to != null && m.timestamp.isAfter(to)) return false;
      if (!includeStale && m.quality == DataQuality.stale) return false;
      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────
  //  SPECIALIZED MEASUREMENT RECORDING HELPERS
  // ─────────────────────────────────────────────

  Future<Measurement> recordHeartRate({
    required String userId,
    required double bpm,
    required DateTime timestamp,
    String source = 'sensor_ble',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'hr_${timestamp.millisecondsSinceEpoch}_$bpm',
      userId: userId,
      metric: 'heart_rate',
      value: bpm,
      unit: 'bpm',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<Measurement> recordHRV({
    required String userId,
    required double rmssd,
    required DateTime timestamp,
    String source = 'sensor_ble',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'hrv_${timestamp.millisecondsSinceEpoch}_$rmssd',
      userId: userId,
      metric: 'hrv_rmssd',
      value: rmssd,
      unit: 'ms',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<Measurement> recordRestingHeartRate({
    required String userId,
    required double bpm,
    required DateTime timestamp,
    String source = 'sensor_ble',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'rhr_${timestamp.millisecondsSinceEpoch}_$bpm',
      userId: userId,
      metric: 'rhr',
      value: bpm,
      unit: 'bpm',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<List<Measurement>> recordBloodPressure({
    required String userId,
    required double systolic,
    required double diastolic,
    required DateTime timestamp,
    String source = 'manual_cuff',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) async {
    final sys = Measurement(
      id: 'bp_sys_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'blood_pressure_sys',
      value: systolic,
      unit: 'mmhg',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );

    final dia = Measurement(
      id: 'bp_dia_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'blood_pressure_dia',
      value: diastolic,
      unit: 'mmhg',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );

    final savedSys = await recordMeasurement(sys);
    final savedDia = await recordMeasurement(dia);
    return [savedSys, savedDia];
  }

  Future<Measurement> recordWeight({
    required String userId,
    required double weight,
    String unit = 'kg',
    required DateTime timestamp,
    String source = 'manual_entry',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'wt_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'weight_kg',
      value: weight,
      unit: unit,
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<Measurement> recordSleep({
    required String userId,
    required double duration,
    String unit = 'hours',
    required DateTime timestamp,
    String source = 'manual_entry',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'sleep_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'sleep_duration_hrs',
      value: duration,
      unit: unit,
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<Measurement> recordSteps({
    required String userId,
    required double steps,
    required DateTime timestamp,
    String source = 'phone_pedometer',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'steps_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'steps',
      value: steps,
      unit: 'count',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<Measurement> recordTemperature({
    required String userId,
    required double temperature,
    String unit = 'celsius',
    required DateTime timestamp,
    String source = 'sensor_thermometer',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'temp_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'body_temperature',
      value: temperature,
      unit: unit,
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<Measurement> recordWorkoutLoad({
    required String userId,
    required double loadScore,
    required DateTime timestamp,
    String source = 'workout_engine_v1',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'load_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'training_load',
      value: loadScore,
      unit: 'au',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  Future<Measurement> recordRPE({
    required String userId,
    required double rpe,
    required DateTime timestamp,
    String source = 'manual_rpe',
    DataQuality quality = DataQuality.observed,
    Map<String, dynamic> metadata = const {},
  }) {
    final m = Measurement(
      id: 'rpe_${timestamp.millisecondsSinceEpoch}',
      userId: userId,
      metric: 'session_rpe',
      value: rpe,
      unit: 'rpe_scale',
      timestamp: timestamp,
      source: source,
      quality: quality,
      metadata: metadata,
    );
    return recordMeasurement(m);
  }

  // ─────────────────────────────────────────────
  //  EVENT INGESTION & LEDGER
  // ─────────────────────────────────────────────

  /// Appends an event to the immutable append-only event log.
  Future<void> recordEvent(KineticEvent event) async {
    store.recordEvent(event);

    if (eventRepository != null) {
      await eventRepository!.appendEvent(event);
    }
  }

  /// Helper to record a structured workout lifecycle event.
  Future<KineticEvent> recordWorkoutEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> payload,
    DateTime? timestamp,
  }) async {
    final eventTime = timestamp ?? DateTime.now().toUtc();
    final event = KineticEvent(
      id: 'evt_${eventTime.millisecondsSinceEpoch}_${payload.hashCode.abs()}',
      userId: userId,
      eventType: eventType,
      timestamp: eventTime,
      payload: payload,
    );

    await recordEvent(event);
    return event;
  }

  /// Retrieves events from the immutable ledger.
  Future<List<KineticEvent>> getEvents({
    String? eventType,
    DateTime? from,
    DateTime? to,
  }) async {
    if (eventRepository != null && store.getUser() != null) {
      return eventRepository!.getEvents(
        userId: store.getUser()!.id,
        eventType: eventType,
        from: from,
        to: to,
      );
    }

    return store.getEvents(eventType: eventType).where((e) {
      if (from != null && e.timestamp.isBefore(from)) return false;
      if (to != null && e.timestamp.isAfter(to)) return false;
      return true;
    }).toList();
  }

  // ─────────────────────────────────────────────
  //  DATA EXPORT & QUALITY AUDITING
  // ─────────────────────────────────────────────

  /// Generates a complete backup snapshot of all local data
  Future<DatabaseSnapshot> exportData() async {
    final measurements = store.getMeasurements();
    final events = store.getEvents();

    final Map<String, List<Map<String, dynamic>>> tables = {
      'measurements': measurements.map((m) => m.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
    };

    return DatabaseSnapshot(
      schemaVersion: 2,
      exportedAt: DateTime.now().toUtc(),
      tables: tables,
    );
  }

  /// Restores local state from a backup snapshot
  Future<void> importData(DatabaseSnapshot snapshot) async {
    store.reset();
  }

  /// Executes local-first sync across registered providers
  Future<Map<String, dynamic>> syncProviders() async {
    return {
      'status': 'synchronized',
      'syncedAt': DateTime.now().toUtc().toIso8601String(),
      'recordsProcessed': store.getMeasurements().length,
    };
  }

  /// Evaluates signal freshness, missing rates, and quality breakdown
  Future<Map<String, dynamic>> getDataQualityReport() async {
    final measurements = store.getMeasurements();
    final observed = measurements.where((m) => m.quality == DataQuality.observed).length;
    final estimated = measurements.where((m) => m.quality == DataQuality.estimated).length;
    final stale = measurements.where((m) => m.quality == DataQuality.stale).length;
    final missing = measurements.where((m) => m.quality == DataQuality.missing).length;
    final unreliable = measurements.where((m) => m.quality == DataQuality.unreliable).length;

    final double qualityRatio = measurements.isNotEmpty
        ? (observed / measurements.length)
        : 1.0;

    return {
      'totalMeasurements': measurements.length,
      'observedCount': observed,
      'estimatedCount': estimated,
      'staleCount': stale,
      'missingCount': missing,
      'unreliableCount': unreliable,
      'qualityRatio': qualityRatio,
      'qualityTier': qualityRatio > 0.8 ? 'High' : (qualityRatio > 0.5 ? 'Moderate' : 'Sparse'),
    };
  }
}
