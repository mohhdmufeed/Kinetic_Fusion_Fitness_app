import '../domain/models.dart';
import '../data/measurement_repository.dart';
import 'provider_interfaces.dart';

/// Provider for user manual entries and in-app logs
class LocalManualProvider implements HeartRateProvider, SleepProvider, NutritionProvider {
  final MeasurementRepository repository;

  LocalManualProvider(this.repository);

  @override
  String get providerId => 'manual_entry';

  @override
  String get displayName => 'Manual Entry';

  @override
  int get defaultPriority => 50; // Moderate priority

  @override
  Future<List<Measurement>> fetchMeasurements({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    return repository.getMeasurements(
      userId: userId,
      from: from,
      to: to,
    );
  }

  @override
  Future<List<Measurement>> fetchHeartRateSamples({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await fetchMeasurements(userId: userId, from: from, to: to);
    return all
        .where((m) => m.metric == 'heart_rate' || m.metric == 'rhr' || m.metric == 'resting_heart_rate')
        .toList();
  }

  @override
  Future<List<Measurement>> fetchHRVSamples({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    return repository.getMeasurements(
      userId: userId,
      metric: 'hrv_rmssd',
      from: from,
      to: to,
    );
  }

  @override
  Future<List<Measurement>> fetchSleepRecords({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    return repository.getMeasurements(
      userId: userId,
      metric: 'sleep_duration_hrs',
      from: from,
      to: to,
    );
  }

  @override
  Future<List<Measurement>> fetchNutritionLogs({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    return repository.getMeasurements(
      userId: userId,
      metric: 'calories_ingested',
      from: from,
      to: to,
    );
  }
}
