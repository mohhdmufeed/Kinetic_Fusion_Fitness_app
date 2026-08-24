import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/persistence/kinetic_store.dart';
import 'package:kinetic_precision/kinetic/services/kinetic_app_facade.dart';
import 'package:kinetic_precision/kinetic/contracts/app_view_models.dart';

void main() {
  group('Phase 11: Frontend Application Contract Layer Tests', () {
    late KineticAppFacade facade;
    late KineticStore store;

    setUp(() {
      store = KineticStore.instance;
      facade = KineticAppFacade(store: store);

      // Seed initial active test user
      store.saveUser(KineticUser(
        id: 'u_facade_test',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        sex: 'male',
        age: 28,
        heightCm: 180,
        weightKg: 80.0,
      ));

      store.addGoal(const UserGoal(
        id: 'g_facade_test',
        userId: 'u_facade_test',
        type: GoalType.hypertrophy,
        targetValue: 83.0,
      ));
    });

    test('1. getToday(): Returns complete TodayViewModel with zero raw SQL leakage', () async {
      // Seed some measurements
      await facade.recordMeasurement(metric: 'hrv_rmssd', value: 75.0, unit: 'ms');
      await facade.recordMeasurement(metric: 'rhr', value: 52.0, unit: 'bpm');
      await facade.recordMeasurement(metric: 'sleep_duration_hrs', value: 8.2, unit: 'hours');

      final result = await facade.getToday();
      expect(result.isSuccess, isTrue);

      final vm = result.data;
      expect(vm.user.id, equals('u_facade_test'));
      expect(vm.currentState.readinessScore, greaterThan(0));
      expect(vm.primaryRecommendation.action.isNotEmpty, isTrue);
      expect(vm.nutritionTarget.energyKcal, greaterThan(1500));
      expect(vm.sleepTarget.targetDurationHours, greaterThan(6.0));
      expect(vm.dataQualityLabel.isNotEmpty, isTrue);
    });

    test('2. Workout Flow: startWorkout -> getNextSet -> completeSet -> completeWorkout', () async {
      // 1. Start Workout
      final startRes = await facade.startWorkout(focus: TrainingFocus.hypertrophy);
      expect(startRes.isSuccess, isTrue);
      final workoutVM = startRes.data;
      final sessionId = workoutVM.session.id;
      expect(workoutVM.session.status, equals('in_progress'));

      // 2. Query getCurrentWorkout
      final currentRes = await facade.getCurrentWorkout();
      expect(currentRes.isSuccess, isTrue);
      expect(currentRes.data.session.id, equals(sessionId));

      // 3. Query getNextSet
      final nextSetRes = await facade.getNextSet();
      expect(nextSetRes.isSuccess, isTrue);
      final nextSet = nextSetRes.data;
      expect(nextSet.setNumber, equals(1));
      expect(nextSet.targetLoadKg, greaterThan(0));
      expect(nextSet.targetReps, greaterThan(0));

      // 4. Complete Set
      final setRes = await facade.completeSet(
        sessionId: sessionId,
        exerciseId: nextSet.exerciseId,
        actualLoadKg: nextSet.targetLoadKg,
        actualReps: nextSet.targetReps,
        actualRPE: 8.0,
      );
      expect(setRes.isSuccess, isTrue);
      expect(setRes.data.completedSets.length, equals(1));
      expect(setRes.data.totalVolumeKg, greaterThan(0));

      // 5. Complete Workout
      final completeRes = await facade.completeWorkout(sessionId);
      expect(completeRes.isSuccess, isTrue);
      expect(completeRes.data.session.status, equals('completed'));
    });

    test('3. Recommendation & WHY Explanation: getCurrentRecommendation -> getRecommendationReason', () async {
      await facade.getToday(); // Triggers recommendation generation & trace storage

      final recRes = await facade.getCurrentRecommendation();
      expect(recRes.isSuccess, isTrue);
      final rec = recRes.data;
      expect(rec.action.isNotEmpty, isTrue);
      expect(rec.headline.isNotEmpty, isTrue);

      final whyRes = await facade.getRecommendationReason(rec.id);
      expect(whyRes.isSuccess, isTrue);
      final why = whyRes.data;
      expect(why.recommendationId, equals(rec.id));
      expect(why.selectedDecision, equals(rec.action));
      expect(why.competingOptionsEvaluated.isNotEmpty, isTrue);
      expect(why.reasonCodes.isNotEmpty, isTrue);
    });

    test('4. Query Contracts: getRecoveryState, getBodyTrajectory, getTargets, getTelemetry', () async {
      // Seed bodyweight timeline
      final now = DateTime.now();
      await facade.recordMeasurement(metric: 'weight_kg', value: 81.5, unit: 'kg', timestamp: now.subtract(const Duration(days: 14)));
      await facade.recordMeasurement(metric: 'weight_kg', value: 80.8, unit: 'kg', timestamp: now.subtract(const Duration(days: 7)));
      await facade.recordMeasurement(metric: 'weight_kg', value: 80.0, unit: 'kg', timestamp: now);

      // 1. Recovery State
      final recovRes = await facade.getRecoveryState();
      expect(recovRes.isSuccess, isTrue);
      expect(recovRes.data.recoveryScore, greaterThan(0));

      // 2. Body Trajectory
      final trajRes = await facade.getBodyTrajectory();
      expect(trajRes.isSuccess, isTrue);
      final traj = trajRes.data;
      expect(traj.currentWeightKg, equals(80.0));
      expect(traj.targetWeightKg, equals(83.0));
      expect(traj.trendDirection, equals('losing'));

      // 3. Targets
      final targetRes = await facade.getTargets();
      expect(targetRes.isSuccess, isTrue);
      expect(targetRes.data.targetCaloriesKcal, greaterThan(1500));
      expect(targetRes.data.targetProteinGrams, greaterThan(50));
      expect(targetRes.data.targetSleepDurationHours, greaterThan(6.0));

      // 4. Telemetry
      final telemRes = await facade.getTelemetry();
      expect(telemRes.isSuccess, isTrue);
      expect(telemRes.data.totalMeasurementsRecorded, greaterThan(0));
      expect(telemRes.data.dataStorageMode, contains('Local-Only'));
    });

    test('5. Structured Error Handling: Validation and State Transition Errors', () async {
      // 1. Validation Error on Negative Weight
      final invalidUserRes = await facade.createUser(KineticUser(
        id: 'u_invalid',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        weightKg: -50.0,
      ));
      expect(invalidUserRes.isFailure, isTrue);
      expect(invalidUserRes.errorOrNull, isA<ValidationError>());

      // 2. Validation Error on Out-of-Range RPE
      final invalidRPERes = await facade.completeSet(
        sessionId: 'dummy_sess',
        exerciseId: 'ex_1',
        actualLoadKg: 100,
        actualReps: 5,
        actualRPE: 12.5, // Invalid > 10
      );
      expect(invalidRPERes.isFailure, isTrue);
      expect(invalidRPERes.errorOrNull, isA<ValidationError>());

      // 3. Invalid State Transition Error: complete set on non-existent session
      final invalidSetRes = await facade.completeSet(
        sessionId: 'non_existent_session',
        exerciseId: 'ex_1',
        actualLoadKg: 100,
        actualReps: 5,
        actualRPE: 8.0,
      );
      expect(invalidSetRes.isFailure, isTrue);
      expect(invalidSetRes.errorOrNull, isA<InvalidStateTransitionError>());

      // 4. Missing Data Error on non-existent trace
      final missingTraceRes = await facade.getRecommendationReason('rec_unknown_999');
      expect(missingTraceRes.isFailure, isTrue);
      expect(missingTraceRes.errorOrNull, isA<MissingDataError>());
    });

    test('6. User Autonomy & Overrides: acceptRecommendation & overrideRecommendation', () async {
      await facade.getToday();
      final rec = (await facade.getCurrentRecommendation()).data;

      // 1. Accept
      final acceptRes = await facade.acceptRecommendation(rec.id);
      expect(acceptRes.isSuccess, isTrue);

      // 2. Override
      final overrideRes = await facade.overrideRecommendation(
        recommendationId: rec.id,
        overrideAction: 'train_hard',
        overrideReason: 'feeling_strong',
        notes: 'Double espresso pre-workout',
      );
      expect(overrideRes.isSuccess, isTrue);
    });
  });
}
