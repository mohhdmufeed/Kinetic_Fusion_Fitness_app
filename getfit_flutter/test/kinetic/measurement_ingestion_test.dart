import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:kinetic_precision/kinetic/kinetic_core.dart';
import 'package:kinetic_precision/kinetic/data/database_manager.dart';
import 'package:kinetic_precision/kinetic/data/migration.dart';
import 'package:kinetic_precision/kinetic/data/migrations/migration_v1_measurements_events.dart';
import 'package:kinetic_precision/kinetic/data/measurement_repository.dart';
import 'package:kinetic_precision/kinetic/data/event_repository.dart';
import 'package:kinetic_precision/kinetic/services/data_service.dart';

void main() {
  group('Phase 2: Measurement & Event Ingestion Integration Tests', () {
    late KineticDatabaseManager dbManager;
    late MigrationRegistry registry;
    late MeasurementRepository measurementRepo;
    late EventRepository eventRepo;
    late DataService dataService;

    setUp(() async {
      registry = MigrationRegistry();
      registry.register(MigrationV1MeasurementsEvents());
      registry.register(MigrationV2DomainModels());

      dbManager = KineticDatabaseManager.inMemory(registry: registry);
      await dbManager.initialize();
      await dbManager.migrateToLatest();

      measurementRepo = MeasurementRepository(dbManager.executor);
      eventRepo = EventRepository(dbManager.executor);

      final store = KineticStore.instance..reset();
      store.saveUser(KineticUser(
        id: 'user_ingest_test',
        createdAt: DateTime.utc(2026, 8, 18, 12, 0),
        updatedAt: DateTime.utc(2026, 8, 18, 12, 0),
      ));

      dataService = DataService(
        store: store,
        measurementRepository: measurementRepo,
        eventRepository: eventRepo,
      );
    });

    tearDown(() async {
      await dbManager.close();
    });

    test('1. Valid Measurements across all 10 Initial Metrics', () async {
      final now = DateTime.utc(2026, 8, 18, 12, 0);

      // 1. Heart Rate
      final hr = await dataService.recordHeartRate(
        userId: 'user_ingest_test',
        bpm: 145.0,
        timestamp: now,
      );
      expect(hr.metric, equals('heart_rate'));
      expect(hr.value, equals(145.0));
      expect(hr.unit, equals('bpm'));

      // 2. HRV (rmssd)
      final hrv = await dataService.recordHRV(
        userId: 'user_ingest_test',
        rmssd: 68.5,
        timestamp: now,
      );
      expect(hrv.metric, equals('hrv_rmssd'));
      expect(hrv.value, equals(68.5));
      expect(hrv.unit, equals('ms'));

      // 3. Resting Heart Rate
      final rhr = await dataService.recordRestingHeartRate(
        userId: 'user_ingest_test',
        bpm: 54.0,
        timestamp: now,
      );
      expect(rhr.metric, equals('rhr'));
      expect(rhr.value, equals(54.0));

      // 4. Blood Pressure (systolic & diastolic)
      final bp = await dataService.recordBloodPressure(
        userId: 'user_ingest_test',
        systolic: 118.0,
        diastolic: 76.0,
        timestamp: now,
      );
      expect(bp.length, equals(2));
      expect(bp[0].metric, equals('blood_pressure_sys'));
      expect(bp[0].value, equals(118.0));
      expect(bp[1].metric, equals('blood_pressure_dia'));
      expect(bp[1].value, equals(76.0));

      // 5. Weight
      final wt = await dataService.recordWeight(
        userId: 'user_ingest_test',
        weight: 78.4,
        unit: 'kg',
        timestamp: now,
      );
      expect(wt.metric, equals('weight_kg'));
      expect(wt.value, equals(78.4));

      // 6. Sleep Duration
      final sleep = await dataService.recordSleep(
        userId: 'user_ingest_test',
        duration: 7.8,
        unit: 'hours',
        timestamp: now,
      );
      expect(sleep.metric, equals('sleep_duration_hrs'));
      expect(sleep.value, equals(7.8));

      // 7. Steps
      final steps = await dataService.recordSteps(
        userId: 'user_ingest_test',
        steps: 10420.0,
        timestamp: now,
      );
      expect(steps.metric, equals('steps'));
      expect(steps.value, equals(10420.0));

      // 8. Body Temperature
      final temp = await dataService.recordTemperature(
        userId: 'user_ingest_test',
        temperature: 36.8,
        unit: 'celsius',
        timestamp: now,
      );
      expect(temp.metric, equals('body_temperature'));
      expect(temp.value, equals(36.8));
      expect(temp.unit, equals('celsius'));

      // 9. Workout Load
      final load = await dataService.recordWorkoutLoad(
        userId: 'user_ingest_test',
        loadScore: 320.0,
        timestamp: now,
      );
      expect(load.metric, equals('training_load'));
      expect(load.value, equals(320.0));

      // 10. RPE
      final rpe = await dataService.recordRPE(
        userId: 'user_ingest_test',
        rpe: 8.5,
        timestamp: now,
      );
      expect(rpe.metric, equals('session_rpe'));
      expect(rpe.value, equals(8.5));

      // Verify all measurements exist in database repository
      final allDbMeasurements = await measurementRepo.getMeasurements(userId: 'user_ingest_test');
      expect(allDbMeasurements.length, equals(11)); // 10 metrics + 1 extra for dual blood pressure
    });

    test('2. Unit Conversions: Automatic normalization of pounds, minutes, and fahrenheit', () async {
      final now = DateTime.utc(2026, 8, 18, 12, 0);

      // 1. Weight in pounds (170 lbs -> ~77.11 kg)
      final wt = await dataService.recordWeight(
        userId: 'user_ingest_test',
        weight: 170.0,
        unit: 'lbs',
        timestamp: now,
      );
      expect(wt.unit, equals('kg'));
      expect(wt.value, closeTo(77.11, 0.05));

      // 2. Sleep in minutes (480 mins -> 8.0 hours)
      final sleep = await dataService.recordSleep(
        userId: 'user_ingest_test',
        duration: 480.0,
        unit: 'minutes',
        timestamp: now,
      );
      expect(sleep.unit, equals('hours'));
      expect(sleep.value, equals(8.0));

      // 3. Temperature in Fahrenheit (98.6 °F -> 37.0 °C)
      final temp = await dataService.recordTemperature(
        userId: 'user_ingest_test',
        temperature: 98.6,
        unit: 'fahrenheit',
        timestamp: now,
      );
      expect(temp.unit, equals('celsius'));
      expect(temp.value, closeTo(37.0, 0.01));
    });

    test('3. Timestamps & Out-of-Order Ingestion: UTC alignment and chronological sorting', () async {
      final t1 = DateTime.parse('2026-08-18T10:00:00+05:30'); // 04:30 UTC
      final t2 = DateTime.parse('2026-08-18T12:00:00Z');     // 12:00 UTC
      final t3 = DateTime.parse('2026-08-18T08:00:00Z');     // 08:00 UTC

      final rawBatch = [
        Measurement(
          id: 'm2',
          userId: 'user_ingest_test',
          metric: 'heart_rate',
          value: 120.0,
          unit: 'bpm',
          timestamp: t2,
          source: 'sensor_ble',
        ),
        Measurement(
          id: 'm1',
          userId: 'user_ingest_test',
          metric: 'heart_rate',
          value: 70.0,
          unit: 'bpm',
          timestamp: t1,
          source: 'sensor_ble',
        ),
        Measurement(
          id: 'm3',
          userId: 'user_ingest_test',
          metric: 'heart_rate',
          value: 95.0,
          unit: 'bpm',
          timestamp: t3,
          source: 'sensor_ble',
        ),
      ];

      final processed = await dataService.recordMeasurements(rawBatch);

      // Verify UTC normalization and chronological sorting
      expect(processed[0].id, equals('m1')); // 04:30 UTC
      expect(processed[0].timestamp.isUtc, isTrue);
      expect(processed[1].id, equals('m3')); // 08:00 UTC
      expect(processed[2].id, equals('m2')); // 12:00 UTC
    });

    test('4. Duplicate Measurements: Deduplication and source priority conflict resolution', () async {
      final timestamp = DateTime.utc(2026, 8, 18, 12, 0);

      // Two measurements at the same minute for the same metric from different sources
      final appleHealth = Measurement(
        id: 'apple_1',
        userId: 'user_ingest_test',
        metric: 'rhr',
        value: 62.0,
        unit: 'bpm',
        timestamp: timestamp,
        source: 'apple_health', // priority 80
      );

      final polarSensor = Measurement(
        id: 'polar_1',
        userId: 'user_ingest_test',
        metric: 'rhr',
        value: 58.0,
        unit: 'bpm',
        timestamp: timestamp,
        source: 'sensor_ble_polar', // priority 100
      );

      // Batch ingestion: higher priority source should win
      final processed = await dataService.recordMeasurements([appleHealth, polarSensor]);
      expect(processed.length, equals(1));
      expect(processed.first.source, equals('sensor_ble_polar'));
      expect(processed.first.value, equals(58.0));
    });

    test('5. Data Quality: Tracking observed, estimated, stale, missing, and quality ratio report', () async {
      final now = DateTime.utc(2026, 8, 18, 12, 0);

      await dataService.recordMeasurement(Measurement(
        id: 'q_obs',
        userId: 'user_ingest_test',
        metric: 'hrv_rmssd',
        value: 65.0,
        unit: 'ms',
        timestamp: now,
        source: 'sensor',
        quality: DataQuality.observed,
      ));

      await dataService.recordMeasurement(Measurement(
        id: 'q_est',
        userId: 'user_ingest_test',
        metric: 'hrv_rmssd',
        value: 60.0,
        unit: 'ms',
        timestamp: now,
        source: 'estimator',
        quality: DataQuality.estimated,
      ));

      await dataService.recordMeasurement(Measurement(
        id: 'q_stale',
        userId: 'user_ingest_test',
        metric: 'hrv_rmssd',
        value: 55.0,
        unit: 'ms',
        timestamp: now,
        source: 'cache',
        quality: DataQuality.stale,
      ));

      final report = await dataService.getDataQualityReport();
      expect(report['totalMeasurements'], equals(3));
      expect(report['observedCount'], equals(1));
      expect(report['estimatedCount'], equals(1));
      expect(report['staleCount'], equals(1));
      expect(report['qualityRatio'], closeTo(0.33, 0.05));
    });

    test('6. Immutable Event System: Appending all standard event types', () async {
      final now = DateTime.utc(2026, 8, 18, 14, 0);

      final eventTypes = [
        KineticEventType.workoutStarted,
        KineticEventType.setCompleted,
        KineticEventType.workoutCompleted,
        KineticEventType.sleepRecorded,
        KineticEventType.weightRecorded,
        KineticEventType.deviceMeasurementReceived,
        KineticEventType.goalChanged,
        KineticEventType.targetChanged,
        KineticEventType.recommendationGenerated,
        KineticEventType.recommendationAccepted,
        KineticEventType.recommendationOverridden,
      ];

      for (int i = 0; i < eventTypes.length; i++) {
        await dataService.recordWorkoutEvent(
          userId: 'user_ingest_test',
          eventType: eventTypes[i],
          payload: {'step_index': i, 'action': 'test'},
          timestamp: now.add(Duration(minutes: i)),
        );
      }

      final recordedEvents = await dataService.getEvents();
      expect(recordedEvents.length, equals(eventTypes.length));

      // Verify chronological order and immutable payload
      for (int i = 0; i < eventTypes.length; i++) {
        expect(recordedEvents[i].eventType, equals(eventTypes[i]));
        expect(recordedEvents[i].payload['step_index'], equals(i));
      }
    });

    test('7. Restart Recovery: Restoring state from SQLite disk layer after process restart', () async {
      final now = DateTime.utc(2026, 8, 18, 12, 0);

      // Ingest measurements & events
      await dataService.recordWeight(
        userId: 'user_ingest_test',
        weight: 82.5,
        timestamp: now,
      );

      await dataService.recordWorkoutEvent(
        userId: 'user_ingest_test',
        eventType: KineticEventType.workoutCompleted,
        payload: {'duration_mins': 45, 'session_id': 'sess_1'},
        timestamp: now,
      );

      // Simulate app restart / crash: reset in-memory store
      KineticStore.instance.reset();
      expect(KineticStore.instance.getMeasurements(), isEmpty);
      expect(KineticStore.instance.getEvents(), isEmpty);

      // Reconstruct store directly from local database
      final persistedMeasurements = await measurementRepo.getMeasurements(userId: 'user_ingest_test');
      final persistedEvents = await eventRepo.getEvents(userId: 'user_ingest_test');

      for (final m in persistedMeasurements) {
        KineticStore.instance.recordMeasurement(m);
      }
      for (final e in persistedEvents) {
        KineticStore.instance.recordEvent(e);
      }

      // Verify reconstructed state
      expect(KineticStore.instance.getMeasurements().length, equals(1));
      expect(KineticStore.instance.getMeasurements().first.metric, equals('weight_kg'));
      expect(KineticStore.instance.getMeasurements().first.value, equals(82.5));

      expect(KineticStore.instance.getEvents().length, equals(1));
      expect(KineticStore.instance.getEvents().first.eventType, equals(KineticEventType.workoutCompleted));
      expect(KineticStore.instance.getEvents().first.payload['session_id'], equals('sess_1'));
    });
  });
}
