import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/motion_widgets.dart';

class GymAdminScreen extends ConsumerStatefulWidget {
  const GymAdminScreen({super.key});

  @override
  ConsumerState<GymAdminScreen> createState() => _GymAdminScreenState();
}

class _GymAdminScreenState extends ConsumerState<GymAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'primed', 'warning', 'deload'
  bool _is2faVerified = true;
  int _sessionMinutesLeft = 28;

  final List<Map<String, dynamic>> _gymClients = [
    {
      'id': 'c_101',
      'name': 'Alex Rivera',
      'email': 'alex.rivera@athletemail.com',
      'avatar': 'AR',
      'recoveryScore': 94,
      'status': 'primed',
      'statusLabel': 'Primed for Overload',
      'workout': 'Upper-Body Heavy Hypertrophy',
      'lastActive': 'Active 12m ago',
      'acwr': 1.08,
      'rpeTarget': 8.5,
      'isActive': true,
      'isSoftDeleted': false,
    },
    {
      'id': 'c_102',
      'name': 'Sarah Chen',
      'email': 'sarah.chen@kinetic.io',
      'avatar': 'SC',
      'recoveryScore': 88,
      'status': 'primed',
      'statusLabel': 'Normal Training Capacity',
      'workout': 'Zone 2 Cardio + Core Engine',
      'lastActive': 'Active 2h ago',
      'acwr': 1.14,
      'rpeTarget': 8.0,
      'isActive': true,
      'isSoftDeleted': false,
    },
    {
      'id': 'c_103',
      'name': 'Marcus Vance',
      'email': 'marcus.vance@powerlifter.org',
      'avatar': 'MV',
      'recoveryScore': 52,
      'status': 'warning',
      'statusLabel': 'Fatigue Accumulating',
      'workout': 'Moderate Push • Volume -20%',
      'lastActive': 'Active 4h ago',
      'acwr': 1.38,
      'rpeTarget': 7.0,
      'isActive': true,
      'isSoftDeleted': false,
    },
    {
      'id': 'c_104',
      'name': 'Elena Rostova',
      'email': 'elena.rostova@precision.fit',
      'avatar': 'ER',
      'recoveryScore': 76,
      'status': 'primed',
      'statusLabel': 'Steady Progression',
      'workout': 'Lower Body Posterior Chain',
      'lastActive': 'Active 1d ago',
      'acwr': 1.02,
      'rpeTarget': 8.0,
      'isActive': true,
      'isSoftDeleted': false,
    },
    {
      'id': 'c_105',
      'name': 'David Kim',
      'email': 'david.kim@kinetic.me',
      'avatar': 'DK',
      'recoveryScore': 42,
      'status': 'deload',
      'statusLabel': 'Deload / Rest Prescribed',
      'workout': 'Active Mobility & Breathwork',
      'lastActive': 'Active 30m ago',
      'acwr': 1.52,
      'rpeTarget': 5.0,
      'isActive': true,
      'isSoftDeleted': false,
    },
  ];

  final List<Map<String, dynamic>> _auditLogs = [
    {
      'id': 'log_901',
      'timestamp': 'Just now',
      'admin': 'admin@kinetic.precision',
      'action': 'ADMIN_LOGIN_SUCCESS',
      'target': 'auth.Session:2fa_verified',
      'ip': '127.0.0.1',
      'details': 'Mandatory TOTP 2FA verified. Admin-scoped JWT issued.',
      'diff': {'session_scope': 'admin_jwt', 'expires_in': '30m'},
    },
    {
      'id': 'log_900',
      'timestamp': '15m ago',
      'admin': 'admin@kinetic.precision',
      'action': 'COACH_PRESCRIPTION_OVERRIDE',
      'target': 'athlete:c_101 (Alex Rivera)',
      'ip': '127.0.0.1',
      'details': 'Overload load increment +2.5kg approved.',
      'diff': {'load_before': '100.0 kg', 'load_after': '102.5 kg'},
    },
    {
      'id': 'log_899',
      'timestamp': '1h ago',
      'admin': 'admin@kinetic.precision',
      'action': 'SECURITY_AUDIT_CHECK',
      'target': 'system:celery_workers',
      'ip': '127.0.0.1',
      'details': 'System health ping: 4 workers online, 0 queue latency.',
      'diff': {'status': 'healthy', 'error_rate': '0.00%'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClients {
    return _gymClients.where((c) {
      final matchesQuery = (c['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c['email'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c['workout'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      if (_filterStatus == 'all') return matchesQuery;
      return matchesQuery && c['status'] == _filterStatus;
    }).toList();
  }

  void _recordAuditLog(String action, String target, String details, Map<String, dynamic> diff) {
    setState(() {
      _auditLogs.insert(0, {
        'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
        'timestamp': 'Just now',
        'admin': 'admin@kinetic.precision',
        'action': action,
        'target': target,
        'ip': '127.0.0.1',
        'details': details,
        'diff': diff,
      });
    });
  }

  void _toggleUserSuspension(Map<String, dynamic> client) {
    final bool currentActive = client['isActive'] as bool;
    final bool willSuspend = currentActive;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          willSuspend ? 'Suspend Athlete Account' : 'Reactivate Athlete Account',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          willSuspend
              ? 'Are you sure you want to suspend "${client['name']}"? The user will be blocked from data access and API sync.'
              : 'Reactivate "${client['name']}"? Account data access will be restored.',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                client['isActive'] = !willSuspend;
              });
              _recordAuditLog(
                willSuspend ? 'USER_SUSPENDED' : 'USER_ACTIVATED',
                'athlete:${client['id']} (${client['name']})',
                'Admin toggled account active status.',
                {'is_active_before': currentActive, 'is_active_after': !willSuspend},
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Athlete "${client['name']}" ${willSuspend ? 'suspended' : 'reactivated'}. Logged to audit trail.'),
                  backgroundColor: willSuspend ? AppColors.warning : AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: willSuspend ? AppColors.warning : AppColors.primary,
              foregroundColor: Colors.black,
            ),
            child: Text(willSuspend ? 'Confirm Suspension' : 'Confirm Reactivation'),
          ),
        ],
      ),
    );
  }

  void _confirmSoftDelete(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Soft-Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Execute soft-deletion for "${client['name']}" (${client['email']})?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              '• Preserves referential database integrity (workout logs and sets retained).\n• Immediately revokes all active JWT tokens.\n• Writes before/after diff to immutable audit ledger.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                client['isSoftDeleted'] = true;
                client['isActive'] = false;
              });
              _recordAuditLog(
                'USER_SOFT_DELETED',
                'athlete:${client['id']} (${client['name']})',
                'Soft delete confirmed. Referential integrity preserved.',
                {'is_active_before': true, 'is_active_after': false, 'soft_deleted': true},
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Athlete "${client['name']}" soft-deleted with audit diff record.'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Execute Soft-Delete'),
          ),
        ],
      ),
    );
  }

  void _openClientCoachEditor(Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildCoachEditorSheet(ctx, client),
    );
  }

  Widget _buildCoachEditorSheet(BuildContext ctx, Map<String, dynamic> client) {
    final noteCtrl = TextEditingController(text: 'Focus on bar speed; reduce RPE overshoot on final set.');
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        top: 24,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(client['avatar'], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(client['email'], style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Coach Prescription Overrides', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _recordAuditLog(
                      'COACH_DELOAD_PRESCRIBED',
                      'athlete:${client['id']}',
                      'Deload session prescribed by coach.',
                      {'status_before': client['status'], 'status_after': 'deload'},
                    );
                    setState(() {
                      client['status'] = 'deload';
                      client['statusLabel'] = 'Deload Prescribed by Coach';
                    });
                  },
                  icon: const Icon(Icons.shield_moon_outlined, size: 16, color: AppColors.info),
                  label: const Text('Prescribe Deload', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.info.withOpacity(0.4))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _recordAuditLog(
                      'COACH_OVERLOAD_APPROVED',
                      'athlete:${client['id']}',
                      'Overload +2.5kg approved.',
                      {'status_before': client['status'], 'status_after': 'primed'},
                    );
                    setState(() {
                      client['status'] = 'primed';
                      client['statusLabel'] = 'Approved for +2.5kg Overload';
                    });
                  },
                  icon: const Icon(Icons.trending_up_rounded, size: 16, color: Colors.black),
                  label: const Text('Approve +2.5kg', style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Coach Direct Note to Athlete',
              labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 8),
          const Text('Account Governance Actions', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _toggleUserSuspension(client);
                  },
                  icon: Icon(
                    client['isActive'] == true ? Icons.pause_circle_outline : Icons.play_circle_outline,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  label: Text(
                    client['isActive'] == true ? 'Suspend Account' : 'Reactivate',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmSoftDelete(client);
                  },
                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                  label: const Text('Soft-Delete', style: TextStyle(color: AppColors.error, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Super Admin Vault',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                ),
                const SizedBox(width: 5),
                Text(
                  '2FA TOTP Verified • Session ${_sessionMinutesLeft}m',
                  style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_outlined, size: 18), text: 'Athletes'),
            Tab(icon: Icon(Icons.monitor_heart_outlined, size: 18), text: 'System Health'),
            Tab(icon: Icon(Icons.history_edu_outlined, size: 18), text: 'Audit Trail'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAthletesTab(),
          _buildSystemHealthTab(),
          _buildAuditTrailTab(),
        ],
      ),
    );
  }

  Widget _buildAthletesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search & Filter
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search athletes or workouts...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Athlete List
        ..._filteredClients.map((client) {
          final isSoftDeleted = client['isSoftDeleted'] == true;
          final isActive = client['isActive'] == true;

          return FadeSlideTransition(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSoftDeleted
                      ? AppColors.error.withOpacity(0.4)
                      : (!isActive ? AppColors.warning.withOpacity(0.3) : Colors.white.withOpacity(0.08)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isSoftDeleted ? AppColors.error.withOpacity(0.2) : AppColors.primary.withOpacity(0.15),
                        child: Text(
                          client['avatar'],
                          style: TextStyle(
                            color: isSoftDeleted ? AppColors.error : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  client['name'],
                                  style: TextStyle(
                                    color: isSoftDeleted ? Colors.white54 : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    decoration: isSoftDeleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                if (isSoftDeleted) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.error.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('DELETED', style: TextStyle(color: AppColors.error, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ] else if (!isActive) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('SUSPENDED', style: TextStyle(color: AppColors.warning, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text(client['email'], style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                        onPressed: () => _openClientCoachEditor(client),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client['workout'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(client['statusLabel'], style: const TextStyle(color: AppColors.primaryLight, fontSize: 11)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${client['recoveryScore']}%', style: const TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('ACWR ${client['acwr']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSystemHealthTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overall Status Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF16231C), Color(0xFF161B26)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('System Status: OPERATIONAL', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                  Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Celery Workers & Background Pipeline', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('4 distributed workers active • Redis heartbeat normal', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Metrics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildMetricCard('DB Query Latency', '1.4 ms', Icons.speed_rounded, AppColors.success),
            _buildMetricCard('Sync Success Rate', '99.8%', Icons.sync_lock_rounded, AppColors.primary),
            _buildMetricCard('Cache Hit Ratio', '96.4%', Icons.memory_rounded, AppColors.info),
            _buildMetricCard('Error Rate', '0.02%', Icons.shield_rounded, AppColors.accent),
          ],
        ),
        const SizedBox(height: 16),

        // Security Configuration
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161B26),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Active Security Posture', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              _buildSecurityItem('Mandatory 2FA (RFC 6238 TOTP)', 'ENFORCED', AppColors.success),
              _buildSecurityItem('Admin Path Isolation (/api/v2/admin/**)', 'ACTIVE', AppColors.success),
              _buildSecurityItem('JWT Scope Separation (admin_jwt)', 'ACTIVE', AppColors.success),
              _buildSecurityItem('Append-Only Audit Logging', 'ACTIVE', AppColors.success),
              _buildSecurityItem('Guest & Anonymous Access', 'DISABLED', AppColors.error),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(String label, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditTrailTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _auditLogs.length,
      itemBuilder: (ctx, i) {
        final log = _auditLogs[i];
        return FadeSlideTransition(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        log['action'],
                        style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(log['timestamp'], style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(log['target'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(log['details'], style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Diff: ${log['diff'].toString()}',
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
