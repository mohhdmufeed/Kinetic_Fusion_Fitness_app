import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/intelligence/recovery_engine.dart';

void main() {
  group('Phase 5: Recovery Engine Multi-Signal & Scenario Tests', () {
    test('1. Scenario: Strong recovery', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: 8.5,
        sleepDebtHours: 0.0,
        hrvZScore: 1.5,
        rhrDeltaBpm: -2.0,
        acuteChronicWorkloadRatio: 1.0,
        recentAverageRPE: 6.5,
        weeklyVolumeLoadKg: 10000,
        volumeBaselineKg: 10000,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.state, equals('optimal'));
      expect(recovery.direction, equals('improving'));
      expect(recovery.recommendedAction, equals('train_hard'));
      expect(recovery.contributingFactors, contains('sleep_fully_restored'));
      expect(recovery.contributingFactors, contains('hrv_significantly_above_baseline'));
      expect(recovery.confidenceScore, closeTo(0.95, 0.01));
    });

    test('2. Scenario: Poor sleep', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: 4.5,
        sleepDebtHours: 3.5,
        hrvZScore: 0.0,
        rhrDeltaBpm: 0.0,
        acuteChronicWorkloadRatio: 1.0,
        recentAverageRPE: 7.0,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.state, isIn(['fatigued', 'depleted', 'recovering']));
      expect(recovery.contributingFactors, contains('acute_sleep_deficit'));
      expect(recovery.contributingFactors, contains('chronic_sleep_debt_accumulated'));
      expect(recovery.recoveryScore, lessThan(65.0));
    });

    test('3. Scenario: Elevated resting HR', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: 7.5,
        hrvZScore: 0.0,
        rhrDeltaBpm: 6.0, // Elevated by 6 bpm
        acuteChronicWorkloadRatio: 1.0,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.contributingFactors, contains('resting_heart_rate_elevated'));
      expect(recovery.recoveryScore, lessThan(80.0));
    });

    test('4. Scenario: Low HRV', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: 7.5,
        hrvZScore: -1.8, // Suppressed parasympathetic tone
        rhrDeltaBpm: 0.0,
        acuteChronicWorkloadRatio: 1.0,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.contributingFactors, contains('autonomic_sympathetic_strain_detected'));
      expect(recovery.direction, equals('declining'));
    });

    test('5. Scenario: High recent training load (ACWR spike)', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: 8.0,
        hrvZScore: 0.2,
        rhrDeltaBpm: 0.0,
        acuteChronicWorkloadRatio: 1.75, // Dangerous acute workload spike
        recentAverageRPE: 9.0,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.contributingFactors, contains('acute_workload_spike_exceeds_chronic'));
      expect(recovery.contributingFactors, contains('high_perceived_exertion_recent_sessions'));
      expect(recovery.fatigueScore, greaterThanOrEqualTo(60.0));
    });

    test('6. Scenario: Missing HRV signal handles absence and reduces confidence', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: 8.0,
        hrvZScore: null, // HRV sensor missing / off
        rhrDeltaBpm: -1.0,
        acuteChronicWorkloadRatio: 1.0,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.contributingFactors, contains('hrv_signal_unavailable'));
      expect(recovery.confidenceScore, lessThanOrEqualTo(0.65));
      expect(recovery.recoveryScore, greaterThan(0.0)); // Functionality does not crash
    });

    test('7. Scenario: Missing sleep signal handles absence and reduces confidence', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: null, // Sleep tracker not worn
        hrvZScore: 1.0,
        rhrDeltaBpm: 0.0,
        acuteChronicWorkloadRatio: 1.0,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.contributingFactors, contains('sleep_signal_unavailable'));
      expect(recovery.confidenceScore, lessThanOrEqualTo(0.65));
    });

    test('8. Scenario: Conflicting signals (High HRV but high fatigue & sleep debt)', () {
      const input = RecoveryEvaluationInput(
        sleepDurationHours: 4.5,
        sleepDebtHours: 3.5,
        hrvZScore: 1.2, // Paradoxically elevated HRV
        rhrDeltaBpm: 4.0,
        acuteChronicWorkloadRatio: 1.6,
        signalQuality: DataQuality.observed,
      );

      final recovery = KineticRecoveryEngine.estimate(input);
      expect(recovery.contributingFactors, contains('conflicting_autonomic_signals_detected'));
      expect(recovery.recommendedAction, isIn(['active_recovery', 'rest', 'train_light']));
    });

    test('9. Scenario: Noisy measurements / Data quality modulation & pluggable architecture', () {
      // 1. Stale / noisy signal input
      const noisyInput = RecoveryEvaluationInput(
        sleepDurationHours: 7.0,
        hrvZScore: 0.0,
        rhrDeltaBpm: 0.0,
        signalQuality: DataQuality.stale,
      );

      final staleResult = KineticRecoveryEngine.estimate(noisyInput);
      expect(staleResult.dataQuality, equals('stale'));
      expect(staleResult.confidenceScore, equals(0.40));

      // 2. Pluggable model verification: Custom mock model injection
      final customModel = _MockBayesianRecoveryModel();
      KineticRecoveryEngine.setModel(customModel);
      expect(KineticRecoveryEngine.version, equals('bayesian_recovery_mock_v1'));

      final customResult = KineticRecoveryEngine.estimate(noisyInput);
      expect(customResult.state, equals('bayesian_optimal'));
      expect(customResult.modelVersion, equals('bayesian_recovery_mock_v1'));

      // Reset to default
      KineticRecoveryEngine.resetModel();
      expect(KineticRecoveryEngine.version, equals('recovery_model_v1'));
    });
  });
}

class _MockBayesianRecoveryModel implements RecoveryModel {
  @override
  String get modelVersion => 'bayesian_recovery_mock_v1';

  @override
  RecoveryState estimate(RecoveryEvaluationInput input) {
    return const RecoveryState(
      state: 'bayesian_optimal',
      direction: 'improving',
      contributingFactors: ['bayesian_prior_updated'],
      recommendedAction: 'train_hard',
      dataQuality: 'high',
      recoveryScore: 90.0,
      readinessScore: 90.0,
      fatigueScore: 10.0,
      confidenceScore: 0.99,
      modelVersion: 'bayesian_recovery_mock_v1',
    );
  }
}
