import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class UnderlyingDataSheet extends StatelessWidget {
  final double currentWeight;
  final double weeklyWeightDelta;
  final int recoveryScore;
  final double acwr;

  const UnderlyingDataSheet({
    super.key,
    required this.currentWeight,
    required this.weeklyWeightDelta,
    required this.recoveryScore,
    required this.acwr,
  });

  @override
  Widget build(BuildContext context) {
    final deltaSign = weeklyWeightDelta <= 0 ? '↓' : '↑';
    final deltaStr = '$deltaSign ${weeklyWeightDelta.abs().toStringAsFixed(1)} lb';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161B26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Biometric Data Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2x2 Metric Summary Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'HRV 7-DAY BASELINE',
                      value: '68 ms',
                      status: '+4 ms above baseline',
                      icon: Icons.monitor_heart_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'RESTING HEART RATE',
                      value: '54 bpm',
                      status: '-2 bpm (Optimal)',
                      icon: Icons.favorite_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'WORKLOAD (ACWR)',
                      value: acwr.toStringAsFixed(2),
                      status: 'Sweet Spot (0.8 - 1.3)',
                      icon: Icons.fitness_center_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'WEIGHT VELOCITY',
                      value: deltaStr,
                      status: 'On Target Pace',
                      icon: Icons.scale_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Targets Summary List
              const Text(
                'ACTIVE TARGET PROGRESSION',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),

              _buildTargetRow('Double-Progression Milestone', 'Bench Press: 85 kg × 8 reps', true),
              const SizedBox(height: 8),
              _buildTargetRow('Next Overload Increment', '+2.5 kg next session', true),
              const SizedBox(height: 8),
              _buildTargetRow('Target Recovery Window', '24 - 36 hours between muscle groups', true),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF121810),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close Summary',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String status,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222836)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRow(String title, String subtitle, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
