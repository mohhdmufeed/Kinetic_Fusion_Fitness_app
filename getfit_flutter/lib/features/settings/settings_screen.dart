import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/auth/auth_service.dart';
import '../../../core/constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/move_goal_calculator.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/personal_info_form.dart';
import '../../../shared/widgets/activity_level_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  String? _username;
  String? _lastSync;
  int _pending = 0;
  bool _syncing = false;
  bool _savingProfile = false;
  bool _savingActivity = false;
  PersonalInfoData _profileData = PersonalInfoData();
  ActivityData _activityData = ActivityData();
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final u = await ref.read(authServiceProvider).getUsername();
    final ls = await const FlutterSecureStorage()
        .read(key: AppConstants.lastSyncKey);
    final p = await ref.read(databaseProvider).getPendingSyncCount();
    final profile = await ref.read(databaseProvider).getUserProfile();

    if (mounted) {
      setState(() {
        _username = u;
        _lastSync = ls;
        _pending = p;
        if (profile != null) {
          _profileData = PersonalInfoData(
            birthDate: profile.birthDate,
            sex: profile.sex,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            weightUnit: profile.weightUnit,
          );
          _activityData = ActivityData(
            activityLevel: profile.activityLevel,
            profession: profile.profession,
            workHours: profile.workHours,
            workIntensity: profile.workIntensity,
            sportHours: profile.sportHours,
            sportIntensity: profile.sportIntensity,
            freetimeHours: profile.freetimeHours,
            freetimeIntensity: profile.freetimeIntensity,
            sleepHours: profile.sleepHours,
            calculatedMoveGoal: profile.dailyMoveGoalCalories,
          );
        }
        _profileLoaded = true;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);

    try {
      final db = ref.read(databaseProvider);
      await db.saveUserProfile(
        UserProfileCompanion(
          username: drift.Value(_username ?? 'User'),
          birthDate: drift.Value(_profileData.birthDate),
          sex: drift.Value(_profileData.sex),
          heightCm: drift.Value(_profileData.heightCm),
          weightKg: drift.Value(_profileData.weightKg),
          weightUnit: drift.Value(_profileData.weightUnit),
        ),
      );

      if (_profileData.weightKg != null && _profileData.weightKg! > 0) {
        await db.insertWeightEntry(
          WeightEntriesCompanion.insert(
            weight: _profileData.weightKg!,
            date: drift.Value(DateTime.now()),
            notes: const drift.Value('Updated from Profile settings'),
            pendingSync: const drift.Value(true),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Personal information updated ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {}

    if (mounted) setState(() => _savingProfile = false);
  }

  Future<void> _saveActivity() async {
    setState(() => _savingActivity = true);

    try {
      final db = ref.read(databaseProvider);
      await db.saveUserProfile(
        UserProfileCompanion(
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily move goal updated to ~${_activityData.calculatedMoveGoal} kcal ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (_) {}

    if (mounted) setState(() => _savingActivity = false);
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await ref.read(syncServiceProvider).sync();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sync complete ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: check internet connection'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    if (mounted) setState(() => _syncing = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out?'),
        content: const Text(
            'Your local data will remain on this device. You can sign back in to sync.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authServiceProvider).logout();
      ref.invalidate(isLoggedInProvider);
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.accent]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (_username ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_username ?? 'Loading...',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const Text('GetFit account',
                          style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Personal Health Info Section
          _sectionTitle('Personal Health & Body Info'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _profileLoaded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PersonalInfoForm(
                          initialData: _profileData,
                          formKey: _profileFormKey,
                          onChanged: (updated) {
                            _profileData = updated;
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _savingProfile ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _savingProfile
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Daily Move Goal Section
          _sectionTitle('Daily Move Goal & Activity Level'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _profileLoaded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ActivityLevelPicker(
                          initialData: _activityData,
                          weightKg: _profileData.weightKg ?? 70.0,
                          heightCm: _profileData.heightCm ?? 175,
                          birthDate: _profileData.birthDate,
                          sex: _profileData.sex,
                          onChanged: (updated) {
                            _activityData = updated;
                          },
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _savingActivity ? null : _saveActivity,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _savingActivity
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Move Goal Target',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Sync section
          _sectionTitle('Sync'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined,
                      color: AppColors.accent),
                  title: const Text('Last Sync'),
                  trailing: Text(_lastSync ?? 'Never',
                      style: const TextStyle(color: Colors.grey)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined,
                      color: AppColors.warning),
                  title: const Text('Pending Items'),
                  trailing: Text('$_pending',
                      style: TextStyle(
                          color: _pending > 0
                              ? AppColors.warning
                              : AppColors.success,
                          fontWeight: FontWeight.w700)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: _syncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary),
                        )
                      : const Icon(Icons.sync_rounded,
                          color: AppColors.primary),
                  title: const Text('Sync Now'),
                  subtitle: const Text('Upload changes & download updates'),
                  onTap: _syncing ? null : _syncNow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Backend section
          _sectionTitle('Backend'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.dns_outlined, color: AppColors.primary),
              title: const Text('Server URL'),
              subtitle: Text(AppConstants.baseUrl,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 24),

          // Account section
          _sectionTitle('Account'),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.error),
              title: const Text('Log Out'),
              subtitle: const Text('Local data stays on device'),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text('GetFit v1.0.0',
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
          letterSpacing: 0.8));
}
