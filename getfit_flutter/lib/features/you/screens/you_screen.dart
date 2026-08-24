import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/motion_widgets.dart';
import '../../../kinetic/domain/models.dart' as kinetic;
import '../../../kinetic/persistence/kinetic_store.dart';

class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({super.key});

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> {
  bool _useKilograms = true;
  UserProfileData? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final db = ref.read(databaseProvider);
    final p = await db.getUserProfile();
    if (mounted) {
      setState(() {
        _profile = p;
        _useKilograms = p?.weightUnit != 'lbs';
        _loading = false;
      });
    }
  }

  Future<void> _toggleKilograms(bool value) async {
    setState(() => _useKilograms = value);
    final db = ref.read(databaseProvider);

    await db.saveUserProfile(UserProfileCompanion(
      weightUnit: drift.Value(value ? 'kg' : 'lbs'),
    ));

    final p = await db.getUserProfile();
    if (mounted) {
      setState(() => _profile = p);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Units set to Kilograms (kg)' : 'Units set to Pounds (lbs)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showVolumeDetailsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Weekly Volume Pacing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Target: 16 hard sets per muscle group weekly.\n\n'
          'Adaptive Pacing: 14 sets prescribed this week based on recent training load strain and systemic recovery balance.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showFocusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Training Focus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Current Focus: Hypertrophy & Muscle Density\n\n'
          'Target Rep Range: 6 - 12 reps\n'
          'Rest Periods: 90 - 120s\n'
          'Progression Model: Double-Progression with 2.5 kg micro-overload.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showRpeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Target Session RPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Current Target: RPE 8.5 / 10\n\n'
          'Meaning: Leave 1 - 2 reps in reserve on compound movements to stimulate maximum hypertrophy without neural exhaustion.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showCardioDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Cardio Load Distribution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Protocol: Zone 2 → Threshold\n\n'
          '80% Low-Intensity Steady State (Zone 2) for mitochondrial density + 20% Lactate Threshold intervals.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showStrengthGoalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        title: const Text('Strength Goal Benchmark', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Primary Benchmark: 100 kg Bench Press\n\n'
          'Current Estimated 1RM: 82 kg\n'
          'Remaining Gap: 18 kg to target\n'
          'Forecasted Target Date: In 4 weeks at current +2.5 kg bi-weekly overload velocity.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _simulateOffline() {
    final store = KineticStore.instance;
    final now = DateTime.now();
    store.recordEvent(kinetic.KineticEvent(
      id: 'offline_${now.millisecondsSinceEpoch}',
      userId: 'default_user',
      eventType: 'connectivity_simulated_offline',
      timestamp: now,
      payload: {'status': 'offline'},
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulated Offline Mode: SQLite store active with zero-cloud fallback.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subtitle tag & Header with Staggered Entrance
              FadeSlideTransition(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOU',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Targets',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/account'),
                          icon: const Icon(Icons.manage_accounts_rounded,
                              color: Colors.white70, size: 26),
                          tooltip: 'Account Profile',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Super Admin Gym Owner Shortcut Banner
              FadeSlideTransition(
                delay: const Duration(milliseconds: 80),
                child: BouncingTap(
                  onTap: () => context.push('/admin'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF162033),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Gym Owner Portal',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ],
                        ),
                        Row(
                          children: const [
                            Text(
                              'Live Floor (18)',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Color(0xFF38BDF8), size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Volume Target Card (Clickable -> opens volume pacing details)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 120),
                child: InkWell(
                  onTap: _showVolumeDetailsDialog,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF222836)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Weekly volume target',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '16 sets',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFF222836), height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Recommended this week',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '14 sets',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Pacing explanation text
              const Text(
                "The system paces below target when recovery calls for it — your target isn't overridden.",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // 2x2 Metric Grid (All 4 cards clickable)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 180),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showFocusDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'TRAINING FOCUS',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Hypertrophy',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _showRpeDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'SESSION RPE',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '8.5 / 10',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showCardioDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'CARDIO LOAD',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Zone 2 → Threshold',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _showStrengthGoalDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'STRENGTH GOAL',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: const [
                                      Text(
                                        '18 kg to target ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: Colors.white54, size: 18),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Divider(color: Color(0xFF1E2634), height: 1),
              const SizedBox(height: 24),

              // Settings & Features Hub Container
              FadeSlideTransition(
                delay: const Duration(milliseconds: 240),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222836)),
                  ),
                  child: Column(
                    children: [
                      // Gym Owner Command Center
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF38BDF8), size: 22),
                        title: const Text(
                          'Gym Owner Command Center',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Manage client roster & live floor status',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () => context.push('/admin'),
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // Account & Profile
                      ListTile(
                        leading: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                        title: const Text(
                          'Profile & Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _profile?.username ?? 'Athlete',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () => context.push('/account'),
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // App Settings & Backup
                      ListTile(
                        leading: const Icon(Icons.settings_rounded, color: Color(0xFF38BDF8), size: 22),
                        title: const Text(
                          'Settings & Cloud Backup',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Export data, SQLite backup, Dark theme',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () => context.push('/settings'),
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // Outdoor Goals & Wishlist
                      ListTile(
                        leading: const Icon(Icons.star_rounded, color: Color(0xFFFB923C), size: 22),
                        title: const Text(
                          'Outdoor Goals & Wishlist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Hiking, Running & Milestone badges',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () => context.push('/wishlist'),
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // Data sources
                      ListTile(
                        leading: const Icon(Icons.hub_rounded, color: Color(0xFFA855F7), size: 22),
                        title: const Text(
                          'Data sources',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Apple Health, Oura Ring (Simulated)',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connected Data Sources: Apple HealthKit, Oura Ring v3 API.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // Connected devices
                      ListTile(
                        leading: const Icon(Icons.bluetooth_connected_rounded, color: Color(0xFF2DD4BF), size: 22),
                        title: const Text(
                          'Connected devices',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          '2 connected (Polar H10 Chest Strap, Smart Ring)',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('BLE Sensors: Polar H10 Chest Strap, Oura Horizon.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // Use kilograms switch (Saves to SQLite)
                      SwitchListTile(
                        secondary: const Icon(Icons.scale_rounded, color: AppColors.primary, size: 22),
                        title: const Text(
                          'Use kilograms',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: _useKilograms,
                        activeColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withOpacity(0.3),
                        onChanged: _toggleKilograms,
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // Send In-App Feedback
                      ListTile(
                        leading: const Icon(Icons.feedback_rounded, color: Color(0xFFF472B6), size: 22),
                        title: const Text(
                          'Send Feedback',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Report bugs or suggest features',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () => context.push('/feedback'),
                      ),
                      const Divider(color: Color(0xFF222836), height: 1),

                      // Privacy
                      ListTile(
                        leading: const Icon(Icons.security_rounded, color: Colors.white54, size: 22),
                        title: const Text(
                          'Privacy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Local SQLite Encrypted Storage',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Privacy Policy: All personal fitness records remain 100% on-device.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Footer Links (Both clickable)
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/onboarding'),
                    child: const Text(
                      'Restart onboarding',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _simulateOffline,
                    child: const Text(
                      'Simulate offline',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
