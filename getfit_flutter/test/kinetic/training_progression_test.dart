import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/math/training_load.dart';
import 'package:kinetic_precision/kinetic/intelligence/training_engine.dart';
import 'package:kinetic_precision/kinetic/intelligence/progression_engine.dart';
import 'package:kinetic_precision/kinetic/services/progression_service.dart';

void main() {
  group('Phase 6: Training & Progression Engine Tests', () {
    final testExercise = const Exercise(
      id: 'ex_bench',
      name: 'Barbell Bench Press',
      movementPattern: MovementPattern.horizontalPush,
      primaryMuscles: [MuscleGroup.chest, MuscleGroup.triceps],
      isCompound: true,
    );

    final favorableRecovery = LatentPhysiologicalState(
      recoveryScore: 88.0,
      fatigueScore: 18.0,
      readinessScore: 90.0,
      adaptationScore: 85.0,
      energyScore: 88.0,
      direction: TrendDirection.improving,
      contributingFactors: ['favorable_hrv'],
      dataQualityScore: 1.0,
      timestamp: DateTime.now(),
      modelVersion: 'v1',
    );

    test('1. Training Load Models: Volume load, Session-RPE, and ACWR calculation', () {
      final volumeModel = VolumeLoadModel();
      final session = TrainingSessionData(
        durationMinutes: 60,
        completedSets: [
          {'reps': 10, 'weightKg': 100.0}, // 1000 kg
          {'reps': 8, 'weightKg': 100.0},  // 800 kg
          {'reps': 6, 'weightKg': 100.0},  // 600 kg
        ],
      );
      expect(volumeModel.calculateSessionLoad(session), equals(2400.0));

      final rpeModel = RPEBasedLoadModel();
      final rpeSession = const TrainingSessionData(
        durationMinutes: 45,
        sessionRPE: 8.0,
      );
      expect(rpeModel.calculateSessionLoad(rpeSession), equals(360.0));

      final dailyHistory = [
        ...List.filled(21, 300.0),
        ...List.filled(7, 600.0),
      ];
      final acwr = TrainingLoadEngine.computeACWR(dailyHistory);
      expect(acwr, greaterThan(1.3));
    });

    test('2. In-Workout Dynamic Autoregulation: Reactive adjustments for overshoot and undershoot', () {
      const prescription = ExercisePrescription(
        exerciseId: 'ex_bench',
        exerciseName: 'Barbell Bench Press',
        targetSets: 3,
        targetReps: 8,
        targetLoadKg: 80.0,
        targetRPE: 8.0,
        reasonCode: 'hypertrophy_push',
      );

      // Overshoot: 80kg x 6 @ RPE 9.5 -> down-adjusts load to 75.0kg
      final overshootSet = ExerciseSet(
        setNumber: 1,
        exerciseId: 'ex_bench',
        prescribedLoadKg: 80.0,
        actualLoadKg: 80.0,
        prescribedReps: 8,
        actualReps: 6,
        targetRPE: 8.0,
        actualRPE: 9.5,
        timestamp: DateTime.now(),
      );

      final downAdj = KineticTrainingEngine.autoregulateNextSet(
        prescription: prescription,
        previousSet: overshootSet,
        nextSetNumber: 2,
      );
      expect(downAdj.adjustedLoadKg, equals(75.0));
      expect(downAdj.reasonCode, equals('rpe_overshoot_fatigue_mitigation'));

      // Undershoot: 80kg x 8 @ RPE 6.0 (target 8.0) -> up-adjusts load to 82.5kg
      final undershootSet = ExerciseSet(
        setNumber: 1,
        exerciseId: 'ex_bench',
        prescribedLoadKg: 80.0,
        actualLoadKg: 80.0,
        prescribedReps: 8,
        actualReps: 8,
        targetRPE: 8.0,
        actualRPE: 6.0,
        timestamp: DateTime.now(),
      );

      final upAdj = KineticTrainingEngine.autoregulateNextSet(
        prescription: prescription,
        previousSet: undershootSet,
        nextSetNumber: 2,
      );
      expect(upAdj.adjustedLoadKg, equals(82.5));
      expect(upAdj.reasonCode, equals('performance_above_expected_load_ramp'));
    });

    test('3. Progression Decision: increase_load when rep ceiling is achieved', () {
      final sets = [
        ExerciseSet(setNumber: 1, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 10, actualReps: 10, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 2, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 10, actualReps: 10, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 3, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 10, actualReps: 10, targetRPE: 8.0, actualRPE: 8.5, timestamp: DateTime.now()),
      ];

      final rec = KineticProgressionEngine.evaluateProgression(
        exercise: testExercise,
        recentSets: sets,
        recoveryState: favorableRecovery,
        minRepTarget: 6,
        maxRepTarget: 10,
      );

      expect(rec.decision, equals('increase_load'));
      expect(rec.recommendedLoadKg, equals(82.5)); // +2.5kg increment
      expect(rec.recommendedReps, equals(6)); // reset to rep floor
      expect(rec.evidence, contains('completed_reps_ge_10'));
    });

    test('4. Progression Decision: increase_reps when working up the double-progression range', () {
      final sets = [
        ExerciseSet(setNumber: 1, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 7, actualReps: 7, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 2, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 7, actualReps: 7, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
      ];

      final rec = KineticProgressionEngine.evaluateProgression(
        exercise: testExercise,
        recentSets: sets,
        recoveryState: favorableRecovery,
        minRepTarget: 6,
        maxRepTarget: 10,
      );

      expect(rec.decision, equals('increase_reps'));
      expect(rec.recommendedLoadKg, equals(80.0));
      expect(rec.recommendedReps, equals(8)); // +1 rep progression target
    });

    test('5. Progression Decision: reduce_load on failure / overshoot', () {
      final failedSets = [
        ExerciseSet(setNumber: 1, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 6, actualReps: 4, targetRPE: 8.0, actualRPE: 10.0, timestamp: DateTime.now()),
      ];

      final rec = KineticProgressionEngine.evaluateProgression(
        exercise: testExercise,
        recentSets: failedSets,
        recoveryState: favorableRecovery,
        minRepTarget: 6,
      );

      expect(rec.decision, equals('reduce_load'));
      expect(rec.recommendedLoadKg, lessThan(80.0));
      expect(rec.reason, equals('rpe_overshoot_load_reduction'));
    });

    test('6. Progression Decision: reduce_volume on intra-session fatigue accumulation', () {
      final fatigueSets = [
        ExerciseSet(setNumber: 1, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 8, actualReps: 8, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 2, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 8, actualReps: 8, targetRPE: 8.0, actualRPE: 8.5, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 3, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 8, actualReps: 7, targetRPE: 8.0, actualRPE: 9.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 4, exerciseId: 'ex_bench', prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 8, actualReps: 6, targetRPE: 8.0, actualRPE: 9.5, timestamp: DateTime.now()),
      ];

      final rec = KineticProgressionEngine.evaluateProgression(
        exercise: testExercise,
        recentSets: fatigueSets,
        recoveryState: favorableRecovery,
      );

      expect(rec.decision, equals('reduce_volume'));
      expect(rec.recommendedSets, equals(3)); // Down from 4 to 3 sets
      expect(rec.reason, equals('intra_session_fatigue_volume_reduction'));
    });

    test('7. Progression Decision: deload & recover on systemic fatigue / depletion', () {
      final fatiguedRecovery = LatentPhysiologicalState(
        recoveryScore: 38.0,
        fatigueScore: 78.0,
        readinessScore: 40.0,
        adaptationScore: 45.0,
        energyScore: 40.0,
        direction: TrendDirection.declining,
        contributingFactors: ['chronic_fatigue'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'v1',
      );

      final sets = [
        ExerciseSet(setNumber: 1, exerciseId: 'ex_bench', prescribedLoadKg: 100.0, actualLoadKg: 100.0, prescribedReps: 8, actualReps: 8, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
      ];

      // Deload check
      final deloadRec = KineticProgressionEngine.evaluateProgression(
        exercise: testExercise,
        recentSets: sets,
        recoveryState: fatiguedRecovery,
      );
      expect(deloadRec.decision, equals('deload'));
      expect(deloadRec.recommendedLoadKg, equals(80.0)); // 20% deload

      // Depleted recover check
      final depletedRecovery = LatentPhysiologicalState(
        recoveryScore: 22.0, // < 30.0
        fatigueScore: 90.0,
        readinessScore: 20.0,
        adaptationScore: 30.0,
        energyScore: 20.0,
        direction: TrendDirection.declining,
        contributingFactors: ['exhaustion'],
        dataQualityScore: 1.0,
        timestamp: DateTime.now(),
        modelVersion: 'v1',
      );

      final recoverRec = KineticProgressionEngine.evaluateProgression(
        exercise: testExercise,
        recentSets: sets,
        recoveryState: depletedRecovery,
      );
      expect(recoverRec.decision, equals('recover'));
      expect(recoverRec.recommendedLoadKg, equals(0.0));
      expect(recoverRec.reason, contains('systemic_depletion'));
    });

    test('8. ProgressionService Lifecycle: generate workout, record performance, evaluate progression, and update future prescription', () {
      final progressionService = ProgressionService();
      const userGoal = UserGoal(id: 'g1', userId: 'u_prog_test', type: GoalType.hypertrophy);

      // 1. Generate workout session
      final initialSession = progressionService.generateWorkout(
        userId: 'u_prog_test',
        goal: userGoal,
        focus: TrainingFocus.hypertrophy,
        readinessState: favorableRecovery,
      );
      expect(initialSession.prescriptions.isNotEmpty, isTrue);
      final firstPrescription = initialSession.prescriptions.first;

      // 2. Simulate completed sets exceeding rep ceiling (80kg x 12, 12, 12)
      final completedSets = [
        ExerciseSet(setNumber: 1, exerciseId: firstPrescription.exerciseId, prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 8, actualReps: 12, targetRPE: 8.0, actualRPE: 7.5, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 2, exerciseId: firstPrescription.exerciseId, prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 8, actualReps: 12, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
        ExerciseSet(setNumber: 3, exerciseId: firstPrescription.exerciseId, prescribedLoadKg: 80.0, actualLoadKg: 80.0, prescribedReps: 8, actualReps: 12, targetRPE: 8.0, actualRPE: 8.0, timestamp: DateTime.now()),
      ];

      // 3. Evaluate progression
      final progression = progressionService.evaluateProgression(
        exercise: testExercise,
        recentSets: completedSets,
        recoveryState: favorableRecovery,
        minRepTarget: 8,
        maxRepTarget: 12,
      );
      expect(progression.decision, equals('increase_load'));
      expect(progression.recommendedLoadKg, equals(82.5));

      // 4. Apply progression to next planned workout
      final nextSession = progressionService.generateWorkout(
        userId: 'u_prog_test',
        goal: userGoal,
        focus: TrainingFocus.hypertrophy,
        readinessState: favorableRecovery,
      );

      final updatedSession = progressionService.applyProgressionToSession(
        session: nextSession,
        progressions: {firstPrescription.exerciseId: progression},
      );

      final updatedPrescription = updatedSession.prescriptions.firstWhere((p) => p.exerciseId == firstPrescription.exerciseId);
      expect(updatedPrescription.targetLoadKg, equals(82.5));
      expect(updatedPrescription.reasonCode, contains('progressive_overload_increase_load'));
    });
  });
}
