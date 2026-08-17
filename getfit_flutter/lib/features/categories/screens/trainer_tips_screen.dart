import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

class TipItem {
  final String title;
  final String body;
  final String category;
  final String icon;

  const TipItem({
    required this.title,
    required this.body,
    required this.category,
    required this.icon,
  });
}

class TrainerTipsScreen extends StatefulWidget {
  const TrainerTipsScreen({super.key});

  @override
  State<TrainerTipsScreen> createState() => _TrainerTipsScreenState();
}

class _TrainerTipsScreenState extends State<TrainerTipsScreen> {
  String _selectedCategory = 'All';

  final List<TipItem> _tips = const [
    TipItem(
      title: 'Progressive Overload Principle',
      body: 'To grow stronger, increase weight, reps, or decrease rest periods by 2-5% every 1 to 2 weeks.',
      category: 'Strength',
      icon: '🏋️',
    ),
    TipItem(
      title: 'Zone 2 Cardio for Longevity',
      body: 'Train at an easy conversational pace (60-70% max HR) for 30-45 mins to build mitochondrial density.',
      category: 'Cardio',
      icon: '🏃',
    ),
    TipItem(
      title: 'Post-Workout Protein Window',
      body: 'Consume 20-35g of complete protein within 2 hours after lifting to kickstart muscle protein synthesis.',
      category: 'Nutrition',
      icon: '🥗',
    ),
    TipItem(
      title: 'Sleep Is Your Best Supplement',
      body: 'Growth hormone peaks during deep NREM sleep. Aim for 7.5 to 9 hours of uninterrupted sleep.',
      category: 'Recovery',
      icon: '😴',
    ),
    TipItem(
      title: 'Box Breathing for Stress Reduction',
      body: 'Inhale 4s, hold 4s, exhale 4s, hold 4s. Repeat 4 times to calm your sympathetic nervous system.',
      category: 'Mindfulness',
      icon: '🧘',
    ),
    TipItem(
      title: 'Optimal Running Cadence',
      body: 'Aim for a cadence around 170-180 steps/min to reduce knee impact and improve running efficiency.',
      category: 'Cardio',
      icon: '👟',
    ),
    TipItem(
      title: 'Deload Weeks Matter',
      body: 'Every 6-8 weeks of intense training, cut volume by 40% for one week to prevent systemic central fatigue.',
      category: 'Recovery',
      icon: '🔋',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);
    final categories = ['All', 'Strength', 'Cardio', 'Nutrition', 'Recovery', 'Mindfulness'];
    final filtered = _selectedCategory == 'All'
        ? _tips
        : _tips.where((t) => t.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trainer Tips & Advice'),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero "Tip of the Day"
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [navyColor, Color(0xFF1e3a5f)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Text('⭐', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              'TIP OF THE DAY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.fitness_center_rounded, color: Colors.white70, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hydration & Sodium Balance',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Drink 500ml of water with a pinch of electrolyte salt upon waking to restore cellular fluid balance after 8 hours of fast.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Categories Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: navyColor,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Tips List
          ...filtered.map((tip) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: navyColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(tip.icon, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                tip.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tip.category,
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tip.body,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
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
      ),
    );
  }
}
