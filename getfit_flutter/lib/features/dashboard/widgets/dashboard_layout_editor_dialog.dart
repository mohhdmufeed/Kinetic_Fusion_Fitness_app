import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';

class DashboardCardItem {
  final String id;
  final String title;
  final IconData icon;
  bool isVisible;

  DashboardCardItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isVisible = true,
  });
}

class DashboardLayoutEditorDialog extends ConsumerStatefulWidget {
  final List<String> currentOrder;
  final VoidCallback onSaved;

  const DashboardLayoutEditorDialog({
    super.key,
    required this.currentOrder,
    required this.onSaved,
  });

  @override
  ConsumerState<DashboardLayoutEditorDialog> createState() =>
      _DashboardLayoutEditorDialogState();
}

class _DashboardLayoutEditorDialogState
    extends ConsumerState<DashboardLayoutEditorDialog> {
  late List<DashboardCardItem> _items;

  final Map<String, Map<String, dynamic>> _catalog = {
    'ring': {'title': 'Activity Ring (kcal moved)', 'icon': Icons.donut_large_rounded},
    'steps': {'title': 'Steps & Sparkline', 'icon': Icons.directions_walk_rounded},
    'distance': {'title': 'Distance Moved', 'icon': Icons.route_rounded},
    'sessions': {'title': 'Workout Sessions', 'icon': Icons.fitness_center_rounded},
    'awards': {'title': 'Awards & Badges', 'icon': Icons.emoji_events_rounded},
    'quote': {'title': 'Daily Gym Motivation', 'icon': Icons.lightbulb_outline_rounded},
  };

  @override
  void initState() {
    super.initState();
    _initItems();
  }

  void _initItems() {
    _items = [];
    final seen = <String>{};

    // Add ordered active items
    for (final id in widget.currentOrder) {
      if (_catalog.containsKey(id)) {
        _items.add(
          DashboardCardItem(
            id: id,
            title: _catalog[id]!['title'] as String,
            icon: _catalog[id]!['icon'] as IconData,
            isVisible: true,
          ),
        );
        seen.add(id);
      }
    }

    // Add remaining hidden items
    for (final entry in _catalog.entries) {
      if (!seen.contains(entry.key)) {
        _items.add(
          DashboardCardItem(
            id: entry.key,
            title: entry.value['title'] as String,
            icon: entry.value['icon'] as IconData,
            isVisible: false,
          ),
        );
      }
    }
  }

  Future<void> _saveLayout() async {
    final enabledIds = _items.where((i) => i.isVisible).map((i) => i.id).toList();
    final jsonStr = jsonEncode(enabledIds);

    final db = ref.read(databaseProvider);
    await db.saveUserProfile(
      UserProfileCompanion(
        summaryLayout: drift.Value(jsonStr),
      ),
    );

    widget.onSaved();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF26496C);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Drag handle to reorder, toggle to hide/show',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _saveLayout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _items.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _items.removeAt(oldIndex);
                  _items.insert(newIndex, item);
                });
              },
              itemBuilder: (context, idx) {
                final item = _items[idx];
                return Card(
                  key: ValueKey(item.id),
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(item.icon, color: item.isVisible ? navyColor : Colors.grey),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: item.isVisible ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: item.isVisible,
                          activeColor: navyColor,
                          onChanged: (val) {
                            setState(() => item.isVisible = val);
                          },
                        ),
                        const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                      ],
                    ),
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
