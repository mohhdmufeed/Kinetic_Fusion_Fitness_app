import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/data/migration.dart';
import 'package:kinetic_precision/kinetic/data/database_manager.dart';
import 'package:kinetic_precision/kinetic/data/migrations/migration_v1_measurements_events.dart';
import 'package:kinetic_precision/kinetic/data/measurement_repository.dart';
import 'package:kinetic_precision/kinetic/data/event_repository.dart';
import 'package:kinetic_precision/kinetic/data/derived_state_repository.dart';
import 'package:kinetic_precision/kinetic/kinetic_core.dart';

void main() {
  late KineticDatabaseManager dbManager;
  late MeasurementRepository measurementRepo;
  late EventRepository eventRepo;
  late DerivedStateRepository derivedRepo;

  setUp(() async {
    final registry = MigrationRegistry();
    registry.register(MigrationV1MeasurementsEvents());
    registry.register(MigrationV2DomainModels());
    dbManager = KineticDatabaseManager.inMemory(registry: registry);
    await dbManager.migrateToLatest();

    measurementRepo = MeasurementRepository(dbManager.executor);
    eventRepo = EventRepository(dbManager.executor);
    derivedRepo = DerivedStateRepository(dbManager.executor);
  });

  tearDown(() async {
    await dbManager.close();
  });

  group('SPEC 5: Generalized Measurement System', () {
    test('Diverse metrics (HR, HRV, BP, Weight, Sleep, Steps, Load, RPE) store in the same table', () async {
      const userId = 'user_kinetic_01';
      final now = DateTime.now();

      final measurements = [
        Measurement(
          id: 'm_hr_1',
          userId: userId,
          metric: 'heart_rate',
          value: 142.0,
          unit: 'bpm',
          timestamp: now,
          source: 'sensor_ble_polar',
          quality: DataQuality.observed,
          metadata: {'context': 'interval_training'},
        ),
        Measurement(
          id: 'm_hrv_1',
          userId: userId,
          metric: 'hrv_rmssd',
          value: 68.5,
          unit: 'ms',
          timestamp: now,
          source: 'oura_ring',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'm_rhr_1',
          userId: userId,
          metric: 'rhr',
          value: 52.0,
          unit: 'bpm',
          timestamp: now,
          source: 'apple_health',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'm_bp_sys_1',
          userId: userId,
          metric: 'blood_pressure_systolic',
          value: 118.0,
          unit: 'mmHg',
          timestamp: now,
          source: 'manual_cuff',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'm_bp_dia_1',
          userId: userId,
          metric: 'blood_pressure_diastolic',
          value: 76.0,
          unit: 'mmHg',
          timestamp: now,
          source: 'manual_cuff',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'm_weight_1',
          userId: userId,
          metric: 'weight_kg',
          value: 82.4,
          unit: 'kg',
          timestamp: now,
          source: 'smart_scale_ble',
          quality: DataQuality.observed,
          metadata: {'body_fat_percent': 14.2},
        ),
        Measurement(
          id: 'm_sleep_1',
          userId: userId,
          metric: 'sleep_duration_hrs',
          value: 8.25,
          unit: 'hours',
          timestamp: now,
          source: 'whoop_strap',
          quality: DataQuality.observed,
          metadata: {'deep_sleep_hrs': 1.8, 'rem_sleep_hrs': 2.1},
        ),
        Measurement(
          id: 'm_steps_1',
          userId: userId,
          metric: 'steps',
          value: 11420.0,
          unit: 'steps',
          timestamp: now,
          source: 'phone_pedometer',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'm_load_1',
          userId: userId,
          metric: 'workout_load',
          value: 480.0,
          unit: 'au',
          timestamp: now,
          source: 'session_rpe_engine',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'm_rpe_1',
          userId: userId,
          metric: 'set_rpe',
          value: 8.5,
          unit: 'rpe_scale_10',
          timestamp: now,
          source: 'manual_user_log',
          quality: DataQuality.observed,
        ),
      ];

      // Insert all diverse metrics through the single unified model
      await measurementRepo.recordBatch(measurements);

      // Verify all 10 measurements are persisted in the single table
      final all = await measurementRepo.getMeasurements(userId: userId);
      expect(all.length, equals(10));

      // Query single metric
      final weight = await measurementRepo.getMeasurements(userId: userId, metric: 'weight_kg');
      expect(weight.length, equals(1));
      expect(weight.first.value, equals(82.4));
      expect(weight.first.metadata['body_fat_percent'], equals(14.2));

      final hrv = await measurementRepo.getMeasurements(userId: userId, metric: 'hrv_rmssd');
      expect(hrv.first.value, equals(68.5));
    });
  });

  group('SPEC 6: Data Quality Metadata', () {
    test('Measurements distinguish between observed, estimated, and stale data', () async {
      const userId = 'user_quality_test';
      final now = DateTime.now();

      // 1. Observed measurement (direct sensor)
      final observed = Measurement(
        id: 'q_obs',
        userId: userId,
        metric: 'rhr',
        value: 54.0,
        unit: 'bpm',
        timestamp: now,
        source: 'sensor_ble',
        quality: DataQuality.observed,
      );

      // 2. Estimated measurement (inferred by model)
      final estimated = Measurement(
        id: 'q_est',
        userId: userId,
        metric: 'active_calories',
        value: 620.0,
        unit: 'kcal',
        timestamp: now,
        source: 'metabolic_estimator_v1',
        quality: DataQuality.estimated,
      );

      // 3. Stale measurement (old sensor sync past freshness threshold)
      final stale = Measurement(
        id: 'q_stale',
        userId: userId,
        metric: 'weight_kg',
        value: 85.0,
        unit: 'kg',
        timestamp: now.subtract(const Duration(days: 14)),
        source: 'manual_entry',
        quality: DataQuality.stale,
      );

      await measurementRepo.recordBatch([observed, estimated, stale]);

      // Query all including stale
      final all = await measurementRepo.getMeasurements(userId: userId, includeStale: true);
      expect(all.length, equals(3));

      // Query excluding stale data
      final freshOnly = await measurementRepo.getMeasurements(userId: userId, includeStale: false);
      expect(freshOnly.length, equals(2));
      expect(freshOnly.any((m) => m.id == 'q_stale'), isFalse);

      // Inspect quality flags
      final fetchedEst = await measurementRepo.getById('q_est');
      expect(fetchedEst?.quality, equals(DataQuality.estimated));
    });
  });

  group('SPEC 7: Immutable Event-Based History Ledger', () {
    test('Events are recorded chronologically in an immutable append-only ledger', () async {
      const userId = 'user_event_test';
      final now = DateTime.now();

      final events = [
        KineticEvent(
          id: 'evt_1',
          userId: userId,
          eventType: 'WorkoutStarted',
          timestamp: now.subtract(const Duration(hours: 2)),
          payload: {'workout_type': 'hypertrophy_push', 'planned_sets': 12},
        ),
        KineticEvent(
          id: 'evt_2',
          userId: userId,
          eventType: 'SetCompleted',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
          payload: {'exercise': 'Barbell Bench Press', 'load_kg': 80.0, 'reps': 8, 'rpe': 8.0},
        ),
        KineticEvent(
          id: 'evt_3',
          userId: userId,
          eventType: 'WorkoutCompleted',
          timestamp: now.subtract(const Duration(hours: 1)),
          payload: {'duration_mins': 60, 'total_volume_kg': 2850.0},
        ),
        KineticEvent(
          id: 'evt_4',
          userId: userId,
          eventType: 'SleepRecorded',
          timestamp: now.subtract(const Duration(minutes: 30)),
          payload: {'duration_hours': 8.5, 'score': 92},
        ),
        KineticEvent(
          id: 'evt_5',
          userId: userId,
          eventType: 'GoalChanged',
          timestamp: now.subtract(const Duration(minutes: 15)),
          payload: {'old_goal': 'maintenance', 'new_goal': 'hypertrophy'},
        ),
        KineticEvent(
          id: 'evt_6',
          userId: userId,
          eventType: 'RecommendationGenerated',
          timestamp: now.subtract(const Duration(minutes: 5)),
          payload: {'rec_id': 'rec_99', 'action': 'trainHard'},
        ),
        KineticEvent(
          id: 'evt_7',
          userId: userId,
          eventType: 'RecommendationOverridden',
          timestamp: now,
          payload: {'rec_id': 'rec_99', 'user_action': 'rest', 'reason': 'traveling'},
        ),
      ];

      for (final evt in events) {
        await eventRepo.appendEvent(evt);
      }

      // Query complete event stream
      final stream = await eventRepo.getEvents(userId: userId);
      expect(stream.length, equals(7));
      expect(stream.first.eventType, equals('WorkoutStarted'));
      expect(stream.last.eventType, equals('RecommendationOverridden'));

      // Filter by specific event type
      final setEvents = await eventRepo.getEvents(userId: userId, eventType: 'SetCompleted');
      expect(setEvents.length, equals(1));
      expect(setEvents.first.payload['load_kg'], equals(80.0));
    });
  });

  group('SPEC 8: Enforcing RAW -> FEATURE -> ESTIMATE Layer Separation', () {
    test('Raw measurements remain strictly immutable when derived features and estimates are computed', () async {
      const userId = 'user_layer_separation';
      final now = DateTime.now();

      // 1. RAW LAYER: Insert original raw observations
      final rawHRV1 = Measurement(
        id: 'raw_hrv_day1',
        userId: userId,
        metric: 'hrv_rmssd',
        value: 70.0,
        unit: 'ms',
        timestamp: now.subtract(const Duration(days: 1)),
        source: 'sensor_ble',
      );
      final rawHRV2 = Measurement(
        id: 'raw_hrv_day2',
        userId: userId,
        metric: 'hrv_rmssd',
        value: 76.0,
        unit: 'ms',
        timestamp: now,
        source: 'sensor_ble',
      );

      await measurementRepo.recordBatch([rawHRV1, rawHRV2]);

      // 2. FEATURE LAYER: Compute derived feature and store in separate table
      final derivedFeature = DerivedFeature(
        id: 'feat_hrv_ewma',
        userId: userId,
        featureName: 'hrv_7d_ewma',
        value: 73.0,
        windowStart: now.subtract(const Duration(days: 7)),
        windowEnd: now,
        sourceRawIds: ['raw_hrv_day1', 'raw_hrv_day2'],
        calculatedAt: DateTime.now(),
      );

      await derivedRepo.saveFeature(derivedFeature);

      // 3. ESTIMATE LAYER: Compute latent recovery state and store in separate table
      final stateEstimate = StateEstimate(
        id: 'est_rec_today',
        userId: userId,
        stateName: 'recovery',
        score: 88.5,
        confidence: 0.95,
        contributingFactors: ['hrv_positive_deviation', 'sleep_restored'],
        estimatedAt: DateTime.now(),
        modelVersion: 'recovery_model_v1.0',
      );

      await derivedRepo.saveStateEstimate(stateEstimate);

      // 4. VERIFY STRICT SEPARATION & IMMUTABILITY:
      // Verify raw measurements table has exact original values and were NEVER overwritten
      final rawRecords = await measurementRepo.getMeasurements(userId: userId, metric: 'hrv_rmssd');
      expect(rawRecords.length, equals(2));
      expect(rawRecords[0].value, equals(70.0));
      expect(rawRecords[1].value, equals(76.0));

      // Verify derived feature exists in its own table
      final features = await derivedRepo.getFeatures(userId: userId, featureName: 'hrv_7d_ewma');
      expect(features.length, equals(1));
      expect(features.first.value, equals(73.0));
      expect(features.first.sourceRawIds, contains('raw_hrv_day1'));

      // Verify state estimate exists in its own table
      final estimates = await derivedRepo.getStateEstimates(userId: userId, stateName: 'recovery');
      expect(estimates.length, equals(1));
      expect(estimates.first.score, equals(88.5));
    });
  });
}
