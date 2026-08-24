import '../domain/models.dart';

/// Base interface for all health & fitness data providers
abstract class HealthDataProvider {
  String get providerId;
  String get displayName;
  int get defaultPriority; // Higher = higher precedence in conflicts

  Future<List<Measurement>> fetchMeasurements({
    required String userId,
    DateTime? from,
    DateTime? to,
  });
}

/// Provider interface specifically for sleep metrics
abstract class SleepProvider extends HealthDataProvider {
  Future<List<Measurement>> fetchSleepRecords({
    required String userId,
    DateTime? from,
    DateTime? to,
  });
}

/// Provider interface specifically for heart rate & HRV metrics
abstract class HeartRateProvider extends HealthDataProvider {
  Future<List<Measurement>> fetchHeartRateSamples({
    required String userId,
    DateTime? from,
    DateTime? to,
  });

  Future<List<Measurement>> fetchHRVSamples({
    required String userId,
    DateTime? from,
    DateTime? to,
  });
}

/// Provider interface specifically for workouts and sets
abstract class WorkoutProvider extends HealthDataProvider {
  Future<List<WorkoutSession>> fetchCompletedWorkouts({
    required String userId,
    DateTime? from,
    DateTime? to,
  });
}

/// Provider interface specifically for nutrition & hydration
abstract class NutritionProvider extends HealthDataProvider {
  Future<List<Measurement>> fetchNutritionLogs({
    required String userId,
    DateTime? from,
    DateTime? to,
  });
}
