import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class StepData {
  final int stepCount;
  final double distanceKm;
  final double caloriesBurned;
  final double goalProgressPercent;
  final int targetSteps;

  const StepData({
    this.stepCount = 0,
    this.distanceKm = 0.0,
    this.caloriesBurned = 0.0,
    this.goalProgressPercent = 0.0,
    this.targetSteps = 8000,
  });
}

class StepTrackerService {
  final AppDatabase _db;

  StepTrackerService(this._db);

  /// Loads today's step data and computes progress towards move goal
  Future<StepData> getTodaySteps() async {
    final entry = await _db.getTodayStepEntry();
    final profile = await _db.getUserProfile();

    final moveGoalCalories = profile?.dailyMoveGoalCalories ?? 400;
    // Rule of thumb: ~20 steps = 1 kcal active burn -> 8000 steps ~= 400 kcal
    final targetSteps = (moveGoalCalories * 20).clamp(3000, 25000);

    final steps = entry?.stepCount ?? 0;
    final distanceKm = (entry?.distanceMeters ?? (steps * 0.762)) / 1000.0;
    final calories = entry?.caloriesBurned ?? (steps * 0.04);
    final progress = targetSteps > 0 ? (steps / targetSteps).clamp(0.0, 1.0) : 0.0;

    return StepData(
      stepCount: steps,
      distanceKm: distanceKm,
      caloriesBurned: calories,
      goalProgressPercent: progress,
      targetSteps: targetSteps,
    );
  }

  /// Adds or updates today's steps in SQLite
  Future<void> addSteps(int stepsToAdd) async {
    final entry = await _db.getTodayStepEntry();
    final currentSteps = entry?.stepCount ?? 0;
    final newTotalSteps = currentSteps + stepsToAdd;
    final newDistanceMeters = newTotalSteps * 0.762; // ~0.762m per stride
    final newCalories = newTotalSteps * 0.04; // ~0.04 kcal per step

    await _db.saveStepEntry(
      DailyStepEntriesCompanion(
        date: drift.Value(DateTime.now()),
        stepCount: drift.Value(newTotalSteps),
        distanceMeters: drift.Value(newDistanceMeters),
        caloriesBurned: drift.Value(newCalories),
        pendingSync: const drift.Value(true),
      ),
    );
  }

  /// Sets absolute step count for today (e.g. from sensor reading)
  Future<void> setSteps(int totalSteps) async {
    final newDistanceMeters = totalSteps * 0.762;
    final newCalories = totalSteps * 0.04;

    await _db.saveStepEntry(
      DailyStepEntriesCompanion(
        date: drift.Value(DateTime.now()),
        stepCount: drift.Value(totalSteps),
        distanceMeters: drift.Value(newDistanceMeters),
        caloriesBurned: drift.Value(newCalories),
        pendingSync: const drift.Value(true),
      ),
    );
  }
}

final stepTrackerServiceProvider = Provider<StepTrackerService>((ref) {
  final db = ref.watch(databaseProvider);
  return StepTrackerService(db);
});
