import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../core/auth/auth_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/motion_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  UserProfileData? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final db = ref.read(databaseProvider);
    final prof = await db.getUserProfile();
    if (mounted) setState(() => _profile = prof);
  }

  void _showUnlockProSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0F141C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: Color(0xFF263345), width: 1.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                const Text('Unlock Kinetic Precision Pro', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white60)),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Gain complete access to autonomous progression models, 1-on-1 trainer consults, and closed-loop bio-analytics.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildProPerk(Icons.auto_awesome, 'Unlimited AI Coaching & Form Diagnostics'),
            _buildProPerk(Icons.insights_rounded, 'Advanced 90-Day Autonomic Trend Analysis'),
            _buildProPerk(Icons.groups_rounded, 'Priority Reservation for Elite Group Classes'),
            _buildProPerk(Icons.lock_open_rounded, 'Full Access to 50+ Specialized Masterclasses'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Welcome to Kinetic Precision Pro!'), backgroundColor: AppColors.primary),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Start 14-Day Free Trial', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Widget _buildProPerk(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final username = _profile?.username ?? 'Athlete';

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. AVATAR & SOCIAL HEADER (Following / Followers) ─────────────
              FadeSlideTransition(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFF1E293B),
                        backgroundImage: const AssetImage('assets/images/athlete_torso.png'),
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                username,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('PRO', style: TextStyle(color: AppColors.primary, fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text('Performance Hybrid Athlete • Level 14', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildSocialCount('Following', '142'),
                              const SizedBox(width: 16),
                              _buildSocialCount('Followers', '318'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── 2. UNLOCK KINETIC PRO (CTA) ──────────────────────────────────────
              FadeSlideTransition(
                delay: const Duration(milliseconds: 50),
                child: InkWell(
                  onTap: _showUnlockProSheet,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF23354C), Color(0xFF131D2A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Unlock Kinetic Precision Pro', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                              SizedBox(height: 2),
                              Text('AI coaching, custom targets & live trainers', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── 3. PROFILE NAVIGATION ITEMS ────────────────────────────────────
              const Text(
                'Athlete Dashboard',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
              ),
              const SizedBox(height: 10),

              _buildNavCard(
                icon: Icons.emoji_events_rounded,
                color: Colors.amberAccent,
                title: 'Achievements',
                subtitle: 'Badges, milestones & trophy case',
                onTap: () => context.go('/achievements'),
              ),
              const SizedBox(height: 10),

              _buildNavCard(
                icon: Icons.history_rounded,
                color: Colors.cyanAccent,
                title: 'Activity history',
                subtitle: 'Comprehensive workout, run & meal logs',
                onTap: () => context.go('/activity'),
              ),
              const SizedBox(height: 10),

              _buildNavCard(
                icon: Icons.show_chart_rounded,
                color: Colors.deepOrangeAccent,
                title: 'Progress',
                subtitle: 'Body measurements & 1RM progression charts',
                onTap: () => context.push('/charts'),
              ),
              const SizedBox(height: 10),

              _buildNavCard(
                icon: Icons.favorite_rounded,
                color: Colors.pinkAccent,
                title: 'My favorites',
                subtitle: 'Saved workouts, custom routines & recipes',
                onTap: () => context.push('/wishlist'),
              ),
              const SizedBox(height: 10),

              _buildNavCard(
                icon: Icons.settings_rounded,
                color: Colors.white70,
                title: 'Settings',
                subtitle: 'PIN & Biometrics, Kilograms/Pounds, Gym Admin',
                onTap: () => context.push('/settings'),
              ),
              const SizedBox(height: 24),

              // ─── 4. LOG OUT BUTTON ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).logout();
                    ref.invalidate(isLoggedInProvider);
                    if (context.mounted) context.go('/login');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF324258)),
                    foregroundColor: Colors.white60,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCount(String label, String count) {
    return Row(
      children: [
        Text(count, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF131A26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF202C3E)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 13),
          ],
        ),
      ),
    );
  }
}
