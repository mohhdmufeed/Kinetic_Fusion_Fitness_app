import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class MLModelsInspectorDialog extends StatelessWidget {
  const MLModelsInspectorDialog({super.key});

  static const List<Map<String, dynamic>> _models = [
    {
      'title': '1. Recovery & Readiness Predictor',
      'category': 'Biometric Time-Series',
      'formula': 'Score = w1*Z(HRV) + w2*Z(RHR) + w3*Z(Sleep)',
      'inputs': 'HRV: 64 ms (Z: +0.82) • RHR: 52 bpm • Sleep: 7.5 hrs',
      'prediction': 'Recovery: 88 / 100 (High Readiness ↗)',
      'status': 'Optimal Training State',
      'color': Color(0xFF879A58),
    },
    {
      'title': '2. Banister Impulse-Response Model',
      'category': 'Fitness-Fatigue Differential',
      'formula': 'P(t) = k1*Σ(Load*e^-t/42) - k2*Σ(Load*e^-t/7)',
      'inputs': 'Chronic Workload (42d): 420 • Acute Workload (7d): 480',
      'prediction': 'ACWR: 1.14 (Safe Progression Zone)',
      'status': 'Overreaching Risk: Low (< 5%)',
      'color': Color(0xFF38BDF8),
    },
    {
      'title': '3. Strength Trajectory & Autoregulation',
      'category': '1RM Double-Progression',
      'formula': '1RM = Weight * (1 + Reps / 30) ± Dynamic RPE Offset',
      'inputs': 'Bench Press: 100 kg × 8 reps @ RPE 8.0',
      'prediction': '+2.5 kg load increase next session',
      'status': '4% ahead of strength trajectory',
      'color': Color(0xFFA855F7),
    },
    {
      'title': '4. Dynamic Energy Balance Forecaster',
      'category': 'Differential Caloric Balance',
      'formula': 'dW/dt = (Intake - (BMR + TEF + NEAT + EEE)) / 7700',
      'inputs': 'Daily Target: 2,370 kcal • Expenditure: 2,620 kcal',
      'prediction': 'Rate: -0.22 kg/week (↓ 1.2 lb this week)',
      'status': 'Benchmark target in 4 weeks',
      'color': Color(0xFFFB923C),
    },
    {
      'title': '5. Circadian Sleep Debt Compensator',
      'category': 'Rolling Deficit Estimator',
      'formula': 'Target = BaselineNeed + (Σ SleepDebt_14d * 0.15)',
      'inputs': '14-Day Baseline: 7.8 hrs • Cumulative Debt: 1.2 hrs',
      'prediction': 'Prescribed Sleep Tonight: ~7h 30m',
      'status': 'Equilibrium Restored',
      'color': Color(0xFF2DD4BF),
    },
    {
      'title': '6. Bayesian Prescription Arbiter',
      'category': 'Constrained Multi-Objective Decision',
      'formula': 'ArgMax(Reward | RecoveryScore, VolumeDeficit, Fatigue)',
      'inputs': 'Readiness: 88 • Split: Upper Body • Fatigue: Low',
      'prediction': 'Prescription: Upper-Body Strength • 42 min',
      'status': 'Normal Push Supported',
      'color': Color(0xFFFFDE54),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0B0E14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF222836), width: 1)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'AI & ML Predictive Engines',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '6 On-Device Predictive Intelligence Models',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF1E2634), height: 1),

          // Models List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _models.length,
              itemBuilder: (context, i) {
                final m = _models[i];
                final color = m['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF222836)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with category badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              m['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color.withOpacity(0.3)),
                            ),
                            child: Text(
                              m['category'] as String,
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Math Formula
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E121A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m['formula'] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Live Inputs
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inputs: ',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              m['inputs'] as String,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Prediction output
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prediction: ',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              m['prediction'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Status note
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: color),
                          const SizedBox(width: 6),
                          Text(
                            m['status'] as String,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
