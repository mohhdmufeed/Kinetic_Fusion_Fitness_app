import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/motion_widgets.dart';
import '../widgets/underlying_data_sheet.dart';
import '../../../kinetic/kinetic_core.dart';

class BodyScreen extends ConsumerStatefulWidget {
  const BodyScreen({super.key});
  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  List<WeightEntry> _weightHistory = [];
  double _latestWeight = 178.4;
  double _weeklyDelta = -1.2;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBodyData();
  }

  Future<void> _loadBodyData() async {
    final db = ref.read(databaseProvider);
    final weights = await db.getWeightEntries(limit: 14);

    double latest = 178.4;
    double delta = -1.2;

    if (weights.isNotEmpty) {
      latest = weights.first.weight * 2.20462; // Convert kg to lb
      if (weights.length > 1) {
        final previous = weights.last.weight * 2.20462;
        delta = latest - previous;
      }
    }

    if (mounted) {
      setState(() {
        _weightHistory = weights;
        _latestWeight = latest;
        _weeklyDelta = delta;
        _loading = false;
      });
    }
  }

  List<FlSpot> get _sparklineSpots {
    if (_weightHistory.length >= 4) {
      return List.generate(_weightHistory.length, (i) {
        final idx = _weightHistory.length - 1 - i;
        return FlSpot(i.toDouble(), _weightHistory[idx].weight);
      });
    }
    return const [
      FlSpot(0, 3.0),
      FlSpot(1, 3.5),
      FlSpot(2, 3.3),
      FlSpot(3, 4.2),
      FlSpot(4, 4.8),
      FlSpot(5, 5.5),
      FlSpot(6, 6.2),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final deltaSign = _weeklyDelta <= 0 ? '↓' : '↑';
    final deltaAbs = _weeklyDelta.abs().toStringAsFixed(1);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0E0F),
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
                  children: const [
                    Text(
                      'BODY',
                      style: TextStyle(
                        color: Color(0xFF8E9094),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Recovery is\ntrending up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Divider(color: Color(0xFF222326), height: 1),
              const SizedBox(height: 24),

              // Weight Trajectory (Clickable -> opens measurements)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 100),
                child: InkWell(
                  onTap: () => context.push('/measurements'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WEIGHT TRAJECTORY',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_latestWeight.toStringAsFixed(1)} ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'lb ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$deltaSign $deltaAbs lb this week',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Strength Trajectory & Line Chart (Clickable -> opens charts)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 150),
                child: InkWell(
                  onTap: () => context.push('/charts'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STRENGTH TRAJECTORY',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '4% ahead of your strength trajectory.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Dynamic Sparkline chart
                        SizedBox(
                          height: 70,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _sparklineSpots,
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 2.5,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(
                                    show: true,
                                    checkToShowDot: (spot, barData) =>
                                        spot.x == (_sparklineSpots.length - 1).toDouble(),
                                    getDotPainter: (spot, percent, barData, index) =>
                                        FlDotCirclePainter(
                                      radius: 4,
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                      strokeColor: AppColors.primary,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primary.withOpacity(0.08),
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
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF222326), height: 1),
              const SizedBox(height: 24),

              // Recovery Section (Clickable)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 200),
                child: InkWell(
                  onTap: () => context.push('/categories/trends'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RECOVERY',
                          style: TextStyle(
                            color: Color(0xFF8E9094),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: const [
                            Text(
                              'Trending up · deload complete ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '↗',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16,
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
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF222326), height: 1),
              const SizedBox(height: 24),

              // Goal Section (Clickable)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 250),
                child: InkWell(
                  onTap: () => context.push('/categories/report/strength'),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'GOAL',
                          style: TextStyle(
                            color: Color(0xFF8E9094),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '4 weeks to your next benchmark.',
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
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF222326), height: 1),
              const SizedBox(height: 24),

              // Link to underlying data (Opens clean Biometric Data Summary sheet)
              FadeSlideTransition(
                delay: const Duration(milliseconds: 300),
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const UnderlyingDataSheet(
                        currentWeight: 178.4,
                        weeklyWeightDelta: -1.2,
                        recoveryScore: 88,
                        acwr: 1.14,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'View underlying data',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF8E9094), size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Divider(color: Color(0xFF222326), height: 1),
              const SizedBox(height: 24),

              // ANALYTICS & BODY METRICS HUB
              FadeSlideTransition(
                delay: const Duration(milliseconds: 350),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ANALYTICS & BODY METRICS',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBodyHubCard(
                            context,
                            icon: Icons.sports_gymnastics_rounded,
                            title: 'Categories Hub',
                            subtitle: 'All Sports & Loads',
                            color: AppColors.primary,
                            onTap: () => context.push('/categories'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBodyHubCard(
                            context,
                            icon: Icons.show_chart_rounded,
                            title: 'Trend Reports',
                            subtitle: 'Volume & Progress',
                            color: const Color(0xFF38BDF8),
                            onTap: () => context.push('/charts'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBodyHubCard(
                            context,
                            icon: Icons.lightbulb_outline_rounded,
                            title: 'Trainer Tips',
                            subtitle: 'Biomechanical Notes',
                            color: const Color(0xFFFB923C),
                            onTap: () => context.push('/categories/tips'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBodyHubCard(
                            context,
                            icon: Icons.accessibility_new_rounded,
                            title: 'Measurements',
                            subtitle: 'Log Circumferences',
                            color: const Color(0xFFA855F7),
                            onTap: () => context.push('/measurements'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyHubCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return BouncingTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B26),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF222836)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
