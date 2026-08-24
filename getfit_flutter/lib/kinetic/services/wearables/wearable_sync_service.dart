import '../../data/measurement_repository.dart';
import '../../domain/models.dart';
import 'health_connect_service.dart';
import 'health_kit_service.dart';
import 'oura_service.dart';

/// Coordinates multi-source wearable ingestion and resolves cross-source data conflicts
class WearableSyncService {
  final MeasurementRepository measurementRepository;
  final HealthKitService healthKitService;
  final HealthConnectService healthConnectService;
  final OuraService ouraService;

  WearableSyncService({
    required this.measurementRepository,
    HealthKitService? healthKitService,
    HealthConnectService? healthConnectService,
    OuraService? ouraService,
  })  : healthKitService = healthKitService ?? HealthKitService(),
        healthConnectService = healthConnectService ?? HealthConnectService(),
        ouraService = ouraService ?? OuraService();

  /// Resolves conflicts across multiple measurements for the same metric & timestamp window
  /// Priority rules:
  /// - Sleep & HRV: Oura (Weight 3) > HealthKit / HealthConnect (Weight 2) > Manual (Weight 1)
  /// - Steps & Active Energy: HealthKit / HealthConnect (Weight 3) > Oura (Weight 2) > Manual (Weight 1)
  /// - Workouts: Sensor-backed (Weight 3) > App-logged (Weight 2) > Manual (Weight 1)
  List<Measurement> resolveConflicts(List<Measurement> rawMeasurements) {
    // Group measurements by metric and bucketed date/time (YYYY-MM-DD)
    final Map<String, List<Measurement>> grouped = {};

    for (final m in rawMeasurements) {
      final dateKey = '${m.metric}_${m.timestamp.year}-${m.timestamp.month.toString().padLeft(2, '0')}-${m.timestamp.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(dateKey, () => []).add(m);
    }

    final List<Measurement> resolved = [];

    for (final entry in grouped.entries) {
      final candidates = entry.value;
      if (candidates.length == 1) {
        resolved.add(candidates.first);
        continue;
      }

      // Conflict exists, evaluate priority with deterministic sorting
      final metric = candidates.first.metric;
      candidates.sort((a, b) {
        final priorityComp = _getSourcePriority(metric, b.source).compareTo(_getSourcePriority(metric, a.source));
        if (priorityComp != 0) return priorityComp;

        // Tie breaker 1: Data quality (observed > estimated > stale)
        final qualityComp = _getQualityWeight(b.quality).compareTo(_getQualityWeight(a.quality));
        if (qualityComp != 0) return qualityComp;

        // Tie breaker 2: Most recent timestamp wins
        return b.timestamp.compareTo(a.timestamp);
      });

      // Winner is the highest priority candidate
      resolved.add(candidates.first);
    }

    return resolved;
  }

  /// Calculates source priority weight for a specific metric
  int _getSourcePriority(String metric, String source) {
    final s = source.toLowerCase();

    if (metric == 'hrv_rmssd' || metric == 'rhr' || metric == 'sleep_duration_hrs') {
      // Sleep & HRV: Oura (3) > HealthKit/HealthConnect (2) > Manual (1)
      if (s.contains('oura')) return 3;
      if (s.contains('apple') || s.contains('health') || s.contains('connect')) return 2;
      return 1;
    } else if (metric == 'steps' || metric == 'active_energy') {
      // Steps & Energy: HealthKit/HealthConnect (3) > Oura (2) > Manual (1)
      if (s.contains('apple') || s.contains('health') || s.contains('connect')) return 3;
      if (s.contains('oura')) return 2;
      return 1;
    } else if (metric == 'workout' || metric == 'workout_session') {
      // Workouts: Sensor-backed (3) > App-logged (2) > Manual (1)
      if (s.contains('sensor') || s.contains('polar') || s.contains('garmin')) return 3;
      if (s.contains('apple') || s.contains('connect') || s.contains('oura')) return 2;
      return 1;
    } else {
      // General / default
      if (s.contains('oura') || s.contains('apple') || s.contains('connect')) return 2;
      return 1;
    }
  }

  int _getQualityWeight(DataQuality quality) {
    switch (quality) {
      case DataQuality.observed:
        return 4;
      case DataQuality.estimated:
        return 3;
      case DataQuality.stale:
        return 2;
      case DataQuality.unreliable:
        return 1;
      case DataQuality.missing:
        return 0;
    }
  }

  /// Ingests all active wearable streams, applies conflict resolution, and saves to repository
  Future<List<Measurement>> syncWearables({
    required String userId,
    required DateTime start,
    required DateTime end,
    List<Map<String, dynamic>>? mockHealthKitSamples,
    List<Map<String, dynamic>>? mockHealthConnectSamples,
    List<Map<String, dynamic>>? mockOuraDocs,
  }) async {
    final List<Measurement> allRaw = [];

    // 1. Fetch iOS HealthKit
    if (healthKitService.permissionStatus == HealthKitPermissionStatus.authorized) {
      final hkData = await healthKitService.readMetrics(
        userId: userId,
        start: start,
        end: end,
        mockSamples: mockHealthKitSamples,
      );
      allRaw.addAll(hkData);
    }

    // 2. Fetch Android Health Connect
    if (healthConnectService.permissionStatus == HealthConnectPermissionStatus.authorized) {
      final hcData = await healthConnectService.readMetrics(
        userId: userId,
        start: start,
        end: end,
        mockSamples: mockHealthConnectSamples,
      );
      allRaw.addAll(hcData);
    }

    // 3. Fetch Oura API
    if (ouraService.status == OuraConnectionStatus.connected) {
      final ouraData = await ouraService.readRawMetrics(
        userId: userId,
        start: start,
        end: end,
        mockOuraDailyDocuments: mockOuraDocs,
      );
      allRaw.addAll(ouraData);
    }

    if (allRaw.isEmpty) {
      return [];
    }

    // 4. Multi-source conflict resolution
    final resolved = resolveConflicts(allRaw);

    // 5. Persist to SQLite MeasurementRepository
    await measurementRepository.recordBatch(resolved);

    return resolved;
  }
}
