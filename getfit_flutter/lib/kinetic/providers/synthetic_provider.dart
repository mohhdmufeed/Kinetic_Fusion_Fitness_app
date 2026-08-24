import '../domain/models.dart';
import '../simulation/archetypes.dart';
import '../simulation/generator.dart';
import 'provider_interfaces.dart';

/// Provider for synthetic test simulation streams
class SyntheticProvider implements HeartRateProvider, SleepProvider, WorkoutProvider {
  final UserArchetype archetype;
  final int seed;

  SyntheticProvider({
    this.archetype = UserArchetype.userA_HighRecoveryAthlete,
    this.seed = 42,
  });

  @override
  String get providerId => 'synthetic_sim';

  @override
  String get displayName => 'Synthetic Simulation Provider';

  @override
  int get defaultPriority => 10; // Low priority (overridden by real sensors)

  @override
  Future<List<Measurement>> fetchMeasurements({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final dataset = KineticSimulator.generateHistory(
      archetype: archetype,
      days: 30,
      seed: seed,
    );
    return dataset.measurements;
  }

  @override
  Future<List<Measurement>> fetchHeartRateSamples({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await fetchMeasurements(userId: userId, from: from, to: to);
    return all.where((m) => m.metric == 'rhr' || m.metric == 'heart_rate').toList();
  }

  @override
  Future<List<Measurement>> fetchHRVSamples({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await fetchMeasurements(userId: userId, from: from, to: to);
    return all.where((m) => m.metric == 'hrv_rmssd').toList();
  }

  @override
  Future<List<Measurement>> fetchSleepRecords({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final all = await fetchMeasurements(userId: userId, from: from, to: to);
    return all.where((m) => m.metric == 'sleep_duration_hrs').toList();
  }

  @override
  Future<List<WorkoutSession>> fetchCompletedWorkouts({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final dataset = KineticSimulator.generateHistory(
      archetype: archetype,
      days: 30,
      seed: seed,
    );
    return dataset.sessions;
  }
}
