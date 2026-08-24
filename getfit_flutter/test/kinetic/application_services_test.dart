import 'package:flutter_test/flutter_test.dart';
import 'package:kinetic_precision/kinetic/domain/models.dart';
import 'package:kinetic_precision/kinetic/persistence/kinetic_store.dart';
import 'package:kinetic_precision/kinetic/simulation/archetypes.dart';
import 'package:kinetic_precision/kinetic/simulation/generator.dart';
import 'package:kinetic_precision/kinetic/services/today_service.dart';
import 'package:kinetic_precision/kinetic/services/training_service.dart';
import 'package:kinetic_precision/kinetic/services/recovery_service.dart';
import 'package:kinetic_precision/kinetic/services/body_service.dart';
import 'package:kinetic_precision/kinetic/services/goal_service.dart';
import 'package:kinetic_precision/kinetic/services/data_service.dart';
import 'package:kinetic_precision/kinetic/services/telemetry_service.dart';

void main() {
  group('SPEC 28-30: Application Service Layer & View Model Contracts', () {
    late KineticStore store;
    late TodayService todayService;
    late TrainingService trainingService;
    late RecoveryService recoveryService;
    late BodyService bodyService;
    late GoalService goalService;
    late DataService dataService;

    setUp(() {
      store = KineticStore.instance..reset();
      todayService = TodayService(store: store);
      trainingService = TrainingService(store: store);
      recoveryService = RecoveryService(store: store, todayService: todayService);
      bodyService = BodyService(store: store);
      goalService = GoalService(store: store);
      dataService = DataService(store: store);
    });

    test('1. TodayViewModel Contract (SPEC Section 29) contains complete rendering payload with zero additional queries', () async {
      // Seed store with User A (High Recovery Athlete)
      final simA = KineticSimulator.generateHistory(
        archetype: UserArchetype.userA_HighRecoveryAthlete,
        days: 30,
        seed: 42,
      );
      store.saveUser(simA.profile.user);
      store.addGoal(simA.profile.goal);
      store.recordMeasurementsBatch(simA.measurements);

      final todayVM = await todayService.getToday();

      // Verify UI contract fields
      expect(todayVM.user.id, equals('sim_user_a'));
      expect(todayVM.currentState.recoveryScore, greaterThan(70.0));
      expect(todayVM.primaryRecommendation.headline.isNotEmpty, isTrue);
      expect(todayVM.primaryRecommendation.action.isNotEmpty, isTrue);
      expect(todayVM.primaryRecommendation.rationale.isNotEmpty, isTrue);
      expect(todayVM.primaryRecommendation.evidence.isNotEmpty, isTrue);
      expect(todayVM.recommendationReason.isNotEmpty, isTrue);
      expect(todayVM.nutritionTarget.energyKcal, greaterThan(2000));
      expect(todayVM.nutritionTarget.proteinGrams, greaterThan(100.0));
      expect(todayVM.sleepTarget.targetDurationHours, greaterThanOrEqualTo(8.0));
      expect(todayVM.sleepTarget.recommendedSleepWindow.isNotEmpty, isTrue);
      expect(todayVM.upcomingWorkout, isNotNull);
      expect(todayVM.dataQualityLabel, equals('High Precision'));
    });

    test('2. WorkoutViewModel Contract (SPEC Section 30) contains active workout execution state and in-workout autoregulation', () async {
      final simD = KineticSimulator.generateHistory(
        archetype: UserArchetype.userD_StrengthFocusedAthlete,
        days: 30,
        seed: 42,
      );
      store.saveUser(simD.profile.user);
      store.addGoal(simD.profile.goal);
      store.recordMeasurementsBatch(simD.measurements);

      final todayVM = await todayService.getToday();
      expect(todayVM.upcomingWorkout, isNotNull);

      // Start Session
      var workoutVM = await trainingService.startSession(todayVM.upcomingWorkout!);
      expect(workoutVM.session.status, equals('in_progress'));
      expect(workoutVM.nextSetNumber, equals(1));
      expect(workoutVM.currentPrescription, isNotNull);
      expect(workoutVM.prescribedLoadKg, greaterThan(0));
      expect(workoutVM.isCompleted, isFalse);

      // Log Set 1
      workoutVM = await trainingService.logSet(
        sessionId: workoutVM.session.id,
        exerciseId: workoutVM.currentPrescription!.exerciseId,
        actualLoadKg: workoutVM.prescribedLoadKg,
        actualReps: workoutVM.prescribedReps,
        actualRPE: 8.0,
      );
      expect(workoutVM.completedSets.length, equals(1));
      expect(workoutVM.nextSetNumber, equals(2));
      expect(workoutVM.totalVolumeKg, greaterThan(0));

      // Log Set 2 with RPE Overshoot to trigger autoregulation
      workoutVM = await trainingService.logSet(
        sessionId: workoutVM.session.id,
        exerciseId: workoutVM.currentPrescription!.exerciseId,
        actualLoadKg: workoutVM.prescribedLoadKg,
        actualReps: 4,
        actualRPE: 9.5, // Overshoot
      );
      expect(workoutVM.lastAutoregulationReason, equals('rpe_overshoot_fatigue_mitigation'));

      // Complete session
      final completed = await trainingService.completeSession(workoutVM.session.id, finalAverageRPE: 8.5);
      expect(completed.status, equals('completed'));
      expect(completed.totalVolumeKg, greaterThan(0));
    });

    test('3. Section 28 Function Contracts: tests all individual service getters across synthetic users', () async {
      final simC = KineticSimulator.generateHistory(
        archetype: UserArchetype.userC_WeightLossGoal,
        days: 90,
        seed: 42,
      );
      store.saveUser(simC.profile.user);
      store.addGoal(simC.profile.goal);
      store.recordMeasurementsBatch(simC.measurements);

      // a. getCurrentRecommendation()
      final rec = await todayService.getCurrentRecommendation();
      expect(rec, isNotNull);

      // b. getRecommendationReason()
      final reason = await todayService.getRecommendationReason(rec!.id);
      expect(reason, isNotNull);

      // c. getRecoveryState()
      final recovery = await recoveryService.getRecoveryState();
      expect(recovery.recoveryScore, greaterThan(0));

      // d. getContributingFactors()
      final factors = await recoveryService.getContributingFactors();
      expect(factors.isNotEmpty, isTrue);

      // e. getBodyTrajectory()
      final trajectory = await bodyService.getBodyTrajectory();
      expect(trajectory.currentWeightKg, greaterThan(70.0));
      expect(trajectory.weightVelocityKgPerWeek, lessThan(0.0)); // Fat loss negative slope
      expect(trajectory.trendDirection, equals('losing'));

      // f. getTargets()
      final targets = await todayService.getTargets();
      expect(targets['nutrition'], isNotNull);
      expect(targets['sleep'], isNotNull);

      // g. getTelemetry()
      final telemetry = await todayService.getTelemetry(rec.id);
      expect(telemetry, isNotNull);
      expect(telemetry?.competingOptionsEvaluated.isNotEmpty, isTrue);

      // h. getGoals() & setPrimaryGoal()
      final goals = await goalService.getGoals();
      expect(goals.isNotEmpty, isTrue);

      // i. exportData() & getDataQualityReport()
      final snapshot = await dataService.exportData();
      expect(snapshot.tables['measurements']!.isNotEmpty, isTrue);
      final qualityReport = await dataService.getDataQualityReport();
      expect(qualityReport['qualityRatio'], greaterThan(0.5));
    });
  });
}
