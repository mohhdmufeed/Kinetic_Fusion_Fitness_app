import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:kinetic_precision/kinetic/kinetic_core.dart';
import 'package:kinetic_precision/kinetic/data/database_manager.dart';
import 'package:kinetic_precision/kinetic/data/migration.dart';
import 'package:kinetic_precision/kinetic/data/migrations/migration_v1_measurements_events.dart';

void main() {
  group('Phase 1: Domain Model & Database Schema Integration Tests', () {
    late KineticDatabaseManager dbManager;
    late MigrationRegistry registry;
    late UserRepository userRepo;
    late GoalRepository goalRepo;
    late ExerciseRepository exerciseRepo;
    late SessionRepository sessionRepo;
    late WorkoutRepository workoutRepo;

    setUp(() async {
      registry = MigrationRegistry();
      registry.register(MigrationV1MeasurementsEvents());
      registry.register(MigrationV2DomainModels());

      dbManager = KineticDatabaseManager.inMemory(registry: registry);
      await dbManager.initialize();
      await dbManager.migrateToLatest();

      userRepo = UserRepository(dbManager.executor);
      goalRepo = GoalRepository(dbManager.executor);
      exerciseRepo = ExerciseRepository(dbManager.executor);
      sessionRepo = SessionRepository(dbManager.executor);
      workoutRepo = WorkoutRepository(sessionRepo);
    });

    tearDown(() async {
      await dbManager.close();
    });

    test('1. Migration V2: Forward and rollback schema migrations work correctly', () async {
      // 1. Rollback to v1 (down)
      await dbManager.migrateTo(1);
      var currentVer = await dbManager.getCurrentVersion();
      expect(currentVer, equals(1));

      // Verify kinetic_users was dropped during down migration
      final tableCheck = await dbManager.executor.runSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='kinetic_users';",
        [],
      );
      expect(tableCheck.isEmpty, isTrue);

      // 2. Rollback to v0
      await dbManager.migrateTo(0);
      currentVer = await dbManager.getCurrentVersion();
      expect(currentVer, equals(0));

      // 3. Migrate back to latest (up)
      await dbManager.migrateToLatest();
      currentVer = await dbManager.getCurrentVersion();
      expect(currentVer, equals(2));

      // select should succeed now
      final userRows = await dbManager.executor.runSelect('SELECT * FROM kinetic_users;', []);
      expect(userRows, isEmpty);
    });

    test('2. User: Create and update user profile data persists locally', () async {
      final user = KineticUser(
        id: 'user_123',
        createdAt: DateTime.utc(2026, 8, 18, 12, 0),
        updatedAt: DateTime.utc(2026, 8, 18, 12, 0),
        sex: 'female',
        age: 29,
        heightCm: 168.0,
        weightKg: 62.5,
        units: 'metric',
        timezone: 'Asia/Kolkata',
        preferences: {'night_mode': true},
      );

      await userRepo.createUser(user);

      var fetched = await userRepo.getUser('user_123');
      expect(fetched, isNotNull);
      expect(fetched!.id, equals('user_123'));
      expect(fetched.age, equals(29));
      expect(fetched.weightKg, equals(62.5));
      expect(fetched.timezone, equals('Asia/Kolkata'));
      expect(fetched.preferences['night_mode'], isTrue);

      final updated = fetched.copyWith(
        age: 30,
        weightKg: 63.0,
      );

      await userRepo.updateUser(updated);

      fetched = await userRepo.getUser('user_123');
      expect(fetched!.age, equals(30));
      expect(fetched.weightKg, equals(63.0));
    });

    test('3. Goal: Create and list user goals correctly', () async {
      // Create user first
      final user = KineticUser(
        id: 'user_goal_test',
        createdAt: DateTime.utc(2026, 8, 18, 12, 0),
        updatedAt: DateTime.utc(2026, 8, 18, 12, 0),
      );
      await userRepo.createUser(user);

      final goal1 = UserGoal(
        id: 'goal_hypertrophy',
        userId: 'user_goal_test',
        type: GoalType.hypertrophy,
        priority: 1,
        targetValue: 70.0,
        targetMetric: 'weight_kg',
        deadline: DateTime.utc(2026, 12, 31),
        constraints: {'max_sessions_per_week': 4},
      );

      final goal2 = UserGoal(
        id: 'goal_cardio',
        userId: 'user_goal_test',
        type: GoalType.endurance,
        priority: 2,
        isActive: false,
      );

      await goalRepo.createGoal(goal1);
      await goalRepo.createGoal(goal2);

      final activeGoals = await goalRepo.getActiveGoals('user_goal_test');
      expect(activeGoals.length, equals(1));
      expect(activeGoals.first.id, equals('goal_hypertrophy'));
      expect(activeGoals.first.constraints['max_sessions_per_week'], equals(4));

      final allGoals = await goalRepo.getAllGoals('user_goal_test');
      expect(allGoals.length, equals(2));
    });

    test('4. Exercise: Insert and query exercise objects by movement pattern', () async {
      final exercise = Exercise(
        id: 'ex_squat',
        name: 'Barbell Squat',
        movementPattern: MovementPattern.squat,
        primaryMuscles: [MuscleGroup.quadriceps, MuscleGroup.glutes],
        equipment: ['barbell', 'rack'],
        defaultRestSeconds: 120.0,
        isCompound: true,
      );

      await exerciseRepo.createExercise(exercise);

      final fetched = await exerciseRepo.getExercise('ex_squat');
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Barbell Squat'));
      expect(fetched.movementPattern, equals(MovementPattern.squat));
      expect(fetched.primaryMuscles.contains(MuscleGroup.quadriceps), isTrue);

      final queryResults = await exerciseRepo.queryExercises(movementPattern: MovementPattern.squat);
      expect(queryResults.length, equals(1));
      expect(queryResults.first.id, equals('ex_squat'));
    });

    test('5. Session Lifecycle: Create workout, prescriptions, log sets, and complete session', () async {
      // 1. Prep User and Exercise
      final user = KineticUser(
        id: 'athlete_1',
        createdAt: DateTime.utc(2026, 8, 18, 12, 0),
        updatedAt: DateTime.utc(2026, 8, 18, 12, 0),
      );
      await userRepo.createUser(user);

      final exercise = Exercise(
        id: 'ex_bench',
        name: 'Dumbbell Bench Press',
        movementPattern: MovementPattern.horizontalPush,
        primaryMuscles: [MuscleGroup.chest, MuscleGroup.triceps],
      );
      await exerciseRepo.createExercise(exercise);

      // 2. Create Workout Session with Prescription
      final session = WorkoutSession(
        id: 'session_abc',
        userId: 'athlete_1',
        startTime: DateTime.utc(2026, 8, 18, 14, 0),
        goal: GoalType.strength,
        focus: TrainingFocus.strength,
        status: 'planned',
        prescriptions: [
          ExercisePrescription(
            exerciseId: 'ex_bench',
            exerciseName: 'Dumbbell Bench Press',
            targetSets: 3,
            targetReps: 8,
            targetLoadKg: 30.0,
            targetRPE: 8.5,
            restSeconds: 90,
            tempo: '3-1-1-0',
            reasonCode: 'primary_horizontal_push',
          ),
        ],
      );

      await sessionRepo.createSession(session);

      var fetchedSession = await sessionRepo.getSession('session_abc');
      expect(fetchedSession, isNotNull);
      expect(fetchedSession!.status, equals('planned'));
      expect(fetchedSession.prescriptions.length, equals(1));
      expect(fetchedSession.prescriptions.first.exerciseId, equals('ex_bench'));
      expect(fetchedSession.prescriptions.first.targetLoadKg, equals(30.0));

      // 3. Record completed sets
      final set1 = ExerciseSet(
        setNumber: 1,
        exerciseId: 'ex_bench',
        prescribedLoadKg: 30.0,
        actualLoadKg: 30.0,
        prescribedReps: 8,
        actualReps: 8,
        targetRPE: 8.5,
        actualRPE: 8.0,
        restSeconds: 90,
        timestamp: DateTime.utc(2026, 8, 18, 14, 10),
      );

      final set2 = ExerciseSet(
        setNumber: 2,
        exerciseId: 'ex_bench',
        prescribedLoadKg: 30.0,
        actualLoadKg: 30.0,
        prescribedReps: 8,
        actualReps: 8,
        targetRPE: 8.5,
        actualRPE: 9.0,
        restSeconds: 90,
        timestamp: DateTime.utc(2026, 8, 18, 14, 15),
      );

      await sessionRepo.recordSet('session_abc', set1);
      await sessionRepo.recordSet('session_abc', set2);

      fetchedSession = await sessionRepo.getSession('session_abc');
      expect(fetchedSession!.completedSets.length, equals(2));
      expect(fetchedSession.completedSets[0].actualRPE, equals(8.0));
      expect(fetchedSession.completedSets[1].actualRPE, equals(9.0));

      // 4. Complete Session
      await sessionRepo.completeSession(
        sessionId: 'session_abc',
        endTime: DateTime.utc(2026, 8, 18, 14, 45),
        averageRPE: 8.5,
        trainingLoad: 480.0,
      );

      fetchedSession = await sessionRepo.getSession('session_abc');
      expect(fetchedSession!.status, equals('completed'));
      expect(fetchedSession.averageRPE, equals(8.5));
      expect(fetchedSession.trainingLoad, equals(480.0));
      expect(fetchedSession.endTime, isNotNull);

      // Verify overall history retrieval
      final history = await sessionRepo.getSessions('athlete_1');
      expect(history.length, equals(1));
      expect(history.first.id, equals('session_abc'));
    });

    test('6. Transactions: Rollback completely reverts changes on failure', () async {
      await userRepo.createUser(KineticUser(
        id: 'user_tx',
        createdAt: DateTime.utc(2026, 8, 18, 12, 0),
        updatedAt: DateTime.utc(2026, 8, 18, 12, 0),
      ));

      try {
        await dbManager.transaction((tx) async {
          final txUserRepo = UserRepository(tx);
          await txUserRepo.updateUser(KineticUser(
            id: 'user_tx',
            createdAt: DateTime.utc(2026, 8, 18, 12, 0),
            updatedAt: DateTime.utc(2026, 8, 18, 12, 0),
            age: 35,
          ));

          // Deliberately trigger conflict/constraint violation or throw exception to cause rollback
          throw Exception('Simulated transaction crash');
        });
      } catch (_) {}

      // Fetch user to verify age was NOT updated
      final user = await userRepo.getUser('user_tx');
      expect(user!.age, isNull);
    });

    test('7. Clean Test Reset purges all user data successfully', () async {
      await userRepo.createUser(KineticUser(
        id: 'user_to_purge',
        createdAt: DateTime.utc(2026, 8, 18, 12, 0),
        updatedAt: DateTime.utc(2026, 8, 18, 12, 0),
      ));

      await dbManager.resetToCleanState();

      // Check version is still latest, but tables are empty
      final currentVer = await dbManager.getCurrentVersion();
      expect(currentVer, equals(2));

      final user = await userRepo.getUser('user_to_purge');
      expect(user, isNull);
    });
  });
}
