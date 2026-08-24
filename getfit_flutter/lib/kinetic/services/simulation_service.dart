import '../persistence/kinetic_store.dart';
import '../simulation/archetypes.dart';
import '../simulation/generator.dart';

/// Application service managing the deterministic simulation environment and synthetic benchmark validation
class SimulationService {
  final KineticStore store;

  SimulationService({KineticStore? store})
      : store = store ?? KineticStore.instance;

  /// Runs multi-day synthetic simulation with full closed-loop intelligence cycle
  ClosedLoopSimulationResult runClosedLoopSimulation({
    required UserArchetype archetype,
    int days = 90,
    int seed = 42,
    bool persistToStore = false,
    DateTime? deterministicTimestamp,
  }) {
    final result = KineticSimulator.simulateClosedLoopHistory(
      archetype: archetype,
      days: days,
      seed: seed,
      deterministicTimestamp: deterministicTimestamp,
    );

    if (persistToStore) {
      final profile = result.dataset.profile;
      store.saveUser(profile.user);
      store.addGoal(profile.goal);

      for (final m in result.dataset.measurements) {
        store.recordMeasurement(m);
      }
      for (final e in result.dataset.events) {
        store.recordEvent(e);
      }
      for (final entry in result.baselines.entries) {
        store.setBaseline(entry.value);
      }
      for (final rec in result.recommendations) {
        store.recordRecommendation(rec);
      }
      for (final trace in result.traces) {
        store.recordTrace(trace);
      }
    }

    return result;
  }

  /// Runs deterministic simulation history dataset (raw observation records)
  SimulationDataset generateHistoryDataset({
    required UserArchetype archetype,
    int days = 90,
    int seed = 42,
    DateTime? deterministicTimestamp,
  }) {
    return KineticSimulator.generateHistory(
      archetype: archetype,
      days: days,
      seed: seed,
      deterministicTimestamp: deterministicTimestamp,
    );
  }

  /// Validates all 5 standard synthetic archetypes across 30, 90, 180, and 365-day timelines
  Map<UserArchetype, Map<int, ClosedLoopSimulationResult>> runMultiTimelineBenchmark({
    int seed = 42,
    DateTime? deterministicTimestamp,
  }) {
    final Map<UserArchetype, Map<int, ClosedLoopSimulationResult>> benchmarkResults = {};
    const durations = [30, 90, 180, 365];

    for (final archetype in UserArchetype.values) {
      benchmarkResults[archetype] = {};
      for (final days in durations) {
        benchmarkResults[archetype]![days] = runClosedLoopSimulation(
          archetype: archetype,
          days: days,
          seed: seed,
          persistToStore: false,
          deterministicTimestamp: deterministicTimestamp,
        );
      }
    }

    return benchmarkResults;
  }
}
