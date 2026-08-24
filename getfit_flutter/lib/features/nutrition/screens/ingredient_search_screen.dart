import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/barcode_scanner_sheet.dart';

class IngredientSearchScreen extends ConsumerStatefulWidget {
  const IngredientSearchScreen({super.key});
  @override
  ConsumerState<IngredientSearchScreen> createState() =>
      _IngredientSearchScreenState();
}

class _IngredientSearchScreenState
    extends ConsumerState<IngredientSearchScreen> {
  List<Ingredient> _results = [];
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    final res = await ref.read(databaseProvider).searchIngredients(q);
    if (mounted) setState(() => _results = res);
  }

  void _selectIngredient(Ingredient ing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AmountPicker(
        ingredient: ing,
        onConfirm: (amount) {
          Navigator.pop(context);
          context.pop({'id': ing.id, 'amount': amount});
        },
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final result = await BarcodeScannerSheet.show(context);
    if (result != null && result['id'] != null && result['amount'] != null && mounted) {
      context.pop({'id': result['id'], 'amount': result['amount']});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search food (offline)...',
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan Barcode',
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: _results.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_rounded,
                      size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    _ctrl.text.isEmpty
                        ? 'Type to search ingredients'
                        : 'No results found',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final ing = _results[i];
                return ListTile(
                  title: Text(ing.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${ing.energy.toInt()} kcal · '
                      '${ing.protein.toStringAsFixed(1)}g P · '
                      '${ing.carbs.toStringAsFixed(1)}g C · '
                      '${ing.fat.toStringAsFixed(1)}g F',
                      style: const TextStyle(fontSize: 12)),
                  onTap: () => _selectIngredient(ing),
                );
              },
            ),
    );
  }
}

class _AmountPicker extends StatefulWidget {
  final Ingredient ingredient;
  final void Function(double) onConfirm;
  const _AmountPicker(
      {required this.ingredient, required this.onConfirm});

  @override
  State<_AmountPicker> createState() => _AmountPickerState();
}

class _AmountPickerState extends State<_AmountPicker> {
  double _amount = 100;
  final _ctrl = TextEditingController(text: '100');

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final factor = _amount / 100;
    final cal = (ing.energy * factor).toInt();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ing.name,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (grams)',
                    suffixText: 'g',
                  ),
                  onChanged: (v) =>
                      setState(() => _amount = double.tryParse(v) ?? 100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroTag('$cal kcal', AppColors.warning),
              _macroTag('${(ing.protein * factor).toStringAsFixed(1)}g P',
                  AppColors.primary),
              _macroTag('${(ing.carbs * factor).toStringAsFixed(1)}g C',
                  AppColors.accent),
              _macroTag('${(ing.fat * factor).toStringAsFixed(1)}g F',
                  AppColors.error),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => widget.onConfirm(_amount),
            child: const Text('Add to Diary'),
          ),
        ],
      ),
    );
  }

  Widget _macroTag(String text, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      );
}
