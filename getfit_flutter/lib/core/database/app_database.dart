import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────
//  TABLE DEFINITIONS
// ─────────────────────────────────────────────

/// Exercises (synced from server, read-only on device)
class Exercises extends Table {
  IntColumn get id => integer()();
  TextColumn get uuid => text().withLength(max: 64)();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get muscles => text().withDefault(const Constant('[]'))();   // JSON list
  TextColumn get equipment => text().withDefault(const Constant('[]'))();  // JSON list
  TextColumn get imageUrl => text().withDefault(const Constant(''))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// User's workout routines
class Routines extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Workout days within a routine
class WorkoutDays extends Table {
  IntColumn get id => integer()();
  IntColumn get routineId => integer().references(Routines, #id)();
  TextColumn get name => text().withDefault(const Constant(''))();
  TextColumn get dayOfWeek => text().withDefault(const Constant('[]'))(); // JSON list of ints
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Exercises within a workout day
class WorkoutSlots extends Table {
  IntColumn get id => integer()();
  IntColumn get dayId => integer().references(WorkoutDays, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get order => integer().withDefault(const Constant(1))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual workout log entries (sets × reps × weight)
class WorkoutLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get routineId => integer().nullable()();
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  IntColumn get sets => integer().withDefault(const Constant(1))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()(); // null until synced
}

// ─── NUTRITION ─────────────────────────────────

class Ingredients extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  RealColumn get energy => real().withDefault(const Constant(0.0))();    // kcal per 100g
  RealColumn get protein => real().withDefault(const Constant(0.0))();
  RealColumn get carbs => real().withDefault(const Constant(0.0))();
  RealColumn get fat => real().withDefault(const Constant(0.0))();
  RealColumn get fiber => real().nullable()();
  RealColumn get sugar => real().nullable()();
  TextColumn get imageUrl => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class NutritionPlans extends Table {
  IntColumn get id => integer()();
  TextColumn get description => text().withDefault(const Constant('My Plan'))();
  RealColumn get goalEnergy => real().nullable()();
  RealColumn get goalProtein => real().nullable()();
  RealColumn get goalCarbs => real().nullable()();
  RealColumn get goalFat => real().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Meals extends Table {
  IntColumn get id => integer()();
  IntColumn get planId => integer().references(NutritionPlans, #id)();
  TextColumn get name => text().withDefault(const Constant('Meal'))();
  TextColumn get time => text().nullable()();  // "08:30"
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId => integer().references(Meals, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get amount => real().withDefault(const Constant(100.0))(); // grams
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()();
}

/// Daily nutrition diary (what was actually eaten)
class NutritionDiary extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId => integer().nullable()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get amount => real().withDefault(const Constant(100.0))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()();
}

// ─── MEASUREMENTS ─────────────────────────────

class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get weight => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()();
}

class MeasurementCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();  // "Waist", "Chest", "Arms", etc.
  TextColumn get unit => text().withDefault(const Constant('cm'))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Measurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(MeasurementCategories, #id)();
  RealColumn get value => real()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
  IntColumn get serverId => integer().nullable()();
}

// ─── AUTH & PROFILE ───────────────────────────

class UserProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().withDefault(const Constant('User'))();
  TextColumn get email => text().withDefault(const Constant(''))();
  DateTimeColumn get birthDate => dateTime().nullable()();
  TextColumn get sex => text().withDefault(const Constant('unspecified'))(); // 'male', 'female', 'unspecified'
  IntColumn get heightCm => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  TextColumn get weightUnit => text().withDefault(const Constant('kg'))(); // 'kg' or 'lbs'
  
  // Activity & Daily Move Goal fields
  TextColumn get activityLevel => text().withDefault(const Constant('moderate'))(); // 'light', 'moderate', 'high', 'custom'
  TextColumn get profession => text().withDefault(const Constant(''))();
  RealColumn get workHours => real().withDefault(const Constant(8.0))();
  TextColumn get workIntensity => text().withDefault(const Constant('low'))(); // 'low', 'medium', 'high'
  RealColumn get sportHours => real().withDefault(const Constant(3.0))(); // per week
  TextColumn get sportIntensity => text().withDefault(const Constant('medium'))();
  RealColumn get freetimeHours => real().withDefault(const Constant(5.0))();
  TextColumn get freetimeIntensity => text().withDefault(const Constant('low'))();
  RealColumn get sleepHours => real().withDefault(const Constant(8.0))();
  IntColumn get dailyMoveGoalCalories => integer().withDefault(const Constant(400))();

  // Notification & Reminder Preferences
  BoolColumn get notificationsEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get moveGoalReminder => boolean().withDefault(const Constant(true))();
  IntColumn get weightReminderDays => integer().withDefault(const Constant(7))();
  BoolColumn get workoutReminder => boolean().withDefault(const Constant(true))();

  // Daily Reminder & Alarm (Custom Time + Days)
  TextColumn get dailyReminderTime => text().withDefault(const Constant('18:30'))();
  TextColumn get dailyReminderDays => text().withDefault(const Constant('[1,2,3,4,5]'))();
  BoolColumn get dailyReminderEnabled => boolean().withDefault(const Constant(true))();

  // Customizable Summary Layout
  TextColumn get summaryLayout => text().withDefault(const Constant('["challenges","ring","steps","distance","sessions","awards","quote"]'))();

  DateTimeColumn get lastSync => dateTime().nullable()();
}

// ─── STEP COUNTING (SENSOR) ────────────────────

class DailyStepEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get stepCount => integer().withDefault(const Constant(0))();
  RealColumn get distanceMeters => real().withDefault(const Constant(0.0))();
  RealColumn get caloriesBurned => real().withDefault(const Constant(0.0))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
}

// ─── RUN TRACKING & GPS ROUTES ─────────────────

class RunSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  RealColumn get distanceMeters => real().withDefault(const Constant(0.0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  RealColumn get caloriesBurned => real().withDefault(const Constant(0.0))();
  RealColumn get avgPaceMinPerKm => real().withDefault(const Constant(0.0))();
  TextColumn get routePointsJson => text().withDefault(const Constant('[]'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
}

// ─── UNIFIED ACTIVITY ENTRIES ──────────────────

class ActivityEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityType => text()(); // 'running', 'cycling', 'swimming', 'hiking', 'walking', 'mindfulness'
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get pausedDurationSeconds => integer().withDefault(const Constant(0))();
  RealColumn get distanceMeters => real().nullable()();
  TextColumn get routePointsJson => text().withDefault(const Constant('[]'))();
  IntColumn get laps => integer().nullable()(); // swimming
  IntColumn get poolLengthMeters => integer().nullable()(); // swimming
  RealColumn get caloriesBurned => real().withDefault(const Constant(0.0))();
  TextColumn get moodNotes => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
}

// ─── OUTDOOR GOALS & WISHLIST ─────────────────

class WishlistItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get activityType => text()(); // 'running', 'cycling', 'hiking', 'walking'
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get targetDate => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get completedActivityId => integer().nullable()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();
}

// ─── DAILY CHALLENGES ──────────────────────────

class DailyChallenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  RealColumn get targetValue => real().withDefault(const Constant(1.0))();
  TextColumn get targetUnit => text().withDefault(const Constant('reps'))();
  TextColumn get activityType => text().withDefault(const Constant('general'))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get dateCompleted => dateTime().nullable()();
}

// ─── USER FEEDBACK ENTRIES ─────────────────────

class FeedbackEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()(); // 'bug', 'suggestion', 'other'
  TextColumn get message => text()();
  IntColumn get rating => integer().withDefault(const Constant(5))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();
}

// ─────────────────────────────────────────────
//  DATABASE
// ─────────────────────────────────────────────

@DriftDatabase(tables: [
  Exercises,
  Routines,
  WorkoutDays,
  WorkoutSlots,
  WorkoutLogs,
  Ingredients,
  NutritionPlans,
  Meals,
  MealItems,
  NutritionDiary,
  WeightEntries,
  MeasurementCategories,
  Measurements,
  UserProfile,
  DailyStepEntries,
  RunSessions,
  ActivityEntries,
  WishlistItems,
  DailyChallenges,
  FeedbackEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'getfit_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }

  // ── User Profile ───────────────────────────

  Future<UserProfileData?> getUserProfile() =>
      (select(userProfile)..limit(1)).getSingleOrNull();

  Future<int> saveUserProfile(UserProfileCompanion profile) async {
    final existing = await getUserProfile();
    if (existing != null) {
      await (update(userProfile)..where((t) => t.id.equals(existing.id))).write(profile);
      return existing.id;
    } else {
      return into(userProfile).insert(profile);
    }
  }

  // ── Workout Logs ───────────────────────────

  Future<List<WorkoutLog>> getWorkoutLogs({DateTime? from, DateTime? to}) {
    final q = select(workoutLogs);
    if (from != null) q.where((t) => t.date.isBiggerOrEqualValue(from));
    if (to != null) q.where((t) => t.date.isSmallerOrEqualValue(to));
    q.orderBy([(t) => OrderingTerm.desc(t.date)]);
    return q.get();
  }

  Future<int> insertWorkoutLog(WorkoutLogsCompanion log) =>
      into(workoutLogs).insert(log);

  Future<List<WorkoutLog>> getPendingWorkoutLogs() =>
      (select(workoutLogs)..where((t) => t.pendingSync.equals(true))).get();

  // ── Nutrition Diary ────────────────────────

  Future<List<NutritionDiaryData>> getDiaryForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(nutritionDiary)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerOrEqualValue(end)))
        .get();
  }

  Future<int> insertDiaryEntry(NutritionDiaryCompanion entry) =>
      into(nutritionDiary).insert(entry);

  Future<List<NutritionDiaryData>> getPendingDiaryEntries() =>
      (select(nutritionDiary)..where((t) => t.pendingSync.equals(true))).get();

  // ── Weight Entries ─────────────────────────

  Future<List<WeightEntry>> getWeightEntries({int limit = 90}) =>
      (select(weightEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .get();

  Future<int> insertWeightEntry(WeightEntriesCompanion entry) =>
      into(weightEntries).insert(entry);

  Future<List<WeightEntry>> getPendingWeightEntries() =>
      (select(weightEntries)..where((t) => t.pendingSync.equals(true))).get();

  // ── Measurements ───────────────────────────

  Future<List<Measurement>> getMeasurementsForCategory(int categoryId) =>
      (select(measurements)
            ..where((t) => t.categoryId.equals(categoryId))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<int> insertMeasurement(MeasurementsCompanion m) =>
      into(measurements).insert(m);

  // ── Exercises ──────────────────────────────

  Future<List<Exercise>> searchExercises(String query) =>
      (select(exercises)
            ..where((t) =>
                t.name.lower().like('%${query.toLowerCase()}%')))
          .get();

  Future<List<Exercise>> getAllExercises() =>
      (select(exercises)..orderBy([(t) => OrderingTerm.asc(t.name)])).get();

  // ── Ingredients ────────────────────────────

  Future<List<Ingredient>> searchIngredients(String query) =>
      (select(ingredients)
            ..where((t) =>
                t.name.lower().like('%${query.toLowerCase()}%'))
            ..limit(50))
          .get();

  // ── Routines ───────────────────────────────

  Future<List<Routine>> getActiveRoutines() =>
      (select(routines)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  // ── Step Counting (Sensor) ────────────────
  
  Future<DailyStepEntry?> getTodayStepEntry() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return (select(dailyStepEntries)
          ..where((t) => t.date.isBiggerOrEqualValue(startOfDay) & t.date.isSmallerOrEqualValue(endOfDay))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> saveStepEntry(DailyStepEntriesCompanion entry) async {
    final existing = await getTodayStepEntry();
    if (existing != null) {
      await (update(dailyStepEntries)..where((t) => t.id.equals(existing.id))).write(entry);
      return existing.id;
    } else {
      return into(dailyStepEntries).insert(entry);
    }
  }

  Future<List<DailyStepEntry>> getRecentStepEntries({int limit = 7}) =>
      (select(dailyStepEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .get();

  // ── Run Tracking & GPS ─────────────────────

  Future<int> insertRunSession(RunSessionsCompanion entry) =>
      into(runSessions).insert(entry);

  Future<List<RunSession>> getRunSessions({int limit = 30}) =>
      (select(runSessions)
            ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
            ..limit(limit))
          .get();

  Future<RunSession?> getRunSessionById(int id) =>
      (select(runSessions)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ── Unified Activity Entries (All Sports) ──

  Future<int> insertActivityEntry(ActivityEntriesCompanion entry) =>
      into(activityEntries).insert(entry);

  Future<List<ActivityEntry>> getActivityEntriesByType(String type, {int limit = 50}) =>
      (select(activityEntries)
            ..where((t) => t.activityType.equals(type.toLowerCase()))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  Future<List<ActivityEntry>> getActivityEntriesByDateRange(
    DateTime start,
    DateTime end, {
    String? activityType,
  }) {
    final query = select(activityEntries)
      ..where((t) =>
          t.date.isBiggerOrEqualValue(start) & t.date.isSmallerOrEqualValue(end));
    if (activityType != null && activityType.isNotEmpty) {
      query.where((t) => t.activityType.equals(activityType.toLowerCase()));
    }
    return (query..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
  }

  Future<List<ActivityEntry>> getAllActivityEntries({int limit = 100}) =>
      (select(activityEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .get();

  Future<void> toggleActivityFavorite(int id, bool isFav) =>
      (update(activityEntries)..where((t) => t.id.equals(id)))
          .write(ActivityEntriesCompanion(isFavorite: Value(isFav)));

  // ── Wishlist & Outdoor Goals ───────────────

  Future<int> insertWishlistItem(WishlistItemsCompanion item) =>
      into(wishlistItems).insert(item);

  Future<List<WishlistItem>> getWishlistItems({String? activityType}) {
    final query = select(wishlistItems);
    if (activityType != null && activityType.isNotEmpty) {
      query.where((t) => t.activityType.equals(activityType.toLowerCase()));
    }
    return (query..orderBy([(t) => OrderingTerm.asc(t.isCompleted), (t) => OrderingTerm.desc(t.id)])).get();
  }

  Future<void> completeWishlistItem(int id, {int? completedActivityId}) =>
      (update(wishlistItems)..where((t) => t.id.equals(id))).write(
        WishlistItemsCompanion(
          isCompleted: const Value(true),
          completedActivityId: Value(completedActivityId),
        ),
      );

  Future<void> deleteWishlistItem(int id) =>
      (delete(wishlistItems)..where((t) => t.id.equals(id))).go();

  // ── Daily Challenges ───────────────────────

  Future<List<DailyChallenge>> getDailyChallenges() =>
      select(dailyChallenges).get();

  Future<void> initDefaultChallengesIfEmpty() async {
    final existing = await select(dailyChallenges).get();
    if (existing.isEmpty) {
      final pool = [
        const DailyChallengesCompanion(
          title: Value('Sprint Intervals (30s x 10)'),
          description: Value('High intensity sprint bursts with 45s recovery walk between.'),
          targetValue: Value(10.0),
          targetUnit: Value('intervals'),
          activityType: Value('running'),
        ),
        const DailyChallengesCompanion(
          title: Value('100 Push-Up Milestone'),
          description: Value('Accumulate 100 push-ups in total throughout the day.'),
          targetValue: Value(100.0),
          targetUnit: Value('reps'),
          activityType: Value('strength'),
        ),
        const DailyChallengesCompanion(
          title: Value('Daily Step Target (8,000 steps)'),
          description: Value('Keep moving throughout the day and reach 8,000 steps.'),
          targetValue: Value(8000.0),
          targetUnit: Value('steps'),
          activityType: Value('walking'),
        ),
        const DailyChallengesCompanion(
          title: Value('10-Minute Breathwork Meditation'),
          description: Value('Dedicated box-breathing mindfulness session to reset.'),
          targetValue: Value(10.0),
          targetUnit: Value('mins'),
          activityType: Value('mindfulness'),
        ),
      ];
      for (final c in pool) {
        await into(dailyChallenges).insert(c);
      }
    }
  }

  Future<void> completeDailyChallenge(int id, bool isCompleted) =>
      (update(dailyChallenges)..where((t) => t.id.equals(id))).write(
        DailyChallengesCompanion(
          isCompleted: Value(isCompleted),
          dateCompleted: Value(isCompleted ? DateTime.now() : null),
        ),
      );

  // ── User Feedback ──────────────────────────

  Future<int> insertFeedback(FeedbackEntriesCompanion entry) =>
      into(feedbackEntries).insert(entry);

  Future<List<FeedbackEntry>> getFeedbackEntries() =>
      (select(feedbackEntries)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  // ── Custom Exercises ───────────────────────

  Future<int> insertCustomExercise(ExercisesCompanion exercise) =>
      into(exercises).insert(exercise);

  // ── Pending sync count ─────────────────────

  Future<int> getPendingSyncCount() async {
    final logs = await getPendingWorkoutLogs();
    final diary = await getPendingDiaryEntries();
    final weights = await getPendingWeightEntries();
    return logs.length + diary.length + weights.length;
  }
}

// Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main()');
});
