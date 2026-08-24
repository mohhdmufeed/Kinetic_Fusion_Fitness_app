import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/theme/app_theme.dart';

class CategoryTileItem {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final String route;

  const CategoryTileItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class CategoriesHubScreen extends StatelessWidget {
  const CategoriesHubScreen({super.key});

  static const List<CategoryTileItem> _tiles = [
    CategoryTileItem(
      title: 'Activity Ring',
      subtitle: 'Daily burn vs target',
      icon: '⭕',
      color: Color(0xFF26496C),
      route: '/dashboard',
    ),
    CategoryTileItem(
      title: 'Steps',
      subtitle: 'Sensor & daily totals',
      icon: '🚶',
      color: Color(0xFF0284C7),
      route: '/categories/report/walking',
    ),
    CategoryTileItem(
      title: 'Sessions',
      subtitle: 'Weight & gym workouts',
      icon: '🏋️',
      color: Color(0xFF0D9488),
      route: '/workouts/history',
    ),
    CategoryTileItem(
      title: 'Running',
      subtitle: 'Distance & pace tracking',
      icon: '🏃',
      color: Color(0xFF0284C7),
      route: '/categories/report/running',
    ),
    CategoryTileItem(
      title: 'Cycling',
      subtitle: 'Rides, distance & speed',
      icon: '🚴',
      color: Color(0xFF059669),
      route: '/categories/report/cycling',
    ),
    CategoryTileItem(
      title: 'Swimming',
      subtitle: 'Laps, distance & sets',
      icon: '🏊',
      color: Color(0xFF0284C7),
      route: '/categories/report/swimming',
    ),
    CategoryTileItem(
      title: 'Hiking',
      subtitle: 'Elevation & trail paths',
      icon: '🥾',
      color: Color(0xFFD97706),
      route: '/categories/report/hiking',
    ),
    CategoryTileItem(
      title: 'Walking',
      subtitle: 'Daily strides & walks',
      icon: '👟',
      color: Color(0xFF26496C),
      route: '/categories/report/walking',
    ),
    CategoryTileItem(
      title: 'Mindfulness',
      subtitle: 'Breathwork & meditation',
      icon: '🧘',
      color: Color(0xFF8B5CF6),
      route: '/categories/report/mindfulness',
    ),
    CategoryTileItem(
      title: 'Trainer Tips',
      subtitle: 'Daily coaching advice',
      icon: '💡',
      color: Color(0xFFEAB308),
      route: '/categories/tips',
    ),
    CategoryTileItem(
      title: 'Trends',
      subtitle: 'Long-term progression',
      icon: '📈',
      color: Color(0xFF10B981),
      route: '/categories/trends',
    ),
    CategoryTileItem(
      title: 'Wishlist & Goals',
      subtitle: 'Target trails & routes',
      icon: '🎯',
      color: Color(0xFFE11D48),
      route: '/wishlist',
    ),
    CategoryTileItem(
      title: 'Awards',
      subtitle: 'Trophies & milestones',
      icon: '🏆',
      color: Color(0xFFF59E0B),
      route: '/charts',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories & Reports'),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
        ),
        itemCount: _tiles.length,
        itemBuilder: (context, idx) {
          final tile = _tiles[idx];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: () {
                context.push(tile.route);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: tile.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tile.icon, style: const TextStyle(fontSize: 22)),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tile.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF26496C),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tile.subtitle,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
