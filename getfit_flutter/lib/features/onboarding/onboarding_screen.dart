import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/auth/auth_service.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/move_goal_calculator.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/personal_info_form.dart';
import '../../shared/widgets/activity_level_picker.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _personalFormKey = GlobalKey<FormState>();
  int _currentStep = 0; // 0 = Personal Info, 1 = Move Goal & Activity Level
  PersonalInfoData _personalData = PersonalInfoData();
  ActivityData _activityData = ActivityData();
  bool _saving = false;

  Future<void> _saveAndFinish() async {
    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      await db.saveUserProfile(
        UserProfileCompanion(
          birthDate: drift.Value(_personalData.birthDate),
          sex: drift.Value(_personalData.sex),
          heightCm: drift.Value(_personalData.heightCm),
          weightKg: drift.Value(_personalData.weightKg),
          weightUnit: drift.Value(_personalData.weightUnit),
          activityLevel: drift.Value(_activityData.activityLevel),
          profession: drift.Value(_activityData.profession),
          workHours: drift.Value(_activityData.workHours),
          workIntensity: drift.Value(_activityData.workIntensity),
          sportHours: drift.Value(_activityData.sportHours),
          sportIntensity: drift.Value(_activityData.sportIntensity),
          freetimeHours: drift.Value(_activityData.freetimeHours),
          freetimeIntensity: drift.Value(_activityData.freetimeIntensity),
          sleepHours: drift.Value(_activityData.sleepHours),
          dailyMoveGoalCalories: drift.Value(_activityData.calculatedMoveGoal),
        ),
      );

      // Log initial weight entry if provided
      if (_personalData.weightKg != null && _personalData.weightKg! > 0) {
        await db.insertWeightEntry(
          WeightEntriesCompanion.insert(
            weight: _personalData.weightKg!,
            date: drift.Value(DateTime.now()),
            notes: const drift.Value('Initial onboarding weight'),
            pendingSync: const drift.Value(true),
          ),
        );
      }

      final username = await ref.read(authServiceProvider).getUsername();
      if (username != null) {
        await ref.read(authServiceProvider).setOnboardingCompleted(username);
      }
    } catch (_) {}

    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _nextStep() {
    if (_personalFormKey.currentState!.validate()) {
      setState(() {
        _currentStep = 1;
      });
    }
  }

  Future<void> _skip() async {
    final username = await ref.read(authServiceProvider).getUsername();
    if (username != null) {
      await ref.read(authServiceProvider).setOnboardingCompleted(username);
    }
    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(
          _currentStep == 0 ? 'Step 1 of 2: Personal Info' : 'Step 2 of 2: Daily Move Goal',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 0),
              )
            : null,
        actions: [
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/textured_dumbbells.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0D0E0F).withOpacity(0.82),
                    const Color(0xFF0D0E0F).withOpacity(0.97),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                color: AppColors.cardDark,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.cardBorderDark),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                            ),
                            child: Icon(
                              _currentStep == 0 ? Icons.person_pin : Icons.local_fire_department_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentStep == 0
                                      ? 'Tell us about yourself'
                                      : 'How active are you?',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentStep == 0
                                      ? 'Help us customize your body metrics'
                                      : 'Set your daily active calorie burn target',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28, color: AppColors.cardBorderDark),

                      // Step 1: Personal Info Form
                      if (_currentStep == 0) ...[
                        PersonalInfoForm(
                          initialData: _personalData,
                          formKey: _personalFormKey,
                          onChanged: (updated) async {
                            _personalData = updated;
                            final db = ref.read(databaseProvider);
                            await db.saveUserProfile(
                              UserProfileCompanion(
                                birthDate: drift.Value(updated.birthDate),
                                sex: drift.Value(updated.sex),
                                heightCm: drift.Value(updated.heightCm),
                                weightKg: drift.Value(updated.weightKg),
                                weightUnit: drift.Value(updated.weightUnit),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next: Set Daily Move Goal',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18, color: Colors.black),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Step 2: Activity Level & Move Goal Picker
                        ActivityLevelPicker(
                          initialData: _activityData,
                          weightKg: _personalData.weightKg ?? 70.0,
                          heightCm: _personalData.heightCm ?? 175,
                          birthDate: _personalData.birthDate,
                          sex: _personalData.sex,
                          onChanged: (updated) async {
                            _activityData = updated;
                            final db = ref.read(databaseProvider);
                            await db.saveUserProfile(
                              UserProfileCompanion(
                                activityLevel: drift.Value(updated.activityLevel),
                                profession: drift.Value(updated.profession),
                                workHours: drift.Value(updated.workHours),
                                workIntensity: drift.Value(updated.workIntensity),
                                sportHours: drift.Value(updated.sportHours),
                                sportIntensity: drift.Value(updated.sportIntensity),
                                freetimeHours: drift.Value(updated.freetimeHours),
                                freetimeIntensity: drift.Value(updated.freetimeIntensity),
                                sleepHours: drift.Value(updated.sleepHours),
                                dailyMoveGoalCalories: drift.Value(updated.calculatedMoveGoal),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveAndFinish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Finish Setup & Open Kinetic Fusion',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
}
}
