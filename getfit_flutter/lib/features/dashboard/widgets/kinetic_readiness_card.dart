import 'package:flutter/material.dart';
import '../../../kinetic/kinetic_core.dart';
import 'kinetic_why_dialog.dart';

class KineticReadinessCard extends StatelessWidget {
  final TodayViewModel todayVM;

  const KineticReadinessCard({super.key, required this.todayVM});

  @override
  Widget build(BuildContext context) {
    final state = todayVM.currentState;
    final rec = todayVM.primaryRecommendation;

    return Card(
      color: const Color(0xFF131313),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2A2A2A)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2AF598).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFF2AF598),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'KINETIC PRECISION',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2AF598).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2AF598).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF2AF598), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        todayVM.dataQualityLabel,
                        style: const TextStyle(
                          color: Color(0xFF2AF598),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Scores Row
            Row(
              children: [
                // Readiness Radial / Dial
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1C1B1B),
                    border: Border.all(color: const Color(0xFF2AF598), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2AF598).withOpacity(0.15),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.readinessScore.round().toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'READINESS',
                          style: TextStyle(
                            color: Color(0xFF2AF598),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Detailed Metrics
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.headline,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rec.rationale,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _MetricPill(
                            label: 'Recovery',
                            value: '${state.recoveryScore.round()}%',
                            color: const Color(0xFF2AF598),
                          ),
                          const SizedBox(width: 8),
                          _MetricPill(
                            label: 'Fatigue',
                            value: '${state.fatigueScore.round()}%',
                            color: const Color(0xFFFFDE54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2A2A2A)),
            const SizedBox(height: 12),

            // Targets Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TargetItem(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF5252),
                  label: 'Energy Target',
                  value: '${todayVM.nutritionTarget.energyKcal} kcal',
                ),
                _TargetItem(
                  icon: Icons.egg_alt_rounded,
                  iconColor: const Color(0xFF2AF598),
                  label: 'Protein',
                  value: '${todayVM.nutritionTarget.proteinGrams.round()}g',
                ),
                _TargetItem(
                  icon: Icons.bedtime_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  label: 'Sleep Need',
                  value: '${todayVM.sleepTarget.targetDurationHours}h',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // WHY Explanation Button
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () {
                  final telemetry = TelemetryService();
                  final explanation = telemetry.explainRecommendation(rec.id);
                  if (explanation != null) {
                    showDialog(
                      context: context,
                      builder: (_) => KineticWhyDialog(explanation: explanation),
                    );
                  }
                },
                icon: const Icon(Icons.help_outline_rounded, size: 16, color: Color(0xFF2AF598)),
                label: const Text(
                  'Explain Recommendation (WHY Audit)',
                  style: TextStyle(
                    color: Color(0xFF2AF598),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2AF598), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _TargetItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _TargetItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
