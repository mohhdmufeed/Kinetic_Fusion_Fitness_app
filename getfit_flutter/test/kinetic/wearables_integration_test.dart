import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/data/database_manager.dart';
import 'package:kinetic_precision/kinetic/data/migration.dart';
import 'package:kinetic_precision/kinetic/data/migrations/migration_v1_measurements_events.dart';
import 'package:kinetic_precision/kinetic/data/migrations/migration_v2_domain_models.dart';
import 'package:kinetic_precision/kinetic/data/measurement_repository.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/domain/latent_states.dart';
import 'package:kinetic_precision/kinetic/intelligence/feature_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/state_estimator.dart';
import 'package:kinetic_precision/kinetic/services/wearables/health_kit_service.dart';
import 'package:kinetic_precision/kinetic/services/wearables/health_connect_service.dart';
import 'package:kinetic_precision/kinetic/services/wearables/oura_service.dart';
import 'package:kinetic_precision/kinetic/services/wearables/wearable_sync_service.dart';

void main() {
  group('Epic B1 Wearables Ingestion Integration Tests', () {
    late KineticDatabaseManager dbManager;
    late MeasurementRepository repository;
    const userId = 'user_wearables_b1';

    setUp(() async {
      final registry = MigrationRegistry();
      registry.register(MigrationV1MeasurementsEvents());
      registry.register(MigrationV2DomainModels());
      dbManager = KineticDatabaseManager.inMemory(registry: registry);
      await dbManager.migrateToLatest();
      repository = MeasurementRepository(dbManager.executor);
    });

    tearDown(() async {
      await dbManager.close();
    });

    test('Task 1: Apple HealthKit data ingestion feeds kinetic engine and produces distinct state vs baseline', () async {
      final healthKit = HealthKitService();
      healthKit.setPermissionStatusForTesting(HealthKitPermissionStatus.authorized);

      final now = DateTime.now().toUtc();
      final mockSamples = [
        {'type': 'HKQuantityTypeIdentifierHeartRate', 'value': 48.0, 'timestamp': now.toIso8601String(), 'unit': 'bpm'},
        {'type': 'HKQuantityTypeIdentifierHeartRateVariabilitySDNN', 'value': 85.0, 'timestamp': now.toIso8601String(), 'unit': 'ms'},
        {'type': 'HKCategoryTypeIdentifierSleepAnalysis', 'value': 8.5, 'timestamp': now.toIso8601String(), 'unit': 'hours'},
        {'type': 'HKQuantityTypeIdentifierStepCount', 'value': 12500.0, 'timestamp': now.toIso8601String(), 'unit': 'count'},
        {'type': 'HKQuantityTypeIdentifierActiveEnergyBurned', 'value': 620.0, 'timestamp': now.toIso8601String(), 'unit': 'kcal'},
      ];

      final measurements = await healthKit.readMetrics(
        userId: userId,
        start: now.subtract(const Duration(days: 1)),
        end: now,
        mockSamples: mockSamples,
      );

      expect(measurements.length, 5);
      await repository.recordBatch(measurements);

      // Verify retrieval from Drift repository
      final storedHrv = await repository.getMeasurements(userId: userId, metric: 'hrv_rmssd');
      expect(storedHrv.isNotEmpty, isTrue);
      expect(storedHrv.first.value, 85.0);
      expect(storedHrv.first.source, 'apple_health');

      // Group stored measurements for feature extractor
      final allUserMeasurements = await repository.getMeasurements(userId: userId);
      final rawGrouped = <String, List<Measurement>>{};
      for (final m in allUserMeasurements) {
        rawGrouped.putIfAbsent(m.metric, () => []).add(m);
      }

      // Feature extraction with established baselines
      final Map<String, PersonalBaseline> baselines = {
        'hrv_rmssd': PersonalBaseline(metric: 'hrv_rmssd', mean: 55.0, stdDev: 10.0, min: 30.0, max: 90.0, sampleCount: 30, lastCalculated: now),
        'rhr': PersonalBaseline(metric: 'rhr', mean: 56.0, stdDev: 4.0, min: 45.0, max: 70.0, sampleCount: 30, lastCalculated: now),
        'sleep_duration_hrs': PersonalBaseline(metric: 'sleep_duration_hrs', mean: 7.5, stdDev: 0.8, min: 6.0, max: 9.0, sampleCount: 30, lastCalculated: now),
        'steps': PersonalBaseline(metric: 'steps', mean: 9000.0, stdDev: 1500.0, min: 5000.0, max: 15000.0, sampleCount: 30, lastCalculated: now),
      };

      final featureEngine = KineticFeatureEngine(baselines: baselines);
      final features = featureEngine.extractFeatures(rawGrouped);

      expect(features.hrvZScore, greaterThan(2.0)); // (85 - 55) / 10 = +3.0
      expect(features.rhrDeltaBpm, lessThan(0.0));  // 48 - 56 = -8 bpm

      final stateEstimator = KineticStateEstimator();
      final state = stateEstimator.estimateState(
        features,
        {'userId': userId},
        deterministicTimestamp: now,
      );

      // Elevated HRV + Low RHR + Optimal sleep yields superior readiness vs baseline
      expect(state.recoveryScore, greaterThan(80.0));
      expect(state.readinessScore, greaterThan(80.0));

      // Partial permission handling (user grants steps only)
      final partialHealthKit = HealthKitService();
      partialHealthKit.setPermissionStatusForTesting(
        HealthKitPermissionStatus.partiallyAuthorized,
        grantedTypes: {'steps'},
      );
      final partialData = await partialHealthKit.readMetrics(
        userId: userId,
        start: now.subtract(const Duration(days: 1)),
        end: now,
        mockSamples: mockSamples,
      );
      expect(partialData.length, 1);
      expect(partialData.first.metric, 'steps');
      expect(partialData.first.value, 12500.0);
    });

    test('Task 2: Android Health Connect maps data with exact schema and output parity with iOS', () async {
      final healthConnect = HealthConnectService();

      // Test 'not installed' handling
      healthConnect.setAvailabilityForTesting(HealthConnectAvailability.notInstalled);
      final unavailMetrics = await healthConnect.readMetrics(
        userId: userId,
        start: DateTime.now(),
        end: DateTime.now(),
        mockSamples: [{'type': 'StepsRecord', 'value': 8000.0}],
      );
      expect(unavailMetrics.isEmpty, isTrue);

      // Test authorized state
      healthConnect.setAvailabilityForTesting(HealthConnectAvailability.installed);
      healthConnect.setPermissionStatusForTesting(HealthConnectPermissionStatus.authorized);

      final now = DateTime.now().toUtc();
      final mockSamples = [
        {'type': 'HeartRateRecord', 'value': 48.0, 'timestamp': now.toIso8601String()},
        {'type': 'HeartRateVariabilityRmssdRecord', 'value': 85.0, 'timestamp': now.toIso8601String()},
        {'type': 'SleepSessionRecord', 'value': 8.5, 'timestamp': now.toIso8601String()},
        {'type': 'StepsRecord', 'value': 12500.0, 'timestamp': now.toIso8601String()},
        {'type': 'ActiveCaloriesBurnedRecord', 'value': 620.0, 'timestamp': now.toIso8601String()},
      ];

      final hcMeasurements = await healthConnect.readMetrics(
        userId: userId,
        start: now.subtract(const Duration(days: 1)),
        end: now,
        mockSamples: mockSamples,
      );

      expect(hcMeasurements.length, 5);
      expect(hcMeasurements.any((m) => m.metric == 'rhr' && m.value == 48.0 && m.source == 'health_connect'), isTrue);
      expect(hcMeasurements.any((m) => m.metric == 'hrv_rmssd' && m.value == 85.0 && m.source == 'health_connect'), isTrue);
      expect(hcMeasurements.any((m) => m.metric == 'sleep_duration_hrs' && m.value == 8.5 && m.source == 'health_connect'), isTrue);
      expect(hcMeasurements.any((m) => m.metric == 'steps' && m.value == 12500.0 && m.source == 'health_connect'), isTrue);
      expect(hcMeasurements.any((m) => m.metric == 'active_energy' && m.value == 620.0 && m.source == 'health_connect'), isTrue);

      // Verify Parity: passing Health Connect measurements produces identical features to iOS HealthKit
      final rawGrouped = <String, List<Measurement>>{};
      for (final m in hcMeasurements) {
        rawGrouped.putIfAbsent(m.metric, () => []).add(m);
      }

      final Map<String, PersonalBaseline> baselines = {
        'hrv_rmssd': PersonalBaseline(metric: 'hrv_rmssd', mean: 55.0, stdDev: 10.0, min: 30.0, max: 90.0, sampleCount: 30, lastCalculated: now),
        'rhr': PersonalBaseline(metric: 'rhr', mean: 56.0, stdDev: 4.0, min: 45.0, max: 70.0, sampleCount: 30, lastCalculated: now),
        'sleep_duration_hrs': PersonalBaseline(metric: 'sleep_duration_hrs', mean: 7.5, stdDev: 0.8, min: 6.0, max: 9.0, sampleCount: 30, lastCalculated: now),
        'steps': PersonalBaseline(metric: 'steps', mean: 9000.0, stdDev: 1500.0, min: 5000.0, max: 15000.0, sampleCount: 30, lastCalculated: now),
      };

      final featureEngine = KineticFeatureEngine(baselines: baselines);
      final features = featureEngine.extractFeatures(rawGrouped);

      final stateEstimator = KineticStateEstimator();
      final state = stateEstimator.estimateState(
        features,
        {'userId': userId},
        deterministicTimestamp: now,
      );

      expect(state.recoveryScore, greaterThan(80.0));
      expect(state.readinessScore, greaterThan(80.0));
    });

    test('Task 3: Oura API extracts raw physiological data, strictly ignores opinionated scores, and handles token lifecycle', () async {
      final oura = OuraService();
      oura.setStatusForTesting(OuraConnectionStatus.connected);

      final now = DateTime.now().toUtc();
      final mockOuraDocs = [
        {
          'day': now.toIso8601String(),
          'average_hrv': 72.0,
          'lowest_heart_rate': 47.0,
          'total_sleep_duration': 29520, // 8.2 hours (29520 / 3600)
          'steps': 10800,
          'readiness_score': 91, // OPINIONATED SCORE - MUST BE BYPASSED
          'sleep_score': 88,     // OPINIONATED SCORE - MUST BE BYPASSED
          'activity_score': 95,  // OPINIONATED SCORE - MUST BE BYPASSED
        }
      ];

      final measurements = await oura.readRawMetrics(
        userId: userId,
        start: now.subtract(const Duration(days: 1)),
        end: now,
        mockOuraDailyDocuments: mockOuraDocs,
      );

      expect(measurements.length, 4);
      expect(measurements.any((m) => m.metric == 'hrv_rmssd' && m.value == 72.0), isTrue);
      expect(measurements.any((m) => m.metric == 'rhr' && m.value == 47.0), isTrue);
      expect(measurements.any((m) => m.metric == 'sleep_duration_hrs' && m.value == 8.2), isTrue);
      expect(measurements.any((m) => m.metric == 'steps' && m.value == 10800.0), isTrue);

      // Verify strictly NO score metrics were ingested
      expect(measurements.any((m) => m.metric.contains('score')), isFalse);
      expect(measurements.any((m) => m.metric.contains('readiness')), isFalse);

      // Token expiry & revocation handling
      oura.setStatusForTesting(OuraConnectionStatus.expired);
      final expiredResult = await oura.readRawMetrics(
        userId: userId,
        start: now,
        end: now,
        mockOuraDailyDocuments: mockOuraDocs,
      );
      expect(expiredResult.isEmpty, isTrue);

      oura.setStatusForTesting(OuraConnectionStatus.revoked);
      final revokedResult = await oura.readRawMetrics(
        userId: userId,
        start: now,
        end: now,
        mockOuraDailyDocuments: mockOuraDocs,
      );
      expect(revokedResult.isEmpty, isTrue);
    });

    test('Task 4: Multi-source conflict resolution applies explicit priority rules and saves winner to Drift DB', () async {
      final syncService = WearableSyncService(measurementRepository: repository);

      final now = DateTime.now().toUtc();
      final conflictingSamples = [
        // 1. Sleep Conflict: Oura (8.2h) vs Apple Health (7.5h) -> Oura wins (Weight 3 > 2)
        Measurement(
          id: 'hk_sleep_1',
          userId: userId,
          metric: 'sleep_duration_hrs',
          value: 7.5,
          unit: 'hours',
          timestamp: now,
          source: 'apple_health',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'oura_sleep_1',
          userId: userId,
          metric: 'sleep_duration_hrs',
          value: 8.2,
          unit: 'hours',
          timestamp: now,
          source: 'oura',
          quality: DataQuality.observed,
        ),

        // 2. HRV Conflict: Oura (72ms) vs Health Connect (65ms) -> Oura wins (Weight 3 > 2)
        Measurement(
          id: 'hc_hrv_1',
          userId: userId,
          metric: 'hrv_rmssd',
          value: 65.0,
          unit: 'ms',
          timestamp: now,
          source: 'health_connect',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'oura_hrv_1',
          userId: userId,
          metric: 'hrv_rmssd',
          value: 72.0,
          unit: 'ms',
          timestamp: now,
          source: 'oura',
          quality: DataQuality.observed,
        ),

        // 3. Steps Conflict: Health Connect (11500) vs Oura (9800) -> Health Connect wins (Weight 3 > 2)
        Measurement(
          id: 'hc_steps_1',
          userId: userId,
          metric: 'steps',
          value: 11500.0,
          unit: 'count',
          timestamp: now,
          source: 'health_connect',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'oura_steps_1',
          userId: userId,
          metric: 'steps',
          value: 9800.0,
          unit: 'count',
          timestamp: now,
          source: 'oura',
          quality: DataQuality.observed,
        ),

        // 4. Energy Conflict: Apple Health (650 kcal) vs Oura (510 kcal) -> Apple Health wins (Weight 3 > 2)
        Measurement(
          id: 'hk_energy_1',
          userId: userId,
          metric: 'active_energy',
          value: 650.0,
          unit: 'kcal',
          timestamp: now,
          source: 'apple_health',
          quality: DataQuality.observed,
        ),
        Measurement(
          id: 'oura_energy_1',
          userId: userId,
          metric: 'active_energy',
          value: 510.0,
          unit: 'kcal',
          timestamp: now,
          source: 'oura',
          quality: DataQuality.observed,
        ),
      ];

      final resolved = syncService.resolveConflicts(conflictingSamples);
      expect(resolved.length, 4);

      final resolvedSleep = resolved.firstWhere((m) => m.metric == 'sleep_duration_hrs');
      expect(resolvedSleep.source, 'oura');
      expect(resolvedSleep.value, 8.2);

      final resolvedHrv = resolved.firstWhere((m) => m.metric == 'hrv_rmssd');
      expect(resolvedHrv.source, 'oura');
      expect(resolvedHrv.value, 72.0);

      final resolvedSteps = resolved.firstWhere((m) => m.metric == 'steps');
      expect(resolvedSteps.source, 'health_connect');
      expect(resolvedSteps.value, 11500.0);

      final resolvedEnergy = resolved.firstWhere((m) => m.metric == 'active_energy');
      expect(resolvedEnergy.source, 'apple_health');
      expect(resolvedEnergy.value, 650.0);

      // Persist resolved measurements and verify in SQLite Drift table
      await repository.recordBatch(resolved);
      final storedResolved = await repository.getMeasurements(userId: userId);
      expect(storedResolved.length, 4);
    });

    test('End-to-End: WearableSyncService pulls from multi-source clients, resolves, and stores to database', () async {
      final healthKit = HealthKitService();
      healthKit.setPermissionStatusForTesting(HealthKitPermissionStatus.authorized);

      final healthConnect = HealthConnectService();
      healthConnect.setPermissionStatusForTesting(HealthConnectPermissionStatus.authorized);

      final oura = OuraService();
      oura.setStatusForTesting(OuraConnectionStatus.connected);

      final syncService = WearableSyncService(
        measurementRepository: repository,
        healthKitService: healthKit,
        healthConnectService: healthConnect,
        ouraService: oura,
      );

      final now = DateTime.now().toUtc();
      final mockHk = [
        {'type': 'HKQuantityTypeIdentifierStepCount', 'value': 12000.0, 'timestamp': now.toIso8601String()},
        {'type': 'HKCategoryTypeIdentifierSleepAnalysis', 'value': 7.2, 'timestamp': now.toIso8601String()},
      ];
      final mockOura = [
        {
          'day': now.toIso8601String(),
          'average_hrv': 68.0,
          'lowest_heart_rate': 50.0,
          'total_sleep_duration': 28800, // 8.0 hrs (Oura wins sleep over HK 7.2h)
          'steps': 10500, // HK wins steps (12000 > 10500)
        }
      ];

      final synced = await syncService.syncWearables(
        userId: userId,
        start: now.subtract(const Duration(days: 1)),
        end: now,
        mockHealthKitSamples: mockHk,
        mockOuraDocs: mockOura,
      );

      expect(synced.length, 4);
      final sleepWinner = synced.firstWhere((m) => m.metric == 'sleep_duration_hrs');
      expect(sleepWinner.source, 'oura');
      expect(sleepWinner.value, 8.0);

      final stepsWinner = synced.firstWhere((m) => m.metric == 'steps');
      expect(stepsWinner.source, 'apple_health');
      expect(stepsWinner.value, 12000.0);

      // Verify all synced items are persisted in SQLite
      final inDb = await repository.getMeasurements(userId: userId);
      expect(inDb.length, 4);
    });
  });
}
