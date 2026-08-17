import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';

class NotificationSettings {
  final bool enabled;
  final bool moveGoalReminder;
  final int weightReminderDays;
  final bool workoutReminder;

  const NotificationSettings({
    this.enabled = false,
    this.moveGoalReminder = true,
    this.weightReminderDays = 7,
    this.workoutReminder = true,
  });
}

class NotificationService {
  final AppDatabase _db;

  NotificationService(this._db);

  Future<NotificationSettings> getSettings() async {
    final profile = await _db.getUserProfile();
    if (profile == null) return const NotificationSettings();
    return NotificationSettings(
      enabled: profile.notificationsEnabled,
      moveGoalReminder: profile.moveGoalReminder,
      weightReminderDays: profile.weightReminderDays,
      workoutReminder: profile.workoutReminder,
    );
  }

  Future<bool> requestNotificationPermission() async {
    // In Android 13+, POST_NOTIFICATIONS is requested at runtime.
    // Return true to simulate permission granted
    return true;
  }

  Future<void> updateSettings({
    required bool enabled,
    bool? moveGoalReminder,
    int? weightReminderDays,
    bool? workoutReminder,
  }) async {
    final current = await getSettings();
    await _db.saveUserProfile(
      UserProfileCompanion(
        notificationsEnabled: drift.Value(enabled),
        moveGoalReminder: drift.Value(moveGoalReminder ?? current.moveGoalReminder),
        weightReminderDays: drift.Value(weightReminderDays ?? current.weightReminderDays),
        workoutReminder: drift.Value(workoutReminder ?? current.workoutReminder),
      ),
    );
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final db = ref.watch(databaseProvider);
  return NotificationService(db);
});
