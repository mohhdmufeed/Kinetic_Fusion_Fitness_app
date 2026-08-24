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
import '../../../shared/widgets/motion_widgets.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  UserProfileData? _profile;
  String? _username;
  bool _loading = true;
  bool _isSuperAdmin = true;

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
        _username = u ?? 'Coach Admin';
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
          content: Text('⏰ Daily reminder set for ${_reminderTime.format(context)}'),
          backgroundColor: AppColors.primary,
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
            color: Color(0xFF161B26),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Personal Info', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(color: Color(0xFF222836)),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      PersonalInfoForm(
                        initialData: currentData,
                        formKey: formKey,
                        onChanged: (data) async {
                          currentData = data;
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
                          _loadProfile();
                        },
                      ),
                      const SizedBox(height: 20),
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
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out of Kinetic Precision?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authServiceProvider).logout();
              ref.invalidate(isLoggedInProvider);
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
    final weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        title: const Text('Account & Roles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: const Color(0xFF161B26),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Gym Owner / Super Admin Command Center Card
                FadeSlideTransition(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A2333), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'GYM OWNER ID',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'SUPER ADMIN',
                                style: TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kinetic Performance Center',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'admin@kinetic.precision • 18 Active Athletes on Floor',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/admin'),
                            icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
                            label: const Text('Open Gym Command Center →', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF38BDF8),
                              foregroundColor: const Color(0xFF0B0E14),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // User Profile Card
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          child: Text(
                            (_username?.isNotEmpty == true ? _username![0].toUpperCase() : 'A'),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _username ?? 'Athlete',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Kinetic Precision On-Device Sync',
                                style: TextStyle(fontSize: 12, color: Colors.white38),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ATHLETE CLIENT',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Personal Health Profile', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                              onPressed: _openEditPersonalInfo,
                              tooltip: 'Edit Personal Info',
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFF222836), height: 16),
                        _infoRow('Date of Birth', _profile?.birthDate != null ? DateFormat('MMM d, yyyy').format(_profile!.birthDate!) : 'Not set'),
                        _infoRow('Sex', _profile?.sex.toUpperCase() ?? 'UNSPECIFIED'),
                        _infoRow('Height', _profile?.heightCm != null ? '${_profile!.heightCm} cm' : 'Not set'),
                        _infoRow('Weight', _profile?.weightKg != null ? '${_profile!.weightKg} ${_profile?.weightUnit ?? 'kg'}' : 'Not set'),
                        _infoRow('Daily Calorie Target', '~${_profile?.dailyMoveGoalCalories ?? 2370} kcal/day'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Daily Reminder & Alarm Section
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.alarm_rounded, color: Color(0xFFFB923C), size: 20),
                                SizedBox(width: 8),
                                Text('Daily Training Alarm', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Switch(
                              value: _reminderEnabled,
                              activeColor: AppColors.primary,
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
                                color: const Color(0xFF0B0E14),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF222836)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Reminder Time', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                                  Row(
                                    children: [
                                      Text(
                                        _reminderTime.format(context),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Repeat on Days:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white38)),
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
                                    color: isSel ? AppColors.primary : const Color(0xFF0B0E14),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSel ? AppColors.primary : const Color(0xFF222836)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      weekdayNames[i][0],
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSel ? const Color(0xFF0B0E14) : Colors.white54,
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
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 250),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    child: ListTile(
                      onTap: () => context.push('/feedback'),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF38BDF8), size: 20),
                      ),
                      title: const Text('Send Feedback & Diagnostics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Report bugs or suggest features', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Log Out Button
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmLogout,
                      icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                      label: const Text('Log Out of Kinetic Precision', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.white54)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
