import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/database/app_database.dart';
import '../../core/utils/move_goal_calculator.dart';
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

  void _skip() {
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Step 1 of 2: Personal Info' : 'Step 2 of 2: Daily Move Goal'),
        backgroundColor: navyColor,
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                              color: navyColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _currentStep == 0 ? Icons.person_pin : Icons.local_fire_department_rounded,
                              color: navyColor,
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
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentStep == 0
                                      ? 'Help us customize your body metrics'
                                      : 'Set your daily active calorie burn target',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),

                      // Step 1: Personal Info Form
                      if (_currentStep == 0) ...[
                        PersonalInfoForm(
                          initialData: _personalData,
                          formKey: _personalFormKey,
                          onChanged: (updated) {
                            _personalData = updated;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
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
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18, color: Colors.white),
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
                          onChanged: (updated) {
                            _activityData = updated;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _saveAndFinish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: navyColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'Finish Setup & Open GetFit',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip for now',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
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
    );
  }
}
