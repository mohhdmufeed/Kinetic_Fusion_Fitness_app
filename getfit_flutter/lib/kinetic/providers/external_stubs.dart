import '../domain/models.dart';
import 'provider_interfaces.dart';

/// Documented Adapter Stub for Apple HealthKit integration
/// Core app remains 100% local-first and does not depend on HealthKit API.
class AppleHealthProviderStub implements HeartRateProvider, SleepProvider, WorkoutProvider {
  @override
  String get providerId => 'apple_health';

  @override
  String get displayName => 'Apple Health';

  @override
  int get defaultPriority => 80; // High priority

  @override
  Future<List<Measurement>> fetchMeasurements({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    // Local-first stub: returns empty list unless connected via local bridge
    return [];
  }

  @override
  Future<List<Measurement>> fetchHeartRateSamples({required String userId, DateTime? from, DateTime? to}) async => [];

  @override
  Future<List<Measurement>> fetchHRVSamples({required String userId, DateTime? from, DateTime? to}) async => [];

  @override
  Future<List<Measurement>> fetchSleepRecords({required String userId, DateTime? from, DateTime? to}) async => [];

  @override
  Future<List<WorkoutSession>> fetchCompletedWorkouts({required String userId, DateTime? from, DateTime? to}) async => [];
}

/// Documented Adapter Stub for Oura Ring integration
class OuraProviderStub implements HeartRateProvider, SleepProvider {
  @override
  String get providerId => 'oura_ring';

  @override
  String get displayName => 'Oura Ring';

  @override
  int get defaultPriority => 90; // Highest priority for sleep and HRV

  @override
  Future<List<Measurement>> fetchMeasurements({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    return [];
  }

  @override
  Future<List<Measurement>> fetchHeartRateSamples({required String userId, DateTime? from, DateTime? to}) async => [];

  @override
  Future<List<Measurement>> fetchHRVSamples({required String userId, DateTime? from, DateTime? to}) async => [];

  @override
  Future<List<Measurement>> fetchSleepRecords({required String userId, DateTime? from, DateTime? to}) async => [];
}
