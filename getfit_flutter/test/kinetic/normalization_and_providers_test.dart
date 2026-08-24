import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/providers/provider_interfaces.dart';
import 'package:kinetic_precision/kinetic/providers/local_manual_provider.dart';
import 'package:kinetic_precision/kinetic/providers/synthetic_provider.dart';
import 'package:kinetic_precision/kinetic/providers/external_stubs.dart';
import 'package:kinetic_precision/kinetic/normalization/data_normalizer.dart';
import 'package:kinetic_precision/kinetic/data/database_manager.dart';
import 'package:kinetic_precision/kinetic/data/migration.dart';
import 'package:kinetic_precision/kinetic/kinetic_core.dart';
import 'package:kinetic_precision/kinetic/data/migrations/migration_v1_measurements_events.dart';
import 'package:kinetic_precision/kinetic/data/measurement_repository.dart';

void main() {
  group('SPEC 33: Provider Interfaces & Adapters', () {
    test('LocalManualProvider reads manual records from local SQLite repository', () async {
      final registry = MigrationRegistry();
      registry.register(MigrationV1MeasurementsEvents());
      registry.register(MigrationV2DomainModels());
      final dbManager = KineticDatabaseManager.inMemory(registry: registry);
      await dbManager.migrateToLatest();

      final repo = MeasurementRepository(dbManager.executor);
      final manualProvider = LocalManualProvider(repo);

      // Record a manual log
      await repo.recordMeasurement(
        Measurement(
          id: 'manual_rhr_1',
          userId: 'user_1',
          metric: 'rhr',
          value: 58.0,
          unit: 'bpm',
          timestamp: DateTime.now(),
          source: 'manual_entry',
          quality: DataQuality.observed,
        ),
      );

      final samples = await manualProvider.fetchHeartRateSamples(userId: 'user_1');
      expect(samples.length, equals(1));
      expect(samples.first.value, equals(58.0));

      await dbManager.close();
    });

    test('SyntheticProvider delivers deterministic simulated streams', () async {
      final syntheticProvider = SyntheticProvider();
      final workouts = await syntheticProvider.fetchCompletedWorkouts(userId: 'sim_user');
      expect(workouts.isNotEmpty, isTrue);

      final hrv = await syntheticProvider.fetchHRVSamples(userId: 'sim_user');
      expect(hrv.isNotEmpty, isTrue);
    });

    test('External stubs (Apple Health & Oura) have documented interfaces without network dependencies', () async {
      final appleHealth = AppleHealthProviderStub();
      final oura = OuraProviderStub();

      expect(appleHealth.providerId, equals('apple_health'));
      expect(appleHealth.defaultPriority, equals(80));

      expect(oura.providerId, equals('oura_ring'));
      expect(oura.defaultPriority, equals(90));

      // Local-first stub returns clean empty list
      final appleResults = await appleHealth.fetchMeasurements(userId: 'user_1');
      expect(appleResults.isEmpty, isTrue);
    });
  });

  group('SPEC 34: Data Normalization & Conflict Resolution', () {
    late DataNormalizer normalizer;

    setUp(() {
      normalizer = DataNormalizer();
    });

    test('Unit Normalization: converts lbs, grams, miles, meters, kJ, and minutes accurately', () {
      final now = DateTime.now();

      // 1. Weight: 180 lbs -> kg (81.6466 kg)
      final mWeight = normalizer.normalize(
        Measurement(id: '1', userId: 'u1', metric: 'weight', value: 180.0, unit: 'lbs', timestamp: now, source: 'scale'),
      );
      expect(mWeight.unit, equals('kg'));
      expect(mWeight.value, closeTo(81.6466, 0.001));

      // 2. Distance: 5 miles -> km (8.0467 km)
      final mDist = normalizer.normalize(
        Measurement(id: '2', userId: 'u1', metric: 'distance', value: 5.0, unit: 'miles', timestamp: now, source: 'gps'),
      );
      expect(mDist.unit, equals('km'));
      expect(mDist.value, closeTo(8.0467, 0.001));

      // 3. Energy: 1000 kJ -> kcal (239.0057 kcal)
      final mEnergy = normalizer.normalize(
        Measurement(id: '3', userId: 'u1', metric: 'energy', value: 1000.0, unit: 'kJ', timestamp: now, source: 'treadmill'),
      );
      expect(mEnergy.unit, equals('kcal'));
      expect(mEnergy.value, closeTo(239.0057, 0.001));

      // 4. Duration: 90 minutes -> hours (1.5 hours)
      final mDuration = normalizer.normalize(
        Measurement(id: '4', userId: 'u1', metric: 'duration', value: 90.0, unit: 'minutes', timestamp: now, source: 'timer'),
      );
      expect(mDuration.unit, equals('hours'));
      expect(mDuration.value, equals(1.5));
    });

    test('Handles intentionally messy input: duplicate timestamps, mixed units, out-of-order events, and source priority', () {
      final baseTime = DateTime.utc(2026, 8, 18, 8, 0, 0);

      // Intentionally messy batch:
      // - Event 1: Lower priority manual entry with 180 lbs at 08:00:00
      // - Event 2: Higher priority Oura ring with 62 bpm at 08:00:10 (out-of-order order)
      // - Event 3: Lower priority Apple Health with 65 bpm at 08:00:15 (duplicate window conflict with Oura)
      // - Event 4: High priority Smart Scale with 81.6 kg at 08:00:00 (duplicate window conflict with manual entry)
      final messyBatch = [
        Measurement(
          id: 'm_manual_weight',
          userId: 'u1',
          metric: 'weight',
          value: 180.0,
          unit: 'lbs', // Mixed unit
          timestamp: baseTime,
          source: 'manual_entry', // Priority = 50
        ),
        Measurement(
          id: 'm_apple_hr',
          userId: 'u1',
          metric: 'heart_rate',
          value: 65.0,
          unit: 'bpm',
          timestamp: baseTime.add(const Duration(seconds: 15)),
          source: 'apple_health', // Priority = 80
        ),
        Measurement(
          id: 'm_oura_hr',
          userId: 'u1',
          metric: 'heart_rate',
          value: 62.0,
          unit: 'bpm',
          timestamp: baseTime.add(const Duration(seconds: 10)),
          source: 'oura_ring', // Higher Priority = 90
        ),
        Measurement(
          id: 'm_scale_weight',
          userId: 'u1',
          metric: 'weight',
          value: 81.65,
          unit: 'kg',
          timestamp: baseTime.add(const Duration(seconds: 5)),
          source: 'oura_ring', // Higher Priority = 90
        ),
      ];

      final cleanBatch = normalizer.normalizeBatch(messyBatch);

      // Verify Deduplication & Conflict Resolution:
      // 4 messy inputs reduced to 2 unique clean metrics (1 weight, 1 heart rate)
      expect(cleanBatch.length, equals(2));

      // 1. Heart Rate: Oura (62 bpm, priority 90) defeated Apple Health (65 bpm, priority 80)
      final resolvedHR = cleanBatch.firstWhere((m) => m.metric == 'heart_rate');
      expect(resolvedHR.source, equals('oura_ring'));
      expect(resolvedHR.value, equals(62.0));

      // 2. Weight: Oura scale (priority 90) defeated Manual entry (priority 50)
      final resolvedWeight = cleanBatch.firstWhere((m) => m.metric == 'weight');
      expect(resolvedWeight.source, equals('oura_ring'));
      expect(resolvedWeight.unit, equals('kg'));
      expect(resolvedWeight.value, equals(81.65));

      // 3. Timestamps are sorted in chronological UTC order
      expect(cleanBatch[0].timestamp.isBefore(cleanBatch[1].timestamp) || cleanBatch[0].timestamp.isAtSameMomentAs(cleanBatch[1].timestamp), isTrue);
    });
  });
}
