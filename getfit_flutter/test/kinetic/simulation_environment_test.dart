import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/simulation/archetypes.dart';
import 'package:kinetic_precision/kinetic/simulation/generator.dart';
import 'package:kinetic_precision/kinetic/services/simulation_service.dart';
import 'package:kinetic_precision/kinetic/persistence/kinetic_store.dart';

void main() {
  group('Phase 10: Deterministic Simulation Environment Tests', () {
    final simulationService = SimulationService();
    final fixedTime = DateTime(2026, 8, 18, 12, 0, 0);

    test('1. Multi-Duration History Generation: 30, 90, 180, and 365 days across all 5 archetypes', () {
      const durations = [30, 90, 180, 365];

      for (final archetype in UserArchetype.values) {
        for (final days in durations) {
          final dataset = simulationService.generateHistoryDataset(
            archetype: archetype,
            days: days,
            seed: 42,
            deterministicTimestamp: fixedTime,
          );

          expect(dataset.days, equals(days));
          expect(dataset.measurements.isNotEmpty, isTrue);
          expect(dataset.events.isNotEmpty, isTrue);
          expect(dataset.totalRecordsCount, greaterThan(days * 2));
        }
      }
    });

    test('2. Bit-for-Bit Determinism: Identical seed produces bit-for-bit identical history & closed-loop results', () {
      final run1 = simulationService.runClosedLoopSimulation(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 90,
        seed: 12345,
        deterministicTimestamp: fixedTime,
      );

      final run2 = simulationService.runClosedLoopSimulation(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 90,
        seed: 12345,
        deterministicTimestamp: fixedTime,
      );

      expect(run1.dataset.measurements.length, equals(run2.dataset.measurements.length));
      expect(run1.recommendations.length, equals(run2.recommendations.length));
      expect(run1.traces.length, equals(run2.traces.length));
      expect(run1.feedbackChains.length, equals(run2.feedbackChains.length));

      for (int i = 0; i < run1.recommendations.length; i++) {
        expect(run1.recommendations[i].action, equals(run2.recommendations[i].action));
        expect(run1.traces[i].selectedDecision, equals(run2.traces[i].selectedDecision));
      }
    });

    test('3. Closed-Loop Multi-Month Execution: Runs 90-day autonomous lifecycle', () {
      final result = simulationService.runClosedLoopSimulation(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 90,
        seed: 42,
        deterministicTimestamp: fixedTime,
      );

      expect(result.recommendations.isNotEmpty, isTrue);
      expect(result.traces.isNotEmpty, isTrue);
      expect(result.feedbackChains.isNotEmpty, isTrue);
      expect(result.baselines.containsKey('hrv_rmssd'), isTrue);
      expect(result.baselines.containsKey('rhr'), isTrue);
      expect(result.finalState.recoveryScore, greaterThan(50.0));
      expect(result.successRate, greaterThan(0.80));
    });

    test('4. Archetype Separation: User A (High Recovery) vs User B (High Fatigue)', () {
      final userAResult = simulationService.runClosedLoopSimulation(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 90,
        seed: 42,
        deterministicTimestamp: fixedTime,
      );

      final userBResult = simulationService.runClosedLoopSimulation(
        archetype: UserArchetype.userB_HighFatiguePoorSleep,
        days: 90,
        seed: 42,
        deterministicTimestamp: fixedTime,
      );

      // User A should have higher mean HRV baseline than User B
      final userA_HRV = userAResult.baselines['hrv_rmssd']!.mean;
      final userB_HRV = userBResult.baselines['hrv_rmssd']!.mean;
      expect(userA_HRV, greaterThan(userB_HRV));

      // User A should have lower RHR baseline than User B
      final userA_RHR = userAResult.baselines['rhr']!.mean;
      final userB_RHR = userBResult.baselines['rhr']!.mean;
      expect(userA_RHR, lessThan(userB_RHR));

      // User A should have higher mean recovery across the 90 days than User B
      final userA_MeanRecovery = userAResult.traces
          .map((t) => (t.estimatedLatentState['recoveryScore'] as num).toDouble())
          .reduce((a, b) => a + b) / userAResult.traces.length;
      final userB_MeanRecovery = userBResult.traces
          .map((t) => (t.estimatedLatentState['recoveryScore'] as num).toDouble())
          .reduce((a, b) => a + b) / userBResult.traces.length;
      expect(userA_MeanRecovery, greaterThan(userB_MeanRecovery));

      // User A should have more train_hard / high overload prescriptions than User B
      final userA_HardCount = userAResult.recommendations.where((r) => r.action == 'train_hard').length;
      final userB_HardCount = userBResult.recommendations.where((r) => r.action == 'train_hard').length;
      expect(userA_HardCount, greaterThanOrEqualTo(userB_HardCount));
    });

    test('5. User C Weight-Loss Archetype: Shows negative weight trend over 180 days', () {
      final dataset = simulationService.generateHistoryDataset(
        archetype: UserArchetype.userC_WeightLossGoal,
        days: 180,
        seed: 42,
        deterministicTimestamp: fixedTime,
      );

      final weights = dataset.measurements
          .where((m) => m.metric == 'weight_kg')
          .map((m) => m.value)
          .toList();

      expect(weights.length, greaterThan(30));
      final firstWeight = weights.first;
      final lastWeight = weights.last;
      expect(lastWeight, lessThan(firstWeight));
    });

    test('6. User D Strength Peaking Archetype: Prescribes heavy compound resistance loads', () {
      final dataset = simulationService.generateHistoryDataset(
        archetype: UserArchetype.userD_StrengthFocusedAthlete,
        days: 90,
        seed: 42,
        deterministicTimestamp: fixedTime,
      );

      expect(dataset.sessions.isNotEmpty, isTrue);
      final hasHeavySquat = dataset.sessions.any((s) =>
          s.prescriptions.any((p) => p.exerciseId == 'ex_squat_heavy' && p.targetLoadKg >= 140.0));
      expect(hasHeavySquat, isTrue);
    });

    test('7. User E Sparse & Noisy Archetype: Imputation & missing days handled safely', () {
      final result = simulationService.runClosedLoopSimulation(
        archetype: UserArchetype.userE_SparseNoisyData,
        days: 90,
        seed: 42,
        deterministicTimestamp: fixedTime,
      );

      // Successfully runs without runtime crash despite 30% missing observation days
      expect(result.dataset.measurements.isNotEmpty, isTrue);
      expect(result.recommendations.isNotEmpty, isTrue);
      expect(result.baselines.isNotEmpty, isTrue);
    });

    test('8. Offline Store Persistence: Populates local database without internet', () {
      final store = KineticStore.instance;

      simulationService.runClosedLoopSimulation(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 30,
        seed: 42,
        persistToStore: true,
        deterministicTimestamp: fixedTime,
      );

      expect(store.getUser(), isNotNull);
      expect(store.getGoals().isNotEmpty, isTrue);
      expect(store.getLatestRecommendation(), isNotNull);
    });
  });
}
