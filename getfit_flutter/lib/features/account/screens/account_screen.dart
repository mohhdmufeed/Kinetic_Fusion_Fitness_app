import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/auth/auth_service.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/personal_info_form.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  UserProfileData? _profile;
  String? _username;
  bool _loading = true;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 18, minute: 30);
  List<int> _reminderDays = [1, 2, 3, 4, 5]; // Mon-Fri
  bool _reminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final db = ref.read(databaseProvider);
    final p = await db.getUserProfile();
    final u = await ref.read(authServiceProvider).getUsername();

    if (p != null) {
      // Parse time
      try {
        final parts = p.dailyReminderTime.split(':');
        if (parts.length == 2) {
          _reminderTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }
        final days = jsonDecode(p.dailyReminderDays) as List<dynamic>;
        _reminderDays = days.map((e) => int.parse(e.toString())).toList();
      } catch (_) {}
      _reminderEnabled = p.dailyReminderEnabled;
    }

    if (mounted) {
      setState(() {
        _profile = p;
        _username = u ?? 'Athlete';
        _loading = false;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
      _saveReminderSettings();
    }
  }

  Future<void> _saveReminderSettings() async {
    final timeStr = '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';
    final daysStr = jsonEncode(_reminderDays);

    final db = ref.read(databaseProvider);
    await db.saveUserProfile(
      UserProfileCompanion(
        dailyReminderTime: drift.Value(timeStr),
        dailyReminderDays: drift.Value(daysStr),
        dailyReminderEnabled: drift.Value(_reminderEnabled),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⏰ Daily alarm set for ${_reminderTime.format(context)}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openEditPersonalInfo() {
    final formKey = GlobalKey<FormState>();
    PersonalInfoData currentData = PersonalInfoData(
      birthDate: _profile?.birthDate,
      sex: _profile?.sex ?? 'unspecified',
      heightCm: _profile?.heightCm,
      weightKg: _profile?.weightKg,
      weightUnit: _profile?.weightUnit ?? 'kg',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Personal Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      PersonalInfoForm(
                        initialData: currentData,
                        formKey: formKey,
                        onChanged: (data) => currentData = data,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final db = ref.read(databaseProvider);
                              await db.saveUserProfile(
                                UserProfileCompanion(
                                  birthDate: drift.Value(currentData.birthDate),
                                  sex: drift.Value(currentData.sex),
                                  heightCm: drift.Value(currentData.heightCm),
                                  weightKg: drift.Value(currentData.weightKg),
                                  weightUnit: drift.Value(currentData.weightUnit),
                                ),
                              );
                              Navigator.pop(ctx);
                              _loadProfile();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF26496C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of your GetFit account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).logout();
              if (mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Profile'),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // User Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: navyColor.withValues(alpha: 0.1),
                          child: Text(
                            (_username?.isNotEmpty == true ? _username![0].toUpperCase() : 'A'),
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: navyColor),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _username ?? 'Athlete',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'GetFit Offline & Local Sync',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PREMIUM ATHLETE',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Personal Info Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Personal Health Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: navyColor, size: 20),
                              onPressed: _openEditPersonalInfo,
                              tooltip: 'Edit Personal Info',
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _infoRow('Date of Birth', _profile?.birthDate != null ? DateFormat('MMM d, yyyy').format(_profile!.birthDate!) : 'Not set'),
                        _infoRow('Sex', _profile?.sex.toUpperCase() ?? 'UNSPECIFIED'),
                        _infoRow('Height', _profile?.heightCm != null ? '${_profile!.heightCm} cm' : 'Not set'),
                        _infoRow('Weight', _profile?.weightKg != null ? '${_profile!.weightKg} ${_profile?.weightUnit ?? 'kg'}' : 'Not set'),
                        _infoRow('Daily Move Goal', '~${_profile?.dailyMoveGoalCalories ?? 400} kcal/day'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily Reminder & Alarm Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.alarm_rounded, color: Color(0xFFE11D48), size: 22),
                                SizedBox(width: 8),
                                Text('Daily Workout Alarm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Switch(
                              value: _reminderEnabled,
                              activeColor: navyColor,
                              onChanged: (val) {
                                setState(() => _reminderEnabled = val);
                                _saveReminderSettings();
                              },
                            ),
                          ],
                        ),
                        if (_reminderEnabled) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickReminderTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Reminder Time', style: TextStyle(fontWeight: FontWeight.w600)),
                                  Row(
                                    children: [
                                      Text(
                                        _reminderTime.format(context),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyColor),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Repeat on Days:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(7, (i) {
                              final dayNum = i + 1;
                              final isSel = _reminderDays.contains(dayNum);
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSel) {
                                      _reminderDays.remove(dayNum);
                                    } else {
                                      _reminderDays.add(dayNum);
                                    }
                                  });
                                  _saveReminderSettings();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSel ? navyColor : Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      weekdayNames[i][0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Support & Feedback Tile
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    onTap: () => context.push('/feedback'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF0284C7)),
                    ),
                    title: const Text('Send Feedback & Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: const Text('Report issues or request features', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),

                // Log Out Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                    label: const Text('Log Out of GetFit', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
