import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/barcode_scanner_sheet.dart';

class FoodDiaryScreen extends ConsumerStatefulWidget {
  const FoodDiaryScreen({super.key});
  @override
  ConsumerState<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends ConsumerState<FoodDiaryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<NutritionDiaryData> _diary = [];
  Map<int, Ingredient> _ingredientCache = {};
  double _totalCal = 0, _totalProtein = 0, _totalCarbs = 0, _totalFat = 0;

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    final db = ref.read(databaseProvider);
    final entries = await db.getDiaryForDate(_selectedDate);
    double cal = 0, prot = 0, carbs = 0, fat = 0;
    final cache = <int, Ingredient>{};
    for (final e in entries) {
      final ing = await (db.select(db.ingredients)
            ..where((t) => t.id.equals(e.ingredientId)))
          .getSingleOrNull();
      if (ing != null) {
        cache[e.ingredientId] = ing;
        final factor = e.amount / 100;
        cal += ing.energy * factor;
        prot += ing.protein * factor;
        carbs += ing.carbs * factor;
        fat += ing.fat * factor;
      }
    }
    if (mounted) {
      setState(() {
        _diary = entries;
        _ingredientCache = cache;
        _totalCal = cal;
        _totalProtein = prot;
        _totalCarbs = carbs;
        _totalFat = fat;
      });
    }
  }

  Future<void> _addEntry(int ingredientId, double amount) async {
    final db = ref.read(databaseProvider);
    await db.insertDiaryEntry(NutritionDiaryCompanion(
      ingredientId: drift.Value(ingredientId),
      amount: drift.Value(amount),
      date: drift.Value(DateTime.now()),
      pendingSync: const drift.Value(true),
    ));
    await _loadDiary();
  }

  Future<void> _scanBarcode() async {
    final result = await BarcodeScannerSheet.show(context);
    if (result != null && result['id'] != null && result['amount'] != null) {
      await _addEntry(result['id'] as int, (result['amount'] as num).toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMM d').format(_selectedDate);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Diary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/nutrition'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Barcode',
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            color: Theme.of(context).cardTheme.color,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () {
                    setState(() => _selectedDate =
                        _selectedDate.subtract(const Duration(days: 1)));
                    _loadDiary();
                  },
                ),
                Text(dateLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () {
                    if (_selectedDate.isBefore(DateTime.now())) {
                      setState(() => _selectedDate =
                          _selectedDate.add(const Duration(days: 1)));
                      _loadDiary();
                    }
                  },
                ),
              ],
            ),
          ),
          // Macro summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _macro('${_totalCal.toInt()}', 'kcal', Colors.white),
                _macro('${_totalProtein.toStringAsFixed(1)}g', 'Protein',
                    Colors.white70),
                _macro('${_totalCarbs.toStringAsFixed(1)}g', 'Carbs',
                    Colors.white70),
                _macro('${_totalFat.toStringAsFixed(1)}g', 'Fat',
                    Colors.white70),
              ],
            ),
          ),
          // Diary entries
          Expanded(
            child: _diary.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_outlined,
                            size: 56,
                            color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('Nothing logged today',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _diary.length,
                    itemBuilder: (_, i) {
                      final entry = _diary[i];
                      final ing = _ingredientCache[entry.ingredientId];
                      if (ing == null) return const SizedBox.shrink();
                      final cal =
                          (ing.energy * entry.amount / 100).toInt();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(ing.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${entry.amount.toInt()}g · ${ing.protein.toStringAsFixed(1)}g prot · '
                              '${ing.carbs.toStringAsFixed(1)}g carbs'),
                          trailing: Text('$cal kcal',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push('/nutrition/search');
          if (result != null && result is Map) {
            await _addEntry(result['id'] as int, result['amount'] as double);
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Food'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _macro(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800)),
        Text(label,
            style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }
}
