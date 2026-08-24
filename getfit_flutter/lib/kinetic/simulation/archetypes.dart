import '../domain/models.dart';

/// Five distinct synthetic athlete archetypes as specified in SPEC.md Section 26
enum UserArchetype {
  userA_HighRecoveryAthlete,
  userB_HighFatiguePoorSleep,
  userC_WeightLossGoal,
  userD_StrengthFocusedAthlete,
  userE_SparseNoisyData,
}

/// Rich profile metadata for each synthetic archetype
class ArchetypeProfile {
  final UserArchetype archetype;
  final String name;
  final String description;
  final KineticUser user;
  final UserGoal goal;
  final TrainingFocus trainingFocus;
  final double targetSleepHours;
  final double meanHRV;
  final double meanRHR;
  final double dailyStepsMean;
  final double weeklyWorkoutFrequency; // days per week
  final double initialWeightKg;
  final double targetWeightKg;
  final double meanSessionTonnage;

  const ArchetypeProfile({
    required this.archetype,
    required this.name,
    required this.description,
    required this.user,
    required this.goal,
    required this.trainingFocus,
    required this.targetSleepHours,
    required this.meanHRV,
    required this.meanRHR,
    required this.dailyStepsMean,
    required this.weeklyWorkoutFrequency,
    required this.initialWeightKg,
    required this.targetWeightKg,
    required this.meanSessionTonnage,
  });
}

/// Catalog of all 5 synthetic user profiles
class SyntheticArchetypes {
  static ArchetypeProfile getProfile(UserArchetype type) {
    switch (type) {
      // 1. User A: Strong recovery, consistent 8.5h sleep, high HRV, high training consistency
      case UserArchetype.userA_HighRecoveryAthlete:
        return ArchetypeProfile(
          archetype: type,
          name: 'Alex (High Recovery Athlete)',
          description: 'Optimized sleep (8.5h), elevated HRV (78ms), low RHR (50bpm), high volume tolerance and progressive overload.',
          user: KineticUser(
            id: 'sim_user_a',
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now(),
            sex: 'male',
            age: 26,
            heightCm: 182,
            weightKg: 84.0,
          ),
          goal: const UserGoal(
            id: 'goal_a',
            userId: 'sim_user_a',
            type: GoalType.hypertrophy,
            priority: 1,
          ),
          trainingFocus: TrainingFocus.hypertrophy,
          targetSleepHours: 8.5,
          meanHRV: 78.0,
          meanRHR: 50.0,
          dailyStepsMean: 11000,
          weeklyWorkoutFrequency: 5.0,
          initialWeightKg: 83.0,
          targetWeightKg: 86.0,
          meanSessionTonnage: 3800.0,
        );

      // 2. User B: Poor sleep (5.8h), chronic sleep debt, suppressed HRV, elevated RHR
      case UserArchetype.userB_HighFatiguePoorSleep:
        return ArchetypeProfile(
          archetype: type,
          name: 'Jordan (High Fatigue & Chronic Sleep Debt)',
          description: 'Sub-optimal sleep (5.8h), chronic sleep debt (2-4h), suppressed HRV (38ms), elevated RHR (70bpm), prone to overreaching.',
          user: KineticUser(
            id: 'sim_user_b',
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now(),
            sex: 'female',
            age: 32,
            heightCm: 168,
            weightKg: 66.0,
          ),
          goal: const UserGoal(
            id: 'goal_b',
            userId: 'sim_user_b',
            type: GoalType.generalFitness,
            priority: 1,
          ),
          trainingFocus: TrainingFocus.hypertrophy,
          targetSleepHours: 5.8,
          meanHRV: 38.0,
          meanRHR: 70.0,
          dailyStepsMean: 7500,
          weeklyWorkoutFrequency: 4.0,
          initialWeightKg: 66.0,
          targetWeightKg: 64.0,
          meanSessionTonnage: 2200.0,
        );

      // 3. User C: Weight Loss Goal, steady deficit, active steps, progressive weight decline
      case UserArchetype.userC_WeightLossGoal:
        return ArchetypeProfile(
          archetype: type,
          name: 'Marcus (Weight Loss & Conditioning)',
          description: 'Steady caloric deficit, progressive weight drop (92kg -> 82kg), high daily locomotion (13,500 steps).',
          user: KineticUser(
            id: 'sim_user_c',
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now(),
            sex: 'male',
            age: 35,
            heightCm: 178,
            weightKg: 92.0,
          ),
          goal: const UserGoal(
            id: 'goal_c',
            userId: 'sim_user_c',
            type: GoalType.fatLoss,
            targetValue: 82.0,
            targetMetric: 'weight_kg',
            priority: 1,
          ),
          trainingFocus: TrainingFocus.endurance,
          targetSleepHours: 7.8,
          meanHRV: 62.0,
          meanRHR: 58.0,
          dailyStepsMean: 13500,
          weeklyWorkoutFrequency: 4.5,
          initialWeightKg: 92.0,
          targetWeightKg: 82.0,
          meanSessionTonnage: 2600.0,
        );

      // 4. User D: Strength-Focused Athlete, heavy compound training, low rep ranges
      case UserArchetype.userD_StrengthFocusedAthlete:
        return ArchetypeProfile(
          archetype: type,
          name: 'Elena (Competitive Strength Athlete)',
          description: 'Heavy compound powerlifting (squat, bench, deadlift), low rep ranges (3-5 reps), high neuromuscular fatigue.',
          user: KineticUser(
            id: 'sim_user_d',
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now(),
            sex: 'female',
            age: 29,
            heightCm: 170,
            weightKg: 72.0,
          ),
          goal: const UserGoal(
            id: 'goal_d',
            userId: 'sim_user_d',
            type: GoalType.strength,
            priority: 1,
          ),
          trainingFocus: TrainingFocus.strength,
          targetSleepHours: 8.2,
          meanHRV: 72.0,
          meanRHR: 54.0,
          dailyStepsMean: 8500,
          weeklyWorkoutFrequency: 4.0,
          initialWeightKg: 72.0,
          targetWeightKg: 72.5,
          meanSessionTonnage: 4500.0,
        );

      // 5. User E: Sparse, Noisy, Incomplete Data
      case UserArchetype.userE_SparseNoisyData:
        return ArchetypeProfile(
          archetype: type,
          name: 'Sam (Sparse / Noisy Logging)',
          description: 'Intermittent logging (~35% missing days), sensor artifacts, occasional duplicates, testing data robustness.',
          user: KineticUser(
            id: 'sim_user_e',
            createdAt: DateTime.now().subtract(const Duration(days: 365)),
            updatedAt: DateTime.now(),
            sex: 'unspecified',
            age: 30,
            heightCm: 175,
            weightKg: 75.0,
          ),
          goal: const UserGoal(
            id: 'goal_e',
            userId: 'sim_user_e',
            type: GoalType.generalFitness,
            priority: 1,
          ),
          trainingFocus: TrainingFocus.activeRecovery,
          targetSleepHours: 7.0,
          meanHRV: 55.0,
          meanRHR: 62.0,
          dailyStepsMean: 8000,
          weeklyWorkoutFrequency: 2.5,
          initialWeightKg: 75.0,
          targetWeightKg: 75.0,
          meanSessionTonnage: 1800.0,
        );
    }
  }
}
